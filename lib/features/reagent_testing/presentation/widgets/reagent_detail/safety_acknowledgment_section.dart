import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../domain/entities/reagent_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../controllers/reagent_detail_controller.dart';

class SafetyAcknowledgmentSection extends ConsumerWidget {
  final ReagentEntity reagent;

  const SafetyAcknowledgmentSection({super.key, required this.reagent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isAcknowledged = ref.watch(reagentDetailControllerProvider);
    final controller = ref.read(reagentDetailControllerProvider.notifier);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme, l10n),
            const SizedBox(height: 16),
            _buildAcknowledgmentCheckbox(
              theme,
              l10n,
              isAcknowledged,
              controller,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade600, Colors.green.shade400],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            HeroIcons.shield_check, // Safety acknowledgment icon
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.safetyAcknowledgment,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAcknowledgmentCheckbox(
    ThemeData theme,
    AppLocalizations l10n,
    bool isAcknowledged,
    ReagentDetailController controller,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: isAcknowledged,
          onChanged: (value) =>
              controller.setSafetyAcknowledgment(value ?? false),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.safetyAcknowledgmentText,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
