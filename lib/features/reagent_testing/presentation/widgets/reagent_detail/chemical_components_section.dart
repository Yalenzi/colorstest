import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../domain/entities/reagent_entity.dart';
import '../../../../../l10n/app_localizations.dart';

class ChemicalComponentsSection extends StatelessWidget {
  final ReagentEntity reagent;

  const ChemicalComponentsSection({super.key, required this.reagent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, l10n),
        const SizedBox(height: 16),
        _buildChemicalsList(theme),
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
              colors: [
                theme.colorScheme.secondary,
                theme.colorScheme.secondary.withOpacity(0.8),
              ],
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
            HeroIcons.beaker, // Chemistry beaker icon for chemical components
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.chemicalComponents,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChemicalsList(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: reagent.chemicals
              .map((chemical) => _ChemicalItem(chemical: chemical))
              .toList(),
        ),
      ),
    );
  }
}

class _ChemicalItem extends StatelessWidget {
  final String chemical;

  const _ChemicalItem({required this.chemical});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            HeroIcons.check_circle, // Better bullet point icon
            size: 12,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(chemical, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
