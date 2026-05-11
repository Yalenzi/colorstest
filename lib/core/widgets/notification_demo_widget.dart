import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../services/notification_service.dart';
import '../globals.dart';

class NotificationDemoWidget extends StatelessWidget {
  const NotificationDemoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => NotificationService.showSuccess(
            title: '✅ Success',
            message: 'This is a success notification!',
          ),
          child: const Text('Show Success Notification'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => NotificationService.showError(
            title: '❌ Error',
            message: 'This is an error notification!',
          ),
          child: const Text('Show Error Notification'),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => NotificationService.showInfo(
            title: '💡 Info',
            message: 'This is an info notification!',
          ),
          child: const Text('Show Info Notification'),
        ),
      ],
    );
  }
}

class TopNotificationWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback? onDismiss;
  final Duration duration;

  const TopNotificationWidget({
    super.key,
    required this.message,
    this.isError = true,
    this.onDismiss,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = widget.isError;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isError
                      ? [
                          const Color(0xFFFEF2F2), // Light red background
                          const Color(0xFFFDF2F8), // Light pink background
                        ]
                      : [
                          const Color(0xFFF0FDF4), // Light green background
                          const Color(0xFFF0F9FF), // Light blue background
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isError
                      ? const Color(0xFFFCA5A5).withOpacity(0.3) // Light red border
                      : const Color(
                          0xFF86EFAC,
                        ).withOpacity(0.3), // Light green border
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isError
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981))
                            .withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          (isError
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981))
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isError
                          ? HeroIcons.exclamation_triangle
                          : HeroIcons.check_circle,
                      size: 20,
                      color: isError
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isError
                            ? const Color(0xFF991B1B)
                            : const Color(0xFF047857),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:
                            (isError
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981))
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        HeroIcons.x_mark,
                        size: 16,
                        color: isError
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TopNotificationOverlay {
  static OverlayEntry? _currentOverlay;

  static void show({
    required String message,
    bool isError = true,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Remove existing notification if any
    hide();

    _currentOverlay = OverlayEntry(
      builder: (context) => TopNotificationWidget(
        message: message,
        isError: isError,
        duration: duration,
        onDismiss: hide,
      ),
    );

    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState != null) {
      overlayState.insert(_currentOverlay!);
    } else {
      debugPrint('❌ TopNotificationOverlay: navigatorKey.currentState?.overlay is null');
    }
  }

  static void hide() {
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}
