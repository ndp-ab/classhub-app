import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_card.dart';
import 'events/events_tab.dart';
import 'fund/fund_tab.dart';
import 'fund/expenses_screen.dart';

class ClassroomDetailScreen extends StatelessWidget {
  final int classroomId;
  final String classroomName;
  final String? inviteCode;
  final String? role;
  final String? faculty;
  final String? academicYear;

  const ClassroomDetailScreen({
    super.key,
    required this.classroomId,
    required this.classroomName,
    this.inviteCode,
    this.role,
    this.faculty,
    this.academicYear,
  });

  bool get _isAdmin => role == 'ADMIN' || role == 'OWNER';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(classroomName),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: 'Tổng quan'),
              Tab(icon: Icon(Icons.payments_outlined), text: 'Khoản thu'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Khoản chi'),
              Tab(icon: Icon(Icons.event_outlined), text: 'Sự kiện'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(
              classroomName: classroomName,
              inviteCode: inviteCode,
              role: role,
              faculty: faculty,
              academicYear: academicYear,
            ),
            FundTab(classroomId: classroomId, isAdmin: _isAdmin),
            ExpensesScreen(classroomId: classroomId, isAdmin: _isAdmin),
            EventsTab(classroomId: classroomId, isAdmin: _isAdmin),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String classroomName;
  final String? inviteCode;
  final String? role;
  final String? faculty;
  final String? academicYear;

  const _OverviewTab({
    required this.classroomName,
    this.inviteCode,
    this.role,
    this.faculty,
    this.academicYear,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = <Widget>[
      _InfoCard(
        icon: Icons.class_outlined,
        label: 'Tên lớp',
        value: classroomName,
      ),
      if (faculty != null && faculty!.isNotEmpty)
        _InfoCard(
          icon: Icons.business_outlined,
          label: 'Khoa',
          value: faculty!,
        ),
      if (academicYear != null && academicYear!.isNotEmpty)
        _InfoCard(
          icon: Icons.calendar_today_outlined,
          label: 'Khóa',
          value: academicYear!,
        ),
      if (role != null)
        _InfoCard(
          icon: role == 'ADMIN' ? Icons.star_rounded : Icons.person_outline,
          label: 'Vai trò',
          value: role!,
        ),
      if (inviteCode != null && inviteCode!.isNotEmpty)
        _InviteCodeCard(code: inviteCode!),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.cardPadding,
      ),
      itemCount: cards.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.element),
      itemBuilder: (context, index) => cards[index],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.element),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  value,
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.primary.withValues(alpha: 0.05),
      borderColor: AppColors.primary.withValues(alpha: 0.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.key_outlined,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.element),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mã tham gia', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  code,
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            color: AppColors.primary,
            tooltip: 'Sao chép',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã copy mã tham gia')),
              );
            },
          ),
        ],
      ),
    );
  }
}
