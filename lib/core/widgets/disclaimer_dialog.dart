import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A reusable legal disclaimer dialog that must be accepted on first app launch.
/// Uses SharedPreferences to persist acceptance state.
class DisclaimerDialog {
  static const String _disclaimerKey = 'hasAcceptedDisclaimer';

  /// Shows the disclaimer dialog if the user has not previously accepted it.
  /// The dialog is non-dismissible — the user must tap "I Understand".
  static Future<void> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasAccepted = prefs.getBool(_disclaimerKey) ?? false;

    if (!hasAccepted && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _DisclaimerDialogContent(),
      );
      await prefs.setBool(_disclaimerKey, true);
    }
  }
}

class _DisclaimerDialogContent extends StatelessWidget {
  const _DisclaimerDialogContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.withOpacity(0.2),
                    Colors.orange.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(
                Icons.gavel_rounded,
                size: 36,
                color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Disclaimer',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Body
            Text(
              'This app is for educational and informational purposes only.\n\n'
              'It does not guarantee accurate identification of substances.\n\n'
              'Do not use results for legal or medical decisions.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Accept Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'I Understand',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
