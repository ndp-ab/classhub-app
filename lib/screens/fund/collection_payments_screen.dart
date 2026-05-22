import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/payment_status_badge.dart';
import '../../models/payment.dart';
import '../../providers/auth_provider.dart';
import '../../services/fund_service.dart';

class CollectionPaymentsScreen extends StatefulWidget {
  final int collectionId;
  final String collectionTitle;
  final bool isAdmin;

  const CollectionPaymentsScreen({
    super.key,
    required this.collectionId,
    required this.collectionTitle,
    required this.isAdmin,
  });

  @override
  State<CollectionPaymentsScreen> createState() =>
      _CollectionPaymentsScreenState();
}

class _CollectionPaymentsScreenState extends State<CollectionPaymentsScreen> {
  final _service = FundService();
  bool _loading = true;
  String? _error;
  List<Payment> _payments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'Chưa đăng nhập';
      });
      return;
    }
    final r = await _service.getCollectionPayments(widget.collectionId, userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success']) {
        _payments = (r['data'] as List).cast<Payment>();
      } else {
        _error = r['message'];
      }
    });
  }

  Future<void> _confirm(Payment p) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    // Confirm dialog — chặn admin lỡ tay (BE giờ idempotent nên không
    // sửa được sau khi xác nhận)
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã đóng?'),
        content: Text(
          'Xác nhận ${p.fullName ?? "sinh viên"} đã đóng khoản này?\n'
          'Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final r = await _service.confirmPayment(p.id, userId);
    if (!mounted) return;
    if (r['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã xác nhận thanh toán'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(r['message'] ?? 'Lỗi'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.collectionTitle)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading();
    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _load);
    }

    if (_payments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: AppSpacing.largeVertical),
            AppEmptyState(
              icon: Icons.assessment_outlined,
              title: 'Chưa có khoản đóng',
              message:
                  'Khi đợt thu phát sinh khoản đóng, danh sách sẽ hiện ở đây.',
            ),
          ],
        ),
      );
    }

    // GP1: 3 nhóm — PENDING lên đầu để admin ưu tiên xử lý
    final pending = _payments.where((p) => p.isPending).toList();
    final unpaid = _payments.where((p) => p.isUnpaid).toList();
    final confirmed = _payments.where((p) => p.isConfirmed).toList();

    final children = <Widget>[
      _SummaryCard(
        confirmedCount: confirmed.length,
        total: _payments.length,
        pendingCount: pending.length,
        unpaidCount: unpaid.length,
      ),
    ];
    _appendSection(children, PaymentStatus.pendingVerification, pending);
    _appendSection(children, PaymentStatus.unpaid, unpaid);
    _appendSection(children, PaymentStatus.confirmed, confirmed);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.cardPadding,
          AppSpacing.screenHorizontal,
          AppSpacing.largeSection,
        ),
        children: children,
      ),
    );
  }

  void _appendSection(
    List<Widget> children,
    PaymentStatus status,
    List<Payment> payments,
  ) {
    if (payments.isEmpty) return;
    children.add(const SizedBox(height: AppSpacing.cardPadding));
    children.add(_SectionHeader(status: status));
    for (int i = 0; i < payments.length; i++) {
      children.add(const SizedBox(height: AppSpacing.element));
      children.add(_PaymentTile(
        payment: payments[i],
        isAdmin: widget.isAdmin,
        onConfirm: () => _confirm(payments[i]),
      ));
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.confirmedCount,
    required this.total,
    required this.pendingCount,
    required this.unpaidCount,
  });

  final int confirmedCount;
  final int total;
  final int pendingCount;
  final int unpaidCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.surfaceMuted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.assessment_outlined,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.element),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đã xác nhận', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.tiny),
                Text('$confirmedCount / $total', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  'Chờ xác nhận: $pendingCount  •  Chưa CK: $unpaidCount',
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.tiny,
        top: AppSpacing.small,
        bottom: AppSpacing.tiny,
      ),
      child: Text(
        paymentStatusLabel(status),
        style: AppTextStyles.caption.copyWith(
          color: paymentStatusColor(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.payment,
    required this.isAdmin,
    required this.onConfirm,
  });

  final Payment payment;
  final bool isAdmin;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final Color color = paymentStatusColor(payment.status);
    final IconData icon = paymentStatusIcon(payment.status);
    final String displayName =
        payment.fullName ?? 'User #${payment.userId}';

    final String subtitle = switch (payment.status) {
      PaymentStatus.confirmed => payment.confirmedByName != null
          ? 'Đã xác nhận bởi ${payment.confirmedByName}'
          : 'Đã xác nhận',
      PaymentStatus.pendingVerification =>
        'Sinh viên đã báo CK — cần đối chiếu sao kê',
      PaymentStatus.unpaid => 'Chưa CK',
    };

    // Admin xác nhận được cho cả UNPAID (vd nộp tiền mặt) lẫn PENDING
    final bool canConfirm = isAdmin && !payment.isConfirmed;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: AppSpacing.element),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.tiny),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (canConfirm) ...[
            const SizedBox(width: AppSpacing.small),
            AppButton(
              label: 'Xác nhận',
              size: AppButtonSize.small,
              fullWidth: false,
              onPressed: onConfirm,
            ),
          ],
        ],
      ),
    );
  }
}
