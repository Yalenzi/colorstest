import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:reagentkit/l10n/app_localizations.dart';
import '../states/settings_state.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsControllerProvider);
    final currentTheme = ref.watch(currentThemeModeProvider);
    final currentLanguage = ref.watch(currentLanguageProvider);

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.8),
              theme.colorScheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        HeroIcons.cog_6_tooth,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.settings,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
              ),
            ),
            SliverToBoxAdapter(
              child: _buildBody(
                context,
                l10n,
                ref,
                settingsState,
                currentTheme,
                currentLanguage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
    SettingsState settingsState,
    String currentTheme,
    String currentLanguage,
  ) {
    final theme = Theme.of(context);

    if (settingsState is SettingsLoading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (settingsState is SettingsError) {
      return Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.withOpacity(0.1),
              Colors.red.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                HeroIcons.exclamation_triangle,
                size: 48,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.errorLoadingSettings,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              settingsState.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Retry loading settings
              },
              icon: Icon(HeroIcons.arrow_path),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 16),

        // Appearance Section
        _buildEnhancedSection(
          title: l10n.appearance,
          icon: HeroIcons.paint_brush,
          gradient: [
            Colors.purple.withOpacity(0.1),
            Colors.blue.withOpacity(0.1),
          ],
          children: [
            SettingsDropdownTile<String>(
              title: l10n.theme,
              subtitle: l10n.themeSubtitle,
              leadingIcon: _getThemeIcon(currentTheme),
              value: currentTheme,
              items: [
                DropdownMenuItem(
                  value: 'light',
                  child: Row(
                    children: [
                      Icon(HeroIcons.sun, size: 16),
                      const SizedBox(width: 8),
                      Text(l10n.lightTheme),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'dark',
                  child: Row(
                    children: [
                      Icon(HeroIcons.moon, size: 16),
                      const SizedBox(width: 8),
                      Text(l10n.darkTheme),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'system',
                  child: Row(
                    children: [
                      Icon(HeroIcons.computer_desktop, size: 16),
                      const SizedBox(width: 8),
                      Text(l10n.systemTheme),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  final themeMode = switch (value) {
                    'light' => ThemeMode.light,
                    'dark' => ThemeMode.dark,
                    'system' => ThemeMode.system,
                    _ => ThemeMode.system,
                  };
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateTheme(themeMode);
                }
              },
              isFirst: true,
              isLast: true,
            ),
          ],
        ),

        // Language Section
        _buildEnhancedSection(
          title: l10n.language,
          icon: HeroIcons.language,
          gradient: [
            Colors.green.withOpacity(0.1),
            Colors.teal.withOpacity(0.1),
          ],
          children: [
            SettingsDropdownTile<String>(
              title: l10n.appLanguage,
              subtitle: l10n.appLanguageSubtitle,
              leadingIcon: HeroIcons.globe_alt,
              value: currentLanguage,
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            'EN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.english),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'ar',
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            'AR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.arabic),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .changeLanguage(value);
                }
              },
              isFirst: true,
              isLast: true,
            ),
          ],
        ),

        // About Section
        _buildEnhancedSection(
          title: l10n.about,
          icon: HeroIcons.information_circle,
          gradient: [
            Colors.indigo.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
          children: [
            SettingsTile(
              title: l10n.developers,
              subtitle: l10n.developersSubtitle,
              leadingIcon: HeroIcons.code_bracket,
              trailing: Icon(
                HeroIcons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onTap: () => _showDevelopersDialog(context, l10n),
              isFirst: true,
            ),
            SettingsTile(
              title: l10n.version,
              subtitle: '1.0.0',
              leadingIcon: HeroIcons.tag,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Latest',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              isLast: true,
            ),
          ],
        ),

        // Additional spacing at bottom
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildEnhancedSection({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gradient.first.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: SettingsSection(title: title, icon: icon, children: children),
    );
  }

  IconData _getThemeIcon(String theme) {
    return switch (theme) {
      'light' => HeroIcons.sun,
      'dark' => HeroIcons.moon,
      'system' => HeroIcons.computer_desktop,
      _ => HeroIcons.computer_desktop,
    };
  }

  void _showDevelopersDialog(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      HeroIcons.code_bracket,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.developersDialogTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l10n.reagentTestingApp,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.theDevelopers,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(l10n.developerOneName),
              Text(l10n.developerTwoName),
              const SizedBox(height: 16),
              Text(
                l10n.aboutTheApp,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(l10n.aboutTheAppContent),
              const SizedBox(height: 16),
              Text(
                l10n.contact,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    l10n.ok,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
