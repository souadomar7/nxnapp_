import 'package:flutter/material.dart';
import '../../theme.dart';

enum AppButtonVariant { primary, secondary, destructive, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bgColor = AppColors.bluePrimary;
        fgColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bgColor = Colors.white;
        fgColor = AppColors.bluePrimary;
        border = const BorderSide(color: AppColors.bluePrimary, width: 1.5);
        break;
      case AppButtonVariant.destructive:
        bgColor = Colors.red.shade600;
        fgColor = Colors.white;
        break;
      case AppButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = AppColors.bluePrimary;
        break;
    }

    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fgColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: variant == AppButtonVariant.primary ? 1.5 : 0,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: effectiveOnPressed,
        child: child,
      ),
    );
  }
}
