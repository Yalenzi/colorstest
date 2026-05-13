import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../domain/entities/reagent_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../controllers/reagent_detail_controller.dart';

import '../../views/test_execution_page.dart';

class StartTestButton extends ConsumerWidget {
  final ReagentEntity reagent;

  const StartTestButton({super.key, required this.reagent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isAcknowledged = ref.watch(reagentDetailControllerProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isAcknowledged ? () => _navigateToTest(context) : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: isAcknowledged
                  ? const Color(0xFF10B981) // Vibrant green for enabled state
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.12), // Disabled color
              foregroundColor: isAcknowledged
                  ? Colors.white
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.38),
              elevation: isAcknowledged ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAcknowledged
                      ? HeroIcons.play
                      : HeroIcons.exclamation_triangle,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  isAcknowledged
                      ? l10n.startTest
                      : l10n.safetyAcknowledgmentRequired,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestExecutionPage(reagent: reagent),
      ),
    );
  }
}
