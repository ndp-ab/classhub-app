import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading.dart';
import '../../models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../services/fund_service.dart';
import 'create_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final int classroomId;
  final bool isAdmin;

  const ExpensesScreen({
    super.key,
    required this.classroomId,
    required this.isAdmin,
  });

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _service = FundService();
  bool _loading = true;
  String? _error;
  List<Expense> _expenses = [];

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
    final r = await _service.getExpenses(widget.classroomId, userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success']) {
        _expenses = (r['data'] as List).cast<Expense>();
      } else {
        _error = r['message'];
      }
    });
  }

  Future<void> _openCreateExpense() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateExpenseScreen(classroomId: widget.classroomId),
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _openCreateExpense,
              icon: const Icon(Icons.add),
              label: const Text('Thêm khoản chi'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading();

    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _load);
    }

    final double total = _expenses.fold<double>(0, (s, e) => s + e.amount);

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
          _TotalCard(total: total),
          const SizedBox(height: AppSpacing.cardPadding),
          if (_expenses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.largeSection),
              child: AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Chưa có khoản chi nào',
                message: 'Khi ban cán sự thêm khoản chi, chúng sẽ hiện ở đây.',
              ),
            )
          else
            ..._buildExpenseList(),
        ],
      ),
    );
  }

  List<Widget> _buildExpenseList() {
    final List<Widget> tiles = [];
    for (int i = 0; i < _expenses.length; i++) {
      if (i > 0) {
        tiles.add(const SizedBox(height: AppSpacing.element));
      }
      tiles.add(_ExpenseTile(expense: _expenses[i]));
    }
    return tiles;
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});

  final double total;

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
              Icons.account_balance_wallet_outlined,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.element),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tổng chi', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.tiny),
                Text(formatVnd(total), style: AppTextStyles.title),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final String? reason = expense.reason;
    final String? author = expense.createdByName;
    final bool hasReason = reason != null && reason.isNotEmpty;
    final bool hasAuthor = author != null && author.isNotEmpty;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.south_west_rounded,
              size: 22,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: AppSpacing.element),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  formatVnd(expense.amount),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasReason) ...[
                  const SizedBox(height: AppSpacing.tiny),
                  Text('Lý do: $reason', style: AppTextStyles.caption),
                ],
                if (hasAuthor) ...[
                  const SizedBox(height: AppSpacing.tiny),
                  Text('Bởi: $author', style: AppTextStyles.small),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
