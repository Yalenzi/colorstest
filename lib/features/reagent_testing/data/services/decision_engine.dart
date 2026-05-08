// ---------------------------------------------------------------------------
// DecisionEngineResult — the output of the full hybrid pipeline
// ---------------------------------------------------------------------------

/// Every field has a strict mathematical interpretation.
class DecisionEngineResult {
  // ── Sources ────────────────────────────────────────────────────────────────
  /// Spectral match score S_match ∈ [0, 1].
  final double spectralMatchScore;

  /// AI heuristic score S_ai ∈ [0, 1].
  final double aiScore;

  // ── Weights ────────────────────────────────────────────────────────────────
  /// W_ai + W_match == 1.0  (enforced at construction).
  final double weightAI;
  final double weightMatch;

  // ── Final output ──────────────────────────────────────────────────────────
  /// C = W_ai × S_ai + W_match × S_match   ∈ [0, 1]
  final double confidence;

  /// Final confidence as an integer percentage [0, 100].
  int get confidencePercentage => (confidence * 100).round();

  /// Chosen substance list after conflict resolution.
  final List<String> resolvedSubstances;

  /// The human-readable observed color string.
  final String resolvedColorDescription;

  /// Conflict was detected and resolved.
  final bool hadConflict;

  /// How the conflict was resolved (for audit/debug).
  final String resolutionPath;

  const DecisionEngineResult({
    required this.spectralMatchScore,
    required this.aiScore,
    required this.weightAI,
    required this.weightMatch,
    required this.confidence,
    required this.resolvedSubstances,
    required this.resolvedColorDescription,
    required this.hadConflict,
    required this.resolutionPath,
  });
}

// ---------------------------------------------------------------------------
// DecisionEngine — Conflict Resolution + Confidence Fusion
// ---------------------------------------------------------------------------
///
/// Weight policy:
///   When Gemini is available AND high-confidence → W_ai = 0.65, W_match = 0.35
///   When Gemini is available AND medium-confidence → W_ai = 0.50, W_match = 0.50
///   When Gemini is missing / failed              → W_ai = 0.00, W_match = 1.00
///   When spectral match fails (noisy image)      → W_ai = 0.85, W_match = 0.15
///
/// Conflict resolution (Decision Tree):
///
///   [AI_score > 0.80] AND [S_Match < 0.60]  →  TRUST AI, flag conflict
///   [AI_score < 0.50] AND [S_Match > 0.70]  →  TRUST SPECTRAL
///   both agree (|AI - S_Match| < 0.20)       →  MERGE (weighted average)
///   otherwise                                →  WEIGHTED MERGE + lower confidence
///
class DecisionEngine {
  // Conflict boundary constants
  static const double _aiHighThreshold        = 0.80;
  static const double _aiLowThreshold         = 0.50;
  static const double _spectralHighThreshold  = 0.70;
  static const double _agreeWindow            = 0.20;

