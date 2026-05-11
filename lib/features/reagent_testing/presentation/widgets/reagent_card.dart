import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../domain/entities/reagent_entity.dart';
import '../../../../core/utils/localization_helper.dart';

class ReagentCard extends StatelessWidget {
  final ReagentEntity reagent;
  final VoidCallback? onTap;

  const ReagentCard({super.key, required this.reagent, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeader(context),
              Flexible(child: _buildDescription(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIcon(context),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocalizationHelper.getLocalizedReagentName(context, reagent),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _buildSafetyBadge(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(BuildContext context) {
    Color iconBackgroundColor;
    switch (reagent.safetyLevel.toUpperCase()) {
      case 'EXTREME':
        iconBackgroundColor = Colors.red.withOpacity(0.1);
        break;
      case 'HIGH':
        iconBackgroundColor = Colors.orange.withOpacity(0.1);
        break;
      case 'MEDIUM':
        iconBackgroundColor = Colors.yellow.withOpacity(0.1);
        break;
      default:
        iconBackgroundColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        HeroIcons.beaker, // Chemistry beaker icon for reagent cards
        color: Theme.of(context).colorScheme.primary,
        size: 24,
      ),
    );
  }

  Widget _buildSafetyBadge(BuildContext context) {
    Color badgeColor;
    String level = reagent.safetyLevel.toUpperCase();

    switch (level) {
      case 'HIGH':
        badgeColor = Colors.orange;
        break;
      case 'EXTREME':
        badgeColor = Colors.red;
        break;
      case 'MEDIUM':
        badgeColor = Colors.yellow.shade700;
        break;
      case 'LOW':
        badgeColor = Colors.green;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        LocalizationHelper.getLocalizedSafetyLevelTranslation(context, level),
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      LocalizationHelper.getLocalizedDescription(context, reagent),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
