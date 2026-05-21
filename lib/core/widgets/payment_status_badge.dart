import 'package:flutter/material.dart';
import '../../models/payment.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Semantic mapping for [PaymentStatus]:
/// - unpaid               → warning  (cam)
/// - pendingVerification  → primary  (tím — neutral đang chờ)
/// - confirmed            → success  (xanh lá)
///
/// Use [PaymentStatusBadge] for an inline chip; use [paymentStatusColor]
/// and [paymentStatusIcon] when you need to render the same status as a
/// custom widget (e.g. an avatar with the status icon).
class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.dense = false,
  });

  final PaymentStatus status;

  /// When true, renders a tighter chip suitable for list rows.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color color = paymentStatusColor(status);
    final String label = paymentStatusLabel(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.small : AppSpacing.element,
        vertical: AppSpacing.tiny,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(paymentStatusIcon(status), size: dense ? 12 : 14, color: color),
          const SizedBox(width: AppSpacing.tiny),
          Text(
            label,
            style: (dense ? AppTextStyles.small : AppTextStyles.caption)
                .copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

Color paymentStatusColor(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.confirmed:
      return AppColors.success;
    case PaymentStatus.pendingVerification:
      return AppColors.primary;
    case PaymentStatus.unpaid:
      return AppColors.warning;
  }
}

IconData paymentStatusIcon(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.confirmed:
      return Icons.check_circle_outline;
    case PaymentStatus.pendingVerification:
      return Icons.hourglass_top;
    case PaymentStatus.unpaid:
      return Icons.error_outline;
  }
}

String paymentStatusLabel(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.confirmed:
      return 'Đã xác nhận';
    case PaymentStatus.pendingVerification:
      return 'Chờ xác nhận';
    case PaymentStatus.unpaid:
      return 'Chưa CK';
  }
}
