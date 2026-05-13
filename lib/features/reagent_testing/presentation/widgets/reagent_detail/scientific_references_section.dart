import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../domain/entities/reagent_entity.dart';
import '../../../../../l10n/app_localizations.dart';

class ScientificReferencesSection extends StatelessWidget {
  final ReagentEntity reagent;

  const ScientificReferencesSection({super.key, required this.reagent});

  @override
  Widget build(BuildContext context) {
    if (reagent.references.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, l10n),
        const SizedBox(height: 16),
        _ReferencesCard(reagent: reagent),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.secondary, theme.colorScheme.secondary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.secondary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            HeroIcons.book_open,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.references,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ReferencesCard extends StatelessWidget {
  final ReagentEntity reagent;

  const _ReferencesCard({required this.reagent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: reagent.references.map((ref) => _ReferenceItem(reference: ref)).toList(),
        ),
      ),
    );
  }
}

class _ReferenceItem extends StatelessWidget {
  final String reference;

  const _ReferenceItem({required this.reference});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              reference,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
