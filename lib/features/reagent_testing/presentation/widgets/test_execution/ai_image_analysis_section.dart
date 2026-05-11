import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reagentkit/features/reagent_testing/domain/entities/reagent_entity.dart';
import 'package:reagentkit/features/reagent_testing/data/models/gemini_analysis_models.dart';
import 'package:reagentkit/features/reagent_testing/presentation/providers/reagent_testing_providers.dart';
import 'package:reagentkit/core/utils/logger.dart';
import 'package:reagentkit/l10n/app_localizations.dart';

class AIImageAnalysisSection extends ConsumerStatefulWidget {
  final ReagentEntity reagent;
  const AIImageAnalysisSection({super.key, required this.reagent});

  @override
  ConsumerState<AIImageAnalysisSection> createState() =>
      _AIImageAnalysisSectionState();
}

class _AIImageAnalysisSectionState
    extends ConsumerState<AIImageAnalysisSection> {
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  bool _isAnalyzing = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(testExecutionControllerProvider);
    final isDarkMode = theme.brightness == Brightness.dark;

    final aiResult = state.maybeWhen(
      loaded: (execution, aiResult, notes) => aiResult,
      orElse: () => null,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainer,
                  theme.colorScheme.surface,
                ]
              : [
                  Colors.purple.shade50,
                  Colors.indigo.shade50,
                  Colors.blue.shade50,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: isDarkMode
            ? Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? theme.colorScheme.shadow.withOpacity(0.1)
                : Colors.purple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          if (!isDarkMode)
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 8,
              offset: const Offset(-4, -4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDarkMode
                          ? [
                              theme.colorScheme.primary,
                              theme.colorScheme.primaryContainer,
                            ]
                          : [Colors.purple.shade400, Colors.indigo.shade500],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? theme.colorScheme.primary.withOpacity(0.2)
                            : Colors.purple.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    HeroIcons.sparkles,
                    color: isDarkMode
                        ? theme.colorScheme.onPrimary
                        : Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aiAnalysis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? theme.colorScheme.onSurface
                              : Colors.indigo.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.uploadImageDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(HeroIcons.camera),
                    label: Text(l10n.captureImage),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(HeroIcons.photo),
                    label: Text(l10n.fromGallery),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade400,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_capturedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _capturedImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isAnalyzing)
                      const CircularProgressIndicator()
                    else
                      Consumer(
                        builder: (context, ref, child) {
                          final geminiServiceAsync = ref.watch(
                            geminiAnalysisServiceProvider,
                          );

                          return geminiServiceAsync.when(
                            data: (service) => ElevatedButton.icon(
                              onPressed: _analyzeImage,
                              icon: Icon(HeroIcons.sparkles),
                              label: Text(l10n.analyzeWithAI),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? Colors.green.shade600
                                    : Colors.green.shade500,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            loading: () => ElevatedButton.icon(
                              onPressed: null,
                              icon: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDarkMode
                                      ? theme.colorScheme.onSurfaceVariant
                                      : Colors.white,
                                ),
                              ),
                              label: const Text('Loading AI...'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? theme.colorScheme.surfaceContainerHigh
                                    : Colors.grey.shade400,
                                foregroundColor: isDarkMode
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            error: (error, stack) => ElevatedButton.icon(
                              onPressed: null,
                              icon: Icon(HeroIcons.exclamation_triangle),
                              label: const Text('AI Service Error'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? theme.colorScheme.errorContainer
                                    : Colors.red.shade400,
                                foregroundColor: isDarkMode
                                    ? theme.colorScheme.onErrorContainer
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            if (aiResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _buildAIResult(aiResult, l10n),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? theme.colorScheme.errorContainer
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode
                          ? theme.colorScheme.error.withOpacity(0.5)
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        HeroIcons.exclamation_triangle,
                        color: isDarkMode
                            ? theme.colorScheme.onErrorContainer
                            : Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: isDarkMode
                                ? theme.colorScheme.onErrorContainer
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIResult(GeminiReagentTestResult result, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? theme.colorScheme.outline.withOpacity(0.2)
              : theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                HeroIcons.sparkles,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.aiAnalysisResult,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildResultRow(
            context,
            l10n.observedColor,
            result.observedColorDescription,
            HeroIcons.swatch,
          ),
          const SizedBox(height: 8),
          _buildResultRow(
            context,
            _getSubstanceLabel(l10n),
            result.primarySubstance,
            HeroIcons.beaker,
          ),
          const SizedBox(height: 8),
          _buildResultRow(
            context,
            _getConfidenceLabel(l10n),
            result.confidenceLevel,
            HeroIcons.chart_bar_square,
          ),
          if (result.analysisNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildResultRow(
              context,
              l10n.analysisNotes,
              result.analysisNotes,
              HeroIcons.document_text,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getSubstanceLabel(AppLocalizations l10n) {
    return l10n.localeName == 'ar' ? 'المادة' : 'Substance';
  }

  String _getConfidenceLabel(AppLocalizations l10n) {
    return l10n.localeName == 'ar' ? 'مستوى الثقة' : 'Confidence';
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );
    if (image != null) {
      setState(() {
        _capturedImage = File(image.path);
        _error = null;
      });
      ref
          .read(testExecutionControllerProvider.notifier)
          .updateAIAnalysisResult(null);
    }
  }

  Future<void> _analyzeImage() async {
    if (_capturedImage == null) return;
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      // Get the AsyncValue from the FutureProvider
      final geminiServiceAsync = ref.read(geminiAnalysisServiceProvider);

      // Handle the async value
      await geminiServiceAsync.when(
        data: (geminiService) async {
          final drugResults = widget.reagent.drugResults
              .map(
                (result) => {
                  'drugName': result.drugName,
                  'color': result.color,
                },
              )
              .toList();

          final resultString = await geminiService.analyzeReagentTestImage(
            imageFile: _capturedImage!,
            reagentName: widget.reagent.reagentName,
            drugResults: drugResults,
            testContext: {'type': 'reagent_test'},
          );

          final resultJson = jsonDecode(resultString);
          final aiResult = GeminiReagentTestResult.fromJson(resultJson);

          ref
              .read(testExecutionControllerProvider.notifier)
              .updateAIAnalysisResult(aiResult);
        },
        loading: () {
          // Service is still loading, keep showing progress
          Logger.info('Gemini service is still initializing...');
        },
        error: (error, stack) {
          throw Exception('Gemini service initialization failed: $error');
        },
      );
    } catch (e) {
      Logger.error('AI Analysis failed: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _error = l10n.aiAnalysisError;
        });
      }
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }
}
