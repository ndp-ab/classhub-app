import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title = 'Đã xảy ra lỗi',
    this.message,
    this.icon = Icons.error_outline,
    this.retryLabel = 'Thử lại',
    this.onRetry,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.largeSection),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 28, color: AppColors.danger),
            ),
            const SizedBox(height: AppSpacing.cardPadding),
            Text(
              title,
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppSpacing.small),
              Text(
                message!,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: AppSpacing.largeSection),
              AppButton(
                label: retryLabel,
                onPressed: onRetry,
                variant: AppButtonVariant.secondary,
                fullWidth: false,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
