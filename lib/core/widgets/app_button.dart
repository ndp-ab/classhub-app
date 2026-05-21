import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.fullWidth = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool fullWidth;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || loading;

    final double height = switch (size) {
      AppButtonSize.small => 40,
      AppButtonSize.medium => 48,
      AppButtonSize.large => 56,
    };

    final EdgeInsets padding = switch (size) {
      AppButtonSize.small => const EdgeInsets.symmetric(horizontal: AppSpacing.element),
      AppButtonSize.medium => const EdgeInsets.symmetric(horizontal: AppSpacing.sectionPadding),
      AppButtonSize.large => const EdgeInsets.symmetric(horizontal: AppSpacing.largeSection),
    };

    final TextStyle textStyle = switch (size) {
      AppButtonSize.small => AppTextStyles.button.copyWith(fontSize: 14),
      AppButtonSize.medium => AppTextStyles.button,
      AppButtonSize.large => AppTextStyles.button.copyWith(fontSize: 17),
    };

    final _ButtonColors colors = _resolveColors(variant, isDisabled);

    final Widget content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colors.foreground),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18, color: colors.foreground),
                const SizedBox(width: AppSpacing.small),
              ],
              Flexible(
                child: Text(
                  label,
                  style: textStyle.copyWith(color: colors.foreground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingIcon != null) ...<Widget>[
                const SizedBox(width: AppSpacing.small),
                Icon(trailingIcon, size: 18, color: colors.foreground),
              ],
            ],
          );

    final BorderRadius radius = BorderRadius.circular(AppRadius.button);

    final Widget button = Material(
      color: colors.background,
      borderRadius: radius,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        borderRadius: radius,
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: colors.borderColor == null
                ? null
                : Border.all(color: colors.borderColor!),
          ),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  _ButtonColors _resolveColors(AppButtonVariant variant, bool disabled) {
    if (disabled) {
      return const _ButtonColors(
        background: AppColors.border,
        foreground: AppColors.textSecondary,
        borderColor: null,
      );
    }
    switch (variant) {
      case AppButtonVariant.primary:
        return const _ButtonColors(
          background: AppColors.primary,
          foreground: AppColors.onPrimary,
          borderColor: null,
        );
      case AppButtonVariant.secondary:
        return const _ButtonColors(
          background: AppColors.surface,
          foreground: AppColors.textPrimary,
          borderColor: AppColors.border,
        );
      case AppButtonVariant.ghost:
        return const _ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.primary,
          borderColor: null,
        );
      case AppButtonVariant.danger:
        return const _ButtonColors(
          background: AppColors.danger,
          foreground: AppColors.onPrimary,
          borderColor: null,
        );
    }
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    required this.borderColor,
  });

  final Color background;
  final Color foreground;
  final Color? borderColor;
}
