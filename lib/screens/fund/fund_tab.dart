import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/app_section_title.dart';
import '../../core/widgets/payment_status_badge.dart';
import '../../models/classroom_bank_account.dart';
import '../../models/expense.dart';
import '../../models/fund_collection.dart';
import '../../models/payment.dart';
import '../../providers/auth_provider.dart';
import '../../services/classroom_service.dart';
import '../../services/fund_service.dart';
import '../classroom_bank_account_screen.dart';
import 'collection_payments_screen.dart';
import 'create_collection_screen.dart';
import 'payment_qr_screen.dart';

class FundTab extends StatefulWidget {
  final int classroomId;
  final bool isAdmin;

  const FundTab({super.key, required this.classroomId, required this.isAdmin});

  @override
  State<FundTab> createState() => _FundTabState();
}

class _FundTabState extends State<FundTab> {
  final _service = FundService();
  final _classroomService = ClassroomService();
  bool _loading = true;
  String? _error;
  String? _bankAccountError;
  ClassroomBankAccount? _bankAccount;
  List<FundCollection> _collections = [];
  List<Payment> _myPayments = [];
  List<Expense> _expenses = [];
  bool _expensesLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _expensesLoaded = false;
    });
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'Chưa đăng nhập';
      });
      return;
    }

    final col = await _service.getCollections(widget.classroomId, userId);
    final my = await _service.getMyPayments(widget.classroomId, userId);
    final bank = await _classroomService.getBankAccount(widget.classroomId);
    final expenseResult = await _service.getExpenses(
      widget.classroomId,
      userId,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (col['success']) {
        _collections = (col['data'] as List).cast<FundCollection>();
      } else {
        _error = col['message'];
      }
      if (my['success']) {
        _myPayments = (my['data'] as List).cast<Payment>();
      }
      if (expenseResult['success']) {
        _expenses = (expenseResult['data'] as List).cast<Expense>();
        _expensesLoaded = true;
      } else {
        _expenses = [];
        _expensesLoaded = false;
      }
      if (bank['success']) {
        _bankAccount = bank['data'] as ClassroomBankAccount;
        _bankAccountError = null;
      } else if (bank['notConfigured'] == true) {
        _bankAccount = null;
        _bankAccountError = null;
      } else {
        _bankAccount = null;
        _bankAccountError = bank['message']?.toString();
      }
    });
  }

  String _fmtAmount(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()} đ';
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _displayText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'Chưa có dữ liệu' : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background, body: _buildBody());
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading(message: 'Đang tải quỹ lớp');
    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _load);
    }

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
        children: [
          _buildOverviewCard(),
          const SizedBox(height: AppSpacing.cardPadding),
          _buildBankAccountCard(),
          const SizedBox(height: AppSpacing.largeSection),
          if (widget.isAdmin) _buildCollectionsSection() else _buildMySection(),
        ],
      ),
    );
  }

  Future<void> _openBankAccountScreen() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ClassroomBankAccountScreen(classroomId: widget.classroomId),
      ),
    );
    if (updated == true && mounted) _load();
  }

  Future<void> _openCreateCollectionScreen() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCollectionScreen(classroomId: widget.classroomId),
      ),
    );
    if (ok == true && mounted) _load();
  }

  Future<void> _openCollectionPayments(FundCollection collection) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionPaymentsScreen(
          collectionId: collection.id,
          collectionTitle: collection.title,
          isAdmin: widget.isAdmin,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _openPaymentQr(Payment payment) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentQrScreen(paymentId: payment.id)),
    );
    if (mounted) _load();
  }

  Widget _buildOverviewCard() {
    final totalCollected = _totalCollected();
    final totalExpense = _expensesLoaded
        ? _expenses.fold<double>(0, (total, expense) => total + expense.amount)
        : null;
    final balance = totalCollected != null && totalExpense != null
        ? totalCollected - totalExpense
        : null;

    return AppCard(
      backgroundColor: AppColors.primary,
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: AppColors.onPrimary.withValues(alpha: 0.72),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  'Số dư quỹ lớp',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            balance == null ? 'Chưa có dữ liệu' : _fmtAmount(balance),
            style: AppTextStyles.heading.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.cardPadding),
          Row(
            children: [
              Expanded(
                child: _BalanceSummaryItem(
                  label: 'Đã thu',
                  value: totalCollected == null
                      ? 'Chưa có dữ liệu'
                      : _fmtAmount(totalCollected),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: _BalanceSummaryItem(
                  label: 'Đã chi',
                  value: totalExpense == null
                      ? 'Chưa có dữ liệu'
                      : _fmtAmount(totalExpense),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double? _totalCollected() {
    if (widget.isAdmin) {
      return _collections.fold<double>(
        0,
        (total, collection) => total + collection.amount * collection.paidCount,
      );
    }

    final confirmedPayments = _myPayments.where(
      (payment) => payment.isConfirmed,
    );
    if (confirmedPayments.any((payment) => payment.amount == null)) {
      return null;
    }

    return confirmedPayments.fold<double>(
      0,
      (total, payment) => total + payment.amount!,
    );
  }

  Widget _buildBankAccountCard() {
    final account = _bankAccount;
    final hasAccount = account != null;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.element),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Tài khoản nhận tiền',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.isAdmin) ...[
                const SizedBox(width: AppSpacing.small),
                AppButton(
                  label: hasAccount ? 'Cập nhật' : 'Thiết lập',
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.ghost,
                  fullWidth: false,
                  onPressed: _openBankAccountScreen,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.tiny),
          if (_bankAccountError != null)
            Text(
              _bankAccountError!,
              style: AppTextStyles.small.copyWith(color: AppColors.danger),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          else if (account == null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isAdmin
                      ? 'Chưa có tài khoản nhận tiền'
                      : 'Lớp chưa có tài khoản nhận tiền.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.isAdmin) ...[
                  const SizedBox(height: AppSpacing.tiny),
                  Text(
                    'Thiết lập để sinh viên chuyển khoản.',
                    style: AppTextStyles.small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_displayText(account.displayBankName)} · ${_displayText(account.accountNo)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  _displayText(account.accountName),
                  style: AppTextStyles.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMySection() {
    final unpaid = _myPayments.where((p) => p.isUnpaid).toList();
    final pending = _myPayments.where((p) => p.isPending).toList();
    final confirmed = _myPayments.where((p) => p.isConfirmed).toList();
    final orderedPayments = <Payment>[...unpaid, ...pending, ...confirmed];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionTitle(
          title: 'Khoản của tôi',
          subtitle: _myPayments.isEmpty
              ? null
              : '${confirmed.length} đã xác nhận • ${pending.length} chờ • ${unpaid.length} chưa CK',
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.element),
        if (_myPayments.isEmpty)
          const AppEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Bạn chưa có khoản nào',
            message:
                'Các khoản cần đóng sẽ hiển thị tại đây khi lớp tạo đợt thu.',
          )
        else
          ...orderedPayments.map(
            (payment) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.element),
              child: _buildMyPaymentCard(payment),
            ),
          ),
      ],
    );
  }

  Widget _buildMyPaymentCard(Payment payment) {
    final canOpenQr = payment.isUnpaid || payment.isPending;
    final title = payment.collectionTitle ?? 'Khoản #${payment.id}';
    final amount = payment.amount == null
        ? 'Chưa có dữ liệu'
        : _fmtAmount(payment.amount!);
    final deadline = payment.deadline == null
        ? 'Chưa có hạn đóng'
        : 'Hạn ${_fmtDate(payment.deadline)}';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.element),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Flexible(
                flex: 2,
                child: Text(
                  amount,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.tiny,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      deadline,
                      style: AppTextStyles.small,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    PaymentStatusBadge(status: payment.status, dense: true),
                  ],
                ),
              ),
              if (canOpenQr) ...[
                const SizedBox(width: AppSpacing.small),
                TextButton(
                  onPressed: () => _openPaymentQr(payment),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.small,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Xem QR',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (payment.isConfirmed && payment.confirmedByName != null) ...[
            const SizedBox(height: AppSpacing.tiny),
            Text(
              'Xác nhận bởi ${payment.confirmedByName}',
              style: AppTextStyles.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollectionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionTitle(
          title: 'Các đợt thu',
          subtitle: _collections.isEmpty
              ? null
              : '${_collections.length} đợt thu',
          padding: EdgeInsets.zero,
          trailing: AppButton(
            label: 'Tạo khoản thu',
            icon: Icons.add,
            size: AppButtonSize.small,
            fullWidth: false,
            onPressed: _openCreateCollectionScreen,
          ),
        ),
        const SizedBox(height: AppSpacing.element),
        if (_collections.isEmpty)
          AppEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có khoản thu nào',
            message: 'Tạo khoản thu đầu tiên để bắt đầu theo dõi đóng quỹ.',
            actionLabel: 'Tạo khoản thu',
            onAction: _openCreateCollectionScreen,
          )
        else
          ..._collections.map(
            (collection) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.element),
              child: _buildCollectionCard(collection),
            ),
          ),
      ],
    );
  }

  Widget _buildCollectionCard(FundCollection collection) {
    final hasTotalMembers = collection.totalMembers > 0;
    final amount = '${_fmtAmount(collection.amount)}/người';
    final deadline = collection.deadline == null
        ? 'Chưa có hạn đóng'
        : 'Hạn ${_fmtDate(collection.deadline)}';
    final paidSummary = hasTotalMembers
        ? 'Đã đóng ${collection.paidCount}/${collection.totalMembers}'
        : 'Đã đóng ${collection.paidCount}';

    return AppCard(
      onTap: () => _openCollectionPayments(collection),
      padding: const EdgeInsets.all(AppSpacing.element),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  collection.title,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Flexible(
                flex: 2,
                child: Text(
                  amount,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '$deadline · $paidSummary',
                  style: AppTextStyles.small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              TextButton(
                onPressed: () => _openCollectionPayments(collection),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.small,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Xem danh sách',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceSummaryItem extends StatelessWidget {
  const _BalanceSummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.element,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: AppColors.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.onPrimary.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.74),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.tiny),
          Text(
            value,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
