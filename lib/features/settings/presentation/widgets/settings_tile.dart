import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class SettingsTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.onTap != null ? (_) => _onTapDown() : null,
            onTapUp: widget.onTap != null ? (_) => _onTapUp() : null,
            onTapCancel: widget.onTap != null ? _onTapCancel : null,
            onTap: widget.onTap,
            child: Container(
              margin: EdgeInsets.only(
                top: widget.isFirst ? 12 : 0,
                bottom: widget.isLast ? 12 : 0,
                left: 12,
                right: 12,
              ),
              decoration: BoxDecoration(
                color: _isPressed
                    ? theme.colorScheme.primaryContainer.withOpacity(0.1)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.vertical(
                  top: widget.isFirst ? const Radius.circular(16) : Radius.zero,
                  bottom: widget.isLast
                      ? const Radius.circular(16)
                      : Radius.zero,
                ),
                border: !widget.isLast
                    ? Border(
                        bottom: BorderSide(
                          color: theme.dividerColor.withOpacity(0.2),
                          width: 0.5,
                        ),
                      )
                    : null,
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    if (widget.leadingIcon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.1),
                              theme.colorScheme.primary.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.leadingIcon,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 16),
                      widget.trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTapDown() {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }
}

class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isFirst;
  final bool isLast;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    required this.value,
    this.onChanged,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsTile(
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      isFirst: isFirst,
      isLast: isLast,
      trailing: Transform.scale(
        scale: 0.9,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: theme.colorScheme.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      onTap: onChanged != null ? () => onChanged!(!value) : null,
    );
  }
}

class SettingsDropdownTile<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isFirst;
  final bool isLast;

  const SettingsDropdownTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    required this.value,
    required this.items,
    this.onChanged,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsTile(
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      isFirst: isFirst,
      isLast: isLast,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surfaceContainer,
              theme.colorScheme.surfaceContainerLow,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          underline: const SizedBox(),
          isDense: true,
          icon: Icon(
            HeroIcons.chevron_down,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: theme.colorScheme.surface,
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
