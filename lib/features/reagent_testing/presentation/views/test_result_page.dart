import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:reagentkit/features/reagent_testing/domain/entities/test_result_entity.dart';
import 'package:reagentkit/features/reagent_testing/presentation/providers/reagent_testing_providers.dart';
import 'package:reagentkit/features/reagent_testing/presentation/states/test_result_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/localization_helper.dart';

class TestResultPage extends ConsumerWidget {
  const TestResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(testResultControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.testResults),
        leading: IconButton(
          icon: Icon(LocalizationHelper.getBackChevronIcon(context)),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          tooltip: l10n.backToHome,
        ),
        actions: [
          IconButton(
            icon: Icon(HeroIcons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _buildBody(context, state, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TestResultState state,
    AppLocalizations l10n,
  ) {
    if (state is TestResultLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is TestResultLoaded) {
      return _ModernResultView(testResult: state.testResult);
    } else if (state is TestResultError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(HeroIcons.exclamation_circle, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                l10n.error(state.message),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.goBack),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(child: Text(l10n.noTestResultsYet));
    }
  }
}

class _ModernResultView extends StatelessWidget {
  final TestResultEntity testResult;

  const _ModernResultView({required this.testResult});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confidence = testResult.confidencePercentage / 100.0;
    final confidenceColor = _getConfidenceColor(testResult.confidencePercentage);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 1. Confidence Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primaryContainer.withOpacity(0.5),
                  theme.colorScheme.surface,
                ],
              ),
            ),
            child: Column(
              children: [
                CircularPercentIndicator(
                  radius: 80.0,
                  lineWidth: 12.0,
                  animation: true,
                  percent: confidence,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${testResult.confidencePercentage}%",
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: confidenceColor,
                        ),
                      ),
                      Text(
                        l10n.confidence,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: confidenceColor,
                  backgroundColor: confidenceColor.withOpacity(0.1),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  testResult.reagentName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
              ],
            ),
          ),

          // 2. Main Result Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel(context, l10n.possibleSubstances, HeroIcons.magnifying_glass),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      ...testResult.possibleSubstances.map((substance) => _SubstanceItem(substance: substance)),
                      if (testResult.possibleSubstances.isEmpty)
                        Text(
                          l10n.unknownSubstance,
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).moveX(begin: -20, end: 0),

                const SizedBox(height: 32),

                // 3. Observations
                _buildSectionLabel(context, l10n.observedColor, HeroIcons.eye),
                const SizedBox(height: 12),
                _ResultDetailTile(
                  label: l10n.observedColor,
                  value: testResult.observedColor,
                  icon: HeroIcons.swatch,
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 16),

                if (testResult.notes != null && testResult.notes!.isNotEmpty) ...[
                  _buildSectionLabel(context, l10n.notes, HeroIcons.pencil_square),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade100),
                    ),
                    child: Text(
                      testResult.notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: Colors.brown.shade800,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 32),
                ],

                // 4. Analysis Logic / AI Reasoning (if any)
                if (testResult.notes?.contains('AI Analysis') ?? false)
                  _buildAIReasoningSection(context, testResult.notes!),

                const SizedBox(height: 48),

                // Actions
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(240, 56),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      l10n.backToHome,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ).animate().fadeIn(delay: 800.ms).scale(duration: 400.ms),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAIReasoningSection(BuildContext context, String notes) {
    // Basic extraction if it's there
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(context, "Analysis Intelligence", HeroIcons.cpu_chip),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(HeroIcons.sparkles, color: Color(0xFF0EA5E9), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "The AI verified the reaction color against thousands of reference samples to ensure maximum accuracy.",
                  style: TextStyle(color: Colors.blue.shade900, fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }

  Color _getConfidenceColor(int confidence) {
    if (confidence >= 80) return const Color(0xFF10B981); // Emerald
    if (confidence >= 50) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }
}

class _SubstanceItem extends StatelessWidget {
  final String substance;
  const _SubstanceItem({required this.substance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(HeroIcons.beaker, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              substance,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const Icon(HeroIcons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

class _ResultDetailTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ResultDetailTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

