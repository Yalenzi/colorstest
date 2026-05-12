import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/services/gemini_image_analysis_service.dart';
import '../../../../core/utils/logger.dart';
import '../models/reagent_model.dart';
import '../models/gemini_analysis_models.dart';
import 'color_analysis_engine.dart';
import 'decision_engine.dart';

export 'color_analysis_engine.dart' show ColorAnalysisResult;
export 'decision_engine.dart' show DecisionEngineResult;

/// Orchestrator that wires ColorAnalysisEngine + Gemini + DecisionEngine.
/// This is the ONLY class the UI layer should talk to.
class AIService {
  final GeminiImageAnalysisService? _geminiService;
  final ColorAnalysisEngine _colorEngine;
  final DecisionEngine _decisionEngine;

  AIService({GeminiImageAnalysisService? geminiService})
      : _geminiService = geminiService,
        _colorEngine = ColorAnalysisEngine(),
        _decisionEngine = DecisionEngine();

  // ── Color Detection ────────────────────────────────────────────────────────

  /// Returns the dominant reaction color, or null on failure.
  Future<Color?> detectColorFromImage(File imageFile) async {
    return _colorEngine.extractReactionColor(FileImage(imageFile));
  }

  /// Returns a [ColorAnalysisResult] with spectral match score, threshold, etc.
  Future<ColorAnalysisResult> analyzeColorFromImage(
    File imageFile,
    List<String> availableColorNames,
  ) async {
    final imageProvider = FileImage(imageFile);

    // 1. Extract reaction color (centroid after HSV filtering)
    final detectedColor = await _colorEngine.extractReactionColor(imageProvider);

    if (detectedColor == null) {
      return const ColorAnalysisResult(
        normalizedDistance: 1.0,
        spectralMatchScore: 0.0,
        matchedColorName: null,
        isMatch: false,
        adaptiveThreshold: 0.35,
        paletteVariance: 0.0,
      );
    }

    // 2. Match against reagent chart
    return _colorEngine.findBestMatch(
      detectedColor: detectedColor,
      availableColors: availableColorNames,
      imageProvider: imageProvider,
    );
  }

  /// Convenience method for the UI to find the closest color name.
  /// Uses spectral Redmean distance under the hood.
  Future<String?> findNearestColorName(
    Color detectedColor,
    List<String> availableColors,
  ) async {
    final result = await _colorEngine.findBestMatch(
      detectedColor: detectedColor,
      availableColors: availableColors,
    );
    return result.matchedColorName;
  }

  // ── Gemini AI Analysis ─────────────────────────────────────────────────────

  /// Runs Gemini analysis. Returns null if Gemini unavailable or fails.
  Future<GeminiReagentTestResult?> analyzeWithAI({
    required File imageFile,
    required ReagentModel reagent,
  }) async {
    if (_geminiService == null) {
      Logger.warning('⚠️ Gemini unavailable — spectral-only mode');
      return null;
    }

    try {
      final drugResultsJson = reagent.drugResults
          .map((e) => {'drugName': e.drugName, 'color': e.color})
          .toList();

      final jsonString = await _geminiService.analyzeReagentTestImage(
        imageFile: imageFile,
        reagentName: reagent.reagentName,
        drugResults: drugResultsJson,
        testContext: {
          'safetyLevel': reagent.safetyLevel,
          'description': reagent.description,
        },
      );

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return GeminiReagentTestResult.fromJson(jsonMap);
    } catch (e) {
      Logger.error('❌ Gemini analysis failed → falling back to spectral: $e');
      return null; // Explicit null = trigger fallback in DecisionEngine
    }
  }

  // ── Full Pipeline ──────────────────────────────────────────────────────────

  /// Runs both spectral + AI analysis and resolves conflicts.
  ///
  /// This is the high-level call used when the user clicks "Analyse".
  Future<DecisionEngineResult> runFullPipeline({
    required File imageFile,
    required ReagentModel reagent,
  }) async {
    Logger.info('🚀 Starting full analysis pipeline for ${reagent.reagentName}');

    final availableColors = reagent.drugResults.map((dr) => dr.color).toList();

    // 1. Spectral analysis (always runs, fast, offline)
    final colorResult = await analyzeColorFromImage(imageFile, availableColors);

    // 2. Map spectral color match → substance names
    final spectralSubstances = colorResult.matchedColorName != null
        ? reagent.drugResults
              .where((dr) => dr.color
                  .toLowerCase()
                  .contains(colorResult.matchedColorName!.toLowerCase()))
              .map((dr) => dr.drugName)
              .toList()
        : <String>[];

    // 3. Gemini AI (may fail — graceful degradation)
    GeminiReagentTestResult? aiResult;
    try {
      aiResult = await analyzeWithAI(imageFile: imageFile, reagent: reagent);
    } catch (_) {
      aiResult = null;
    }

    // 4. Decision Engine fusion
    final decision = _decisionEngine.resolve(
      aiRawLevel: aiResult?.confidenceLevel,
      aiSubstances: aiResult?.identifiedSubstances ?? [],
      aiColorDesc: aiResult?.observedColorDescription,
      spectralScore: colorResult.spectralMatchScore,
      spectralColorName: colorResult.matchedColorName,
      spectralSubstances: spectralSubstances,
    );

    Logger.info('✅ Pipeline complete: ${decision.resolutionPath}');
    Logger.info(
      '   Confidence=${decision.confidencePercentage}% '
      '| W_ai=${decision.weightAI.toStringAsFixed(2)} '
      '| W_match=${decision.weightMatch.toStringAsFixed(2)}'
    );

    return decision;
  }
}
