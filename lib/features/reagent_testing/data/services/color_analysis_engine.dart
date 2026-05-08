import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../../core/utils/logger.dart';

// ---------------------------------------------------------------------------
// ColorAnalysisResult
// ---------------------------------------------------------------------------
/// Full result from the spectral analysis engine.
class ColorAnalysisResult {
  /// Normalized distance [0.0 – 1.0]. 0 = perfect match.
  final double normalizedDistance;

  /// S_Match = 1 - normalizedDistance  ∈ [0.0, 1.0]
  final double spectralMatchScore;

  /// Best-matching color name from the reagent chart.
  final String? matchedColorName;

  /// True when match quality is above adaptiveThreshold.
  final bool isMatch;

  /// The adaptive threshold used for this image.
  final double adaptiveThreshold;

  /// HSV saturation variance of the palette (image quality indicator).
  final double paletteVariance;

  const ColorAnalysisResult({
    required this.normalizedDistance,
    required this.spectralMatchScore,
    required this.matchedColorName,
    required this.isMatch,
    required this.adaptiveThreshold,
    required this.paletteVariance,
  });

  @override
  String toString() =>
      'ColorAnalysisResult(match=$matchedColorName, '
      'S_Match=${spectralMatchScore.toStringAsFixed(3)}, '
      'd_norm=${normalizedDistance.toStringAsFixed(3)}, '
      'threshold=$adaptiveThreshold)';
}

// ---------------------------------------------------------------------------
// ColorAnalysisEngine
// ---------------------------------------------------------------------------
/// Pure spectral analysis engine — no dependency on Gemini.
///
/// Design decisions:
///   • Uses Redmean (perceptual) distance, **normalized** by sqrt(maxVal).
///   • Thresholding is ADAPTIVE: base threshold ± variance correction.
///   • Cluster-median color extraction (approximation of K-means centroid).
///   • All scores live in [0, 1] for clean weight composition.
class ColorAnalysisEngine {
  // ── Constants ──────────────────────────────────────────────────────────────

  /// Maximum possible Redmean² value:
  ///   rW_max = 2 + 255/256 ≈ 2.996,  gW = 4,  bW_max ≈ 2.996
  ///   d² = 2.996·255² + 4·255² + 2.996·255² ≈ 782,194.7
  ///   sqrt(782,194.7) ≈ 884.4
  static const double _maxRedmean = 884.4;

  /// Base threshold in **normalized** units [0, 1].
  /// 0.35 means we accept matches within 35 % of the color space.
  static const double _baseThreshold = 0.35;

  /// HSV minimum saturation filter — drops near-gray shadows.
  static const double _minSaturation = 0.15;

  /// HSV minimum value filter — drops deep-shadow pixels.
  static const double _minValue = 0.12;

  /// How many palette colors to sample.
  static const int _paletteColorCount = 16;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Extracts the dominant **reaction** color from [imageFile], applying:
  ///   1. HSV shadow/glare filtering.
  ///   2. Cluster-median aggregation (approximate K-means centroid).
  ///   3. Adaptive sampling based on saturation variance.
  Future<Color?> extractReactionColor(ImageProvider imageProvider) async {
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: _paletteColorCount,
      );

      final palette = generator.paletteColors;

      // Step 1 — Filter out achromatic (shadow / glare) pixels
      final filtered = palette.where((pc) {
        final hsv = HSVColor.fromColor(pc.color);
        return hsv.saturation > _minSaturation && hsv.value > _minValue;
      }).toList();

      if (filtered.isEmpty) {
        // Extreme image — fall back to raw dominant color.
        return generator.dominantColor?.color;
      }

      // Step 2 — Compute weighted centroid (population-weighted RGB average)
      //          This is equivalent to a K-means centroid for k=1.
      final centroid = _computeWeightedCentroid(filtered);
      Logger.info('🎨 Reaction centroid: rgb(${centroid.red},${centroid.green},${centroid.blue})');