  /// Core fusion method.
  ///
  /// [aiRawLevel]       — Gemini's string: "High" / "Medium" / "Low" / null
  /// [aiSubstances]     — substances from Gemini
  /// [aiColorDesc]      — observed_color_description from Gemini
  /// [spectralScore]    — S_match from ColorAnalysisEngine
  /// [spectralColorName]— matched color name from reagent chart
  /// [spectralSubstances]— substances matched via spectral method
  DecisionEngineResult resolve({
    required String? aiRawLevel,
    required List<String> aiSubstances,
    required String? aiColorDesc,
    required double spectralScore,
    required String? spectralColorName,
    required List<String> spectralSubstances,
  }) {
    final S_ai    = _aiScoreFromLevel(aiRawLevel);
    final S_match = spectralScore.clamp(0.0, 1.0);
    final geminiAvailable = aiRawLevel != null;

    // ── Determine weights ──────────────────────────────────────────────────
    double W_ai, W_match;

    if (!geminiAvailable) {
      // No Gemini → pure spectral
      W_ai = 0.0; W_match = 1.0;
    } else if (S_match < 0.30) {
      // Noisy / low-quality image → trust AI more
      W_ai = 0.85; W_match = 0.15;
    } else if (S_ai >= _aiHighThreshold) {
      W_ai = 0.65; W_match = 0.35;
    } else if (S_ai >= _aiLowThreshold) {
      W_ai = 0.50; W_match = 0.50;
    } else {
      W_ai = 0.35; W_match = 0.65;
    }

    // Enforce W_ai + W_match == 1.0
    assert((W_ai + W_match - 1.0).abs() < 1e-9, 'Weights must sum to 1');

    // ── Decide which source is authoritative ──────────────────────────────
    final diff = (S_ai - S_match).abs();
    bool hadConflict = false;
    String resolutionPath;
    List<String> resolvedSubstances;
    String resolvedColor;

    if (S_ai > _aiHighThreshold && S_match < _spectralHighThreshold * 0.85) {
      // Branch A: AI strongly confident, spectral disagrees
      //  → trust AI, but penalise confidence
      hadConflict = true;
      resolutionPath = 'BRANCH_A: AI_high + Spectral_low → trust AI (−10% confidence)';
      resolvedSubstances = aiSubstances.isNotEmpty ? aiSubstances : spectralSubstances;
      resolvedColor      = aiColorDesc ?? spectralColorName ?? 'Unknown';

      // Penalise confidence for conflict
      final rawConf = W_ai * S_ai + W_match * S_match;
      final penalised = (rawConf - 0.10).clamp(0.0, 1.0);
      return DecisionEngineResult(
        spectralMatchScore:  S_match,
        aiScore:             S_ai,
        weightAI:            W_ai,
        weightMatch:         W_match,
        confidence:          penalised,
        resolvedSubstances:  resolvedSubstances,
        resolvedColorDescription: resolvedColor,
        hadConflict:         hadConflict,
        resolutionPath:      resolutionPath,
      );

    } else if (S_ai < _aiLowThreshold && S_match > _spectralHighThreshold) {
      // Branch B: AI uncertain, spectral is confident
      //  → trust spectral
      hadConflict = true;
      resolutionPath = 'BRANCH_B: AI_low + Spectral_high → trust Spectral';
      resolvedSubstances = spectralSubstances.isNotEmpty ? spectralSubstances : aiSubstances;
      resolvedColor      = spectralColorName ?? aiColorDesc ?? 'Unknown';

    } else if (diff < _agreeWindow) {
      // Branch C: Both agree within ±0.20
      resolutionPath = 'BRANCH_C: Agreement → weighted merge';
      resolvedSubstances = _mergeSubstances(aiSubstances, spectralSubstances);
      resolvedColor      = aiColorDesc ?? spectralColorName ?? 'Unknown';

    } else {
      // Branch D: Moderate conflict → weighted merge, reduced confidence
      hadConflict = true;
      resolutionPath = 'BRANCH_D: Moderate conflict → weighted merge (−5% confidence)';
      resolvedSubstances = _mergeSubstances(aiSubstances, spectralSubstances);
      resolvedColor      = aiColorDesc ?? spectralColorName ?? 'Unknown';
    }

    // ── Confidence formula ─────────────────────────────────────────────────
    //   C = W_ai × S_ai + W_match × S_match
    double confidence = W_ai * S_ai + W_match * S_match;
    if (resolutionPath.startsWith('BRANCH_D')) {
      confidence = (confidence - 0.05).clamp(0.0, 1.0);
    }

    return DecisionEngineResult(
      spectralMatchScore:  S_match,
      aiScore:             S_ai,
      weightAI:            W_ai,
      weightMatch:         W_match,
      confidence:          confidence,
      resolvedSubstances:  resolvedSubstances,
      resolvedColorDescription: resolvedColor,
      hadConflict:         hadConflict,
      resolutionPath:      resolutionPath,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Maps Gemini's string confidence level to a numeric score.
  double _aiScoreFromLevel(String? level) {
    if (level == null) return 0.0;
    switch (level.toLowerCase().trim()) {
      case 'high':
      case 'very high': return 0.92;
      case 'medium':
      case 'moderate':  return 0.68;
      case 'low':       return 0.38;
      default:          return 0.50;
    }
  }

  /// Returns non-duplicate merged list (AI first, spectral as supplement).
  List<String> _mergeSubstances(List<String> ai, List<String> spectral) {
    final result = <String>{...ai};
    for (final s in spectral) {
      result.add(s);
    }
    return result.toList();
  }
}
