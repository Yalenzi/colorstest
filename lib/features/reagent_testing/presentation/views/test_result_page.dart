import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
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
      return Center(child: Text(l10n.loading));
    } else if (state is TestResultLoaded) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  AppBar().preferredSize.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  48, // Extra padding
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                TestResultContent(testResult: state.testResult),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    } else if (state is TestResultError) {
      return Center(child: Text(l10n.error(state.message)));
    } else {
      return Center(child: Text(l10n.noTestResultsYet));
    }
  }
}

class TestResultContent extends StatelessWidget {
  final TestResultEntity testResult;

  const TestResultContent({super.key, required this.testResult});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.testResults,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildResultRow(
              context,
              label: l10n.reagent,
              value: testResult.reagentName,
            ),
            const SizedBox(height: 16),
            _buildResultRow(
              context,
              label: l10n.observedColor,
              value: testResult.observedColor,
            ),
            const SizedBox(height: 16),
            _buildResultRow(
              context,
              label: l10n.possibleSubstances,
              value: testResult.possibleSubstances.join(', '),
            ),
            const SizedBox(height: 16),
            _buildResultRow(
              context,
              label: l10n.confidence,
              value: '${testResult.confidencePercentage}%',
            ),
            if (testResult.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 16),
              _buildResultRow(
                context,
                label: l10n.notes,
                value: testResult.notes!,
              ),
            ],

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(HeroIcons.home),
                label: Text(l10n.backToHome),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
