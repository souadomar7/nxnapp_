import 'package:flutter/material.dart';

enum AppBadgeVariant {
  success,
  warning,
  error,
  info,
  neutral,
  active,
  pending,
  expired,
}

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case AppBadgeVariant.success:
      case AppBadgeVariant.active:
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case AppBadgeVariant.warning:
      case AppBadgeVariant.pending:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        break;
      case AppBadgeVariant.error:
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
      case AppBadgeVariant.info:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
      case AppBadgeVariant.expired:
      case AppBadgeVariant.neutral:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
