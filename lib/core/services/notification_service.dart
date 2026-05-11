import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../globals.dart';
import '../utils/logger.dart';

enum NotificationType { success, error, warning, info }

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static void showNotification({
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 4),
    String? title,
    VoidCallback? onTap,
  }) {
    final scaffoldMessenger = scaffoldMessengerKey.currentState;
    if (scaffoldMessenger == null) {
      Logger.error('❌ NotificationService: scaffoldMessengerKey.currentState is null');
      return;
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: _NotificationContent(
          message: message,
          type: type,
          title: title,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
        duration: duration,
        padding: EdgeInsets.zero,
        action: onTap != null
            ? SnackBarAction(label: 'View', onPressed: onTap, textColor: _getTextColor(type))
            : null,
      ),
    );
  }

  // Show success notification
  static void showSuccess({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    showNotification(
      message: message,
      type: NotificationType.success,
      title: title ?? '✅ Success',
      duration: duration,
      onTap: onTap,
    );
  }

  // Show error notification
  static void showError({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onTap,
  }) {
    showNotification(
      message: message,
      type: NotificationType.error,
      title: title ?? '❌ Error',
      duration: duration,
      onTap: onTap,
    );
  }

  // Show warning notification
  static void showWarning({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    showNotification(
      message: message,
      type: NotificationType.warning,
      title: title ?? '⚠️ Warning',
      duration: duration,
      onTap: onTap,
    );
  }

  // Show info notification
  static void showInfo({
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    showNotification(
      message: message,
      type: NotificationType.info,
      title: title ?? 'ℹ️ Info',
      duration: duration,
      onTap: onTap,
    );
  }

  // Registration success notification
  static void showRegistrationSuccess({
    required String username,
  }) {
    showSuccess(
      title: '🎉 Welcome to the Lab!',
      message:
          'Account created successfully for $username. You can now start testing reagents!',
      duration: const Duration(seconds: 5),
    );
  }

  // Login success notification
  static void showLoginSuccess({
    required String username,
  }) {
    showSuccess(
      title: '🔬 Welcome Back!',
      message: 'Successfully signed in as $username. Ready for testing?',
      duration: const Duration(seconds: 3),
    );
  }

  // Test completion notification
  static void showTestCompleted({
    required String testName,
  }) {
    showSuccess(
      title: '🧪 Test Completed',
      message: '$testName test has been completed successfully!',
      duration: const Duration(seconds: 4),
    );
  }
}

Color _getBackgroundColor(NotificationType type) {
  switch (type) {
    case NotificationType.success:
      return const Color(0xFFF0FDF4);
    case NotificationType.error:
      return const Color(0xFFFEF2F2);
    case NotificationType.warning:
      return const Color(0xFFFFFBEB);
    case NotificationType.info:
      return const Color(0xFFF0F9FF);
  }
}

Color _getBorderColor(NotificationType type) {
  switch (type) {
    case NotificationType.success:
      return const Color(0xFF10B981);
    case NotificationType.error:
      return const Color(0xFFEF4444);
    case NotificationType.warning:
      return const Color(0xFFF59E0B);
    case NotificationType.info:
      return const Color(0xFF3B82F6);
  }
}

Color _getTextColor(NotificationType type) {
  switch (type) {
    case NotificationType.success:
      return const Color(0xFF059669);
    case NotificationType.error:
      return const Color(0xFFDC2626);
    case NotificationType.warning:
      return const Color(0xFFD97706);
    case NotificationType.info:
      return const Color(0xFF1D4ED8);
  }
}

IconData _getIcon(NotificationType type) {
  switch (type) {
    case NotificationType.success:
      return HeroIcons.check_circle;
    case NotificationType.error:
      return HeroIcons.exclamation_triangle;
    case NotificationType.warning:
      return HeroIcons.exclamation_triangle;
    case NotificationType.info:
      return HeroIcons.information_circle;
  }
}

class _NotificationContent extends StatelessWidget {
  final String message;
  final NotificationType type;
  final String? title;

  const _NotificationContent({
    required this.message,
    required this.type,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(type),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(type).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              color: _getBorderColor(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIcon(type),
              color: _getBorderColor(type),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      color: _getTextColor(type),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (title != null) const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: _getTextColor(type).withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => scaffoldMessengerKey.currentState?.hideCurrentSnackBar(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _getBorderColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                HeroIcons.x_mark,
                color: _getBorderColor(type),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
