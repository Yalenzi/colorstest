import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:reagentkit/features/reagent_testing/domain/entities/reagent_entity.dart';
import 'package:reagentkit/features/reagent_testing/presentation/providers/reagent_testing_providers.dart';
import 'package:reagentkit/features/reagent_testing/presentation/states/test_result_state.dart';
import 'package:reagentkit/features/reagent_testing/presentation/views/test_result_page.dart';
import 'package:reagentkit/core/utils/logger.dart';
import 'package:reagentkit/l10n/app_localizations.dart';

class CompleteTestSection extends ConsumerWidget {
  final ReagentEntity reagent;
  const CompleteTestSection({super.key, required this.reagent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    ref.listen<TestResultState>(testResultControllerProvider, (previous, next) {
      if (next is TestResultLoaded) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const TestResultPage()));
      } else if (next is TestResultError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_getErrorLabel(l10n)}: ${next.message}')),
        );
      }
    });

    final state = ref.watch(testExecutionControllerProvider);

    final isReady = state.maybeWhen(
      loaded: (execution, aiResult, notes) {
        return execution.selectedColor != null || aiResult != null;
      },
      orElse: () => false,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isReady
              ? const Color(0xFF10B981) // Vibrant green for enabled state
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.12), // Disabled color
          foregroundColor: isReady
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
          elevation: isReady ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isReady ? () => _completeTest(context, ref, reagent) : null,
        icon: Icon(
          isReady ? HeroIcons.check_circle : HeroIcons.clock,
          size: 20,
        ),
        label: Text(
          _getCompleteTestLabel(l10n),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _getCompleteTestLabel(AppLocalizations l10n) {
    return l10n.localeName == 'ar' ? 'إكمال الاختبار' : 'Complete Test';
  }

  String _getErrorLabel(AppLocalizations l10n) {
    return l10n.localeName == 'ar' ? 'خطأ' : 'Error';
  }

  void _completeTest(
    BuildContext context,
    WidgetRef ref,
    ReagentEntity reagent,
  ) {
    final state = ref.read(testExecutionControllerProvider);
    state.when(
      initial: () => Logger.error('Complete Test pressed in initial state.'),
      loading: () => Logger.error('Complete Test pressed in loading state.'),
      loaded: (execution, aiResult, notes) {
        if (aiResult != null) {
          final List<String> allNotes = [];
          if (aiResult.analysisNotes.isNotEmpty) {
            final aiLabel = Localizations.localeOf(context).languageCode == 'ar'
                ? 'تحليل الذكاء الاصطناعي'
                : 'AI Analysis';
            allNotes.add('$aiLabel:\n${aiResult.analysisNotes}');
          }
          if (notes.isNotEmpty) {
            final userNotesLabel =
                Localizations.localeOf(context).languageCode == 'ar'
                ? 'ملاحظات المستخدم'
                : 'User Notes';
            allNotes.add('$userNotesLabel:\n$notes');
          }
          final finalNotes = allNotes.isEmpty ? null : allNotes.join('\n\n');

          ref
              .read(testResultControllerProvider.notifier)
              .analyzeTestResultWithAI(
                reagent: reagent,
                aiResult: aiResult,
                notes: finalNotes,
              );
        } else if (execution.selectedColor != null) {
          ref
              .read(testResultControllerProvider.notifier)
              .analyzeTestResult(
                reagent: reagent,
                observedColor: execution.selectedColor!,
                notes: notes,
              );
        } else {
          Logger.error(
            'Complete Test button pressed but no color source is available.',
          );
          return;
        }
      },
      error: (message) =>
          Logger.error('Complete Test pressed in error state: $message'),
    );
  }
}