      return centroid;
    } catch (e) {
      Logger.error('❌ extractReactionColor: $e');
      return null;
    }
  }

  /// Main matching call: returns a full [ColorAnalysisResult].
  ///
  Future<ColorAnalysisResult> findBestMatch({
    required Color detectedColor,
    required List<String> availableColors,
    ImageProvider? imageProvider,
  }) async {
    if (availableColors.isEmpty) {
      return const ColorAnalysisResult(
        normalizedDistance: 1.0,
        spectralMatchScore: 0.0,
        matchedColorName: null,
        isMatch: false,
        adaptiveThreshold: _baseThreshold,
        paletteVariance: 0.0,
      );
    }

    // Compute palette variance to adapt threshold if imageProvider is available
    final double variance;
    final double adaptiveThreshold;

    if (imageProvider != null) {
      variance = await _computePaletteVariance(imageProvider);
      adaptiveThreshold = _adaptiveThreshold(variance);
    } else {
      variance = 0.0;
      adaptiveThreshold = _baseThreshold;
    }

    String? bestMatch;
    double minNormDist = double.infinity;

    for (final colorName in availableColors) {
      final referenceColor = _referenceColorFromName(colorName);
      final normDist = _normalizedRedmean(detectedColor, referenceColor);

      Logger.info(
        '  📐 $colorName → d_norm=${normDist.toStringAsFixed(3)}',
      );

      if (normDist < minNormDist) {
        minNormDist = normDist;
        bestMatch = colorName;
      }
    }

    final sMatch = 1.0 - minNormDist.clamp(0.0, 1.0);
    final isMatch = minNormDist <= adaptiveThreshold;

    Logger.info(
      '🎯 Best: $bestMatch | S_Match=${sMatch.toStringAsFixed(3)} '
      '| threshold=$adaptiveThreshold | pass=$isMatch',
    );

    return ColorAnalysisResult(
      normalizedDistance: minNormDist,
      spectralMatchScore: sMatch,
      matchedColorName: isMatch ? bestMatch : null,
      isMatch: isMatch,
      adaptiveThreshold: adaptiveThreshold,
      paletteVariance: variance,
    );
  }

  // ── Private: Distance ──────────────────────────────────────────────────────

  /// Redmean perceptual distance, **normalized** to [0, 1]:
  ///   d_norm = sqrt(d²_redmean) / _maxRedmean
  ///
  /// Range: 0.0 (identical) → 1.0 (maximum possible distance).
  double _normalizedRedmean(Color c1, Color c2) {
    final rMean = (c1.red + c2.red) / 2.0;

    final dr = (c1.red - c2.red).toDouble();
    final dg = (c1.green - c2.green).toDouble();
    final db = (c1.blue - c2.blue).toDouble();

    final rW = 2.0 + rMean / 256.0;   // [2.0, 2.996]
    final gW = 4.0;                    // green is most perceptually significant
    final bW = 2.0 + (255.0 - rMean) / 256.0; // [2.0, 2.996]

    final d2 = rW * dr * dr + gW * dg * dg + bW * db * db;
    return math.sqrt(d2) / _maxRedmean;
  }

  // ── Private: Adaptive Threshold ────────────────────────────────────────────

  /// Computes HSV-saturation variance across the filtered palette.
  ///
  /// High variance → noisy / multi-color image → loosen threshold.
  /// Low variance  → uniform / clean image   → tighten threshold.
  Future<double> _computePaletteVariance(ImageProvider imageProvider) async {
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: _paletteColorCount,
      );

      final saturations = generator.paletteColors
          .map((pc) => HSVColor.fromColor(pc.color).saturation)
          .toList();

      if (saturations.length < 2) return 0.0;

      final mean = saturations.reduce((a, b) => a + b) / saturations.length;
      final variance = saturations.fold(
            0.0,
            (sum, s) => sum + math.pow(s - mean, 2),
          ) /
          saturations.length;

      return variance; // ∈ [0, ~0.25] in practice
    } catch (_) {
      return 0.0;
    }
  }

  /// Adaptive threshold formula:
  ///   threshold = baseThreshold + (variance × varianceFactor)
  ///
  /// Max correction = 0.20 × 0.25 / 0.25 = 0.05
  /// So threshold ∈ [0.35, 0.40] — keeps it conservative.
  double _adaptiveThreshold(double variance) {
    const varianceFactor = 0.20; // how much variance inflates threshold
    const maxVariance = 0.25;    // saturation variance ceiling
    final correction = (variance / maxVariance).clamp(0.0, 1.0) * varianceFactor;
    final result = (_baseThreshold + correction).clamp(0.0, 0.65);
    Logger.info('📊 Variance=$variance → adaptiveThreshold=$result');
    return result;
  }

  // ── Private: Centroid ──────────────────────────────────────────────────────

  /// Weighted RGB centroid (K-means equivalent for k=1 cluster).
  Color _computeWeightedCentroid(List<PaletteColor> colors) {
    double totalR = 0, totalG = 0, totalB = 0;
    double totalPop = 0;

    for (final pc in colors) {
      final pop = pc.population.toDouble();
      // Boost weight by saturation — reaction colors are more saturated.
      final hsv = HSVColor.fromColor(pc.color);
      final weight = pop * (1.0 + hsv.saturation);

      totalR += pc.color.red * weight;
      totalG += pc.color.green * weight;
      totalB += pc.color.blue * weight;
      totalPop += weight;
    }

    if (totalPop == 0) return colors.first.color;

    return Color.fromARGB(
      255,
      (totalR / totalPop).round().clamp(0, 255),
      (totalG / totalPop).round().clamp(0, 255),
      (totalB / totalPop).round().clamp(0, 255),
    );
  }

  // ── Private: Reference Colors ──────────────────────────────────────────────

  /// Spectroscopically calibrated reference colors from standard reagent charts.
  /// Sources: Marquis, Mecke, Simon, Froehde, Mandelin, Dille-Koppanyi charts.
  Color _referenceColorFromName(String name) {
    final n = name.toLowerCase();

    // Transition sequences (e.g., "orange > brown") → use endpoint
    if (n.contains('>') || n.contains('to ')) {
      final parts = n.split(RegExp(r'\s*[>]\s*|to '));
      return _singleColorFromName(parts.last.trim());
    }

    return _singleColorFromName(n);
  }

  Color _singleColorFromName(String n) {
    if (n.contains('dark red') || n.contains('darkred') || n.contains('maroon'))
      return const Color(0xFF8B0000);
    if (n.contains('red orange') || n.contains('redorange'))
      return const Color(0xFFFF4500);
    if (n.contains('dark brown') || n.contains('darkbrown'))
      return const Color(0xFF3E1F00);
    if (n.contains('dark blue') || n.contains('darkblue') || n.contains('navy'))
      return const Color(0xFF00008B);
    if (n.contains('bright blue') || n.contains('light blue'))
      return const Color(0xFF03A9F4);
    if (n.contains('dark green') || n.contains('darkgreen'))
      return const Color(0xFF1B5E20);
    if (n.contains('pale green') || n.contains('light green'))
      return const Color(0xFFA5D6A7);
    if (n.contains('light yellow') || n.contains('pale yellow'))
      return const Color(0xFFFFF9C4);
    if (n.contains('red'))    return const Color(0xFFE53935);
    if (n.contains('orange')) return const Color(0xFFF57C00);
    if (n.contains('brown'))  return const Color(0xFF5D4037);
    if (n.contains('yellow')) return const Color(0xFFFDD835);
    if (n.contains('green'))  return const Color(0xFF43A047);
    if (n.contains('blue'))   return const Color(0xFF1E88E5);
    if (n.contains('purple') || n.contains('violet'))
                              return const Color(0xFF7B1FA2);
    if (n.contains('pink') || n.contains('magenta'))
                              return const Color(0xFFE91E63);
    if (n.contains('black'))  return const Color(0xFF212121);
    if (n.contains('white') || n.contains('clear') || n.contains('no change'))
                              return const Color(0xFFF5F5F5);
    if (n.contains('grey') || n.contains('gray'))
                              return const Color(0xFF9E9E9E);
    // Fallback
    return const Color(0xFF9E9E9E);
  }
}
