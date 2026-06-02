import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/user_roles.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_empty_state.dart';
import '../core/widgets/app_section_title.dart';
import 'events/create_event_screen.dart';
import 'events/events_tab.dart';
import 'fund/create_collection_screen.dart';
import 'fund/expenses_screen.dart';
import 'fund/fund_tab.dart';

class ClassroomDetailScreen extends StatefulWidget {
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

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen> {
  int _selectedIndex = 0;
  int _fundModuleVersion = 0;
  int _eventModuleVersion = 0;

  bool get _isAdmin => UserRoles.isAdminLike(widget.role);

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _openCreateCollection() async {
    final bool? created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCollectionScreen(classroomId: widget.classroomId),
      ),
    );
    if (!mounted) return;
    if (created == true) {
      setState(() {
        _selectedIndex = 1;
        _fundModuleVersion++;
      });
    }
  }

  Future<void> _openCreateEvent() async {
    final bool? created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(classroomId: widget.classroomId),
      ),
    );
    if (!mounted) return;
    if (created == true) {
      setState(() {
        _selectedIndex = 2;
        _eventModuleVersion++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.cardPadding,
                AppSpacing.screenHorizontal,
                AppSpacing.small,
              ),
              child: Column(
                children: [
                  _DashboardHeader(
                    classroomName: widget.classroomName,
                    onSwitchClassroom: () => _showComingSoon(
                      'Chức năng đổi lớp sẽ được bổ sung sau',
                    ),
                    onNotifications: () =>
                        _showComingSoon('Thông báo sẽ được bổ sung sau'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _OverviewTab(
                    classroomName: widget.classroomName,
                    inviteCode: widget.inviteCode,
                    faculty: widget.faculty,
                    academicYear: widget.academicYear,
                    isAdmin: _isAdmin,
                    onOpenFund: () => _selectTab(1),
                    onOpenEvents: () => _selectTab(2),
                    onCreateCollection: _isAdmin ? _openCreateCollection : null,
                    onCreateEvent: _isAdmin ? _openCreateEvent : null,
                  ),
                  _FundWorkspaceTab(
                    key: ValueKey<int>(_fundModuleVersion),
                    classroomId: widget.classroomId,
                    isAdmin: _isAdmin,
                  ),
                  EventsTab(
                    key: ValueKey<int>(_eventModuleVersion),
                    classroomId: widget.classroomId,
                    isAdmin: _isAdmin,
                  ),
                  const _MembersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: AppColors.surface,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Quỹ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event_rounded),
            label: 'Sự kiện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups_rounded),
            label: 'Thành viên',
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.classroomName,
    required this.onSwitchClassroom,
    required this.onNotifications,
  });

  final String classroomName;
  final VoidCallback onSwitchClassroom;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            child: InkWell(
              onTap: onSwitchClassroom,
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.cardPadding,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        classroomName,
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.tiny),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.element),
        _HeaderIconButton(
          icon: Icons.notifications_none_outlined,
          tooltip: 'Thông báo',
          onPressed: onNotifications,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.textPrimary, size: 22),
          ),
        ),
      ),
    );
  }
}

class _ClassroomIdentityCard extends StatelessWidget {
  const _ClassroomIdentityCard({
    required this.classroomName,
    this.inviteCode,
    this.faculty,
    this.academicYear,
  });

  final String classroomName;
  final String? inviteCode;
  final String? faculty;
  final String? academicYear;

  @override
  Widget build(BuildContext context) {
    final String subtitle = <String>[
      if (faculty != null && faculty!.trim().isNotEmpty) faculty!.trim(),
      if (academicYear != null && academicYear!.trim().isNotEmpty)
        academicYear!.trim(),
    ].join(' • ');

    return AppCard(
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            classroomName,
            style: AppTextStyles.heading.copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.tiny),
            Text(
              subtitle,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.element),
          _InviteCodeRow(code: inviteCode),
        ],
      ),
    );
  }
}

class _InviteCodeRow extends StatelessWidget {
  const _InviteCodeRow({this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    final String displayCode = code != null && code!.trim().isNotEmpty
        ? code!.trim()
        : '--';

    return Row(
      children: [
        Expanded(
          child: Text(
            'Mã mời: $displayCode',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        AppButton(
          label: 'Copy',
          icon: Icons.copy_outlined,
          size: AppButtonSize.small,
          variant: AppButtonVariant.secondary,
          fullWidth: false,
          onPressed: code == null || code!.trim().isEmpty
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: code!.trim()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã copy mã mời')),
                  );
                },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.element),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: AppSpacing.small),
          Text(
            value,
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.tiny),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            helper,
            style: AppTextStyles.small,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.classroomName,
    this.inviteCode,
    this.faculty,
    this.academicYear,
    required this.isAdmin,
    required this.onOpenFund,
    required this.onOpenEvents,
    this.onCreateCollection,
    this.onCreateEvent,
  });

  final String classroomName;
  final String? inviteCode;
  final String? faculty;
  final String? academicYear;
  final bool isAdmin;
  final VoidCallback onOpenFund;
  final VoidCallback onOpenEvents;
  final VoidCallback? onCreateCollection;
  final VoidCallback? onCreateEvent;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.small,
        AppSpacing.screenHorizontal,
        AppSpacing.largeSection,
      ),
      children: [
        _ClassroomIdentityCard(
          classroomName: classroomName,
          inviteCode: inviteCode,
          faculty: faculty,
          academicYear: academicYear,
        ),
        const SizedBox(height: AppSpacing.element),
        const Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Thành viên',
                value: '--',
                helper: 'Đang cập nhật',
                icon: Icons.groups_outlined,
              ),
            ),
            SizedBox(width: AppSpacing.small),
            Expanded(
              child: _StatCard(
                label: 'Quỹ',
                value: '--',
                helper: 'Đang cập nhật',
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            SizedBox(width: AppSpacing.small),
            Expanded(
              child: _StatCard(
                label: 'Sự kiện',
                value: '--',
                helper: 'Đang cập nhật',
                icon: Icons.event_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.cardPadding),
        const AppSectionTitle(
          title: 'Tổng quan lớp',
          subtitle: 'Không gian làm việc của lớp hiện tại',
        ),
        _OverviewCard(
          icon: Icons.bolt_outlined,
          title: 'Thông tin nhanh',
          message:
              'Các chỉ số chi tiết sẽ hiển thị khi có API thống kê cho lớp.',
        ),
        if (isAdmin && onCreateCollection != null && onCreateEvent != null) ...[
          const SizedBox(height: AppSpacing.element),
          const AppSectionTitle(title: 'Thao tác nhanh'),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Tạo khoản thu',
                  icon: Icons.add,
                  onPressed: onCreateCollection,
                ),
              ),
              const SizedBox(width: AppSpacing.element),
              Expanded(
                child: AppButton(
                  label: 'Tạo sự kiện',
                  icon: Icons.event_available_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: onCreateEvent,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.element),
        _OverviewCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Quỹ lớp',
          message:
              'Xem khoản thu, khoản chi, QR thanh toán và xác nhận đóng quỹ.',
          actionLabel: isAdmin ? 'Quản lý quỹ' : 'Xem quỹ',
          onAction: onOpenFund,
        ),
        const SizedBox(height: AppSpacing.element),
        _OverviewCard(
          icon: Icons.event_available_outlined,
          title: 'Sự kiện sắp tới',
          message:
              'Theo dõi sự kiện, đăng ký tham gia và danh sách người tham gia.',
          actionLabel: isAdmin ? 'Quản lý sự kiện' : 'Xem sự kiện',
          onAction: onOpenEvents,
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.element),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.tiny),
                    Text(message, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.cardPadding),
            AppButton(
              label: actionLabel!,
              trailingIcon: Icons.arrow_forward_rounded,
              variant: AppButtonVariant.secondary,
              fullWidth: false,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class _FundWorkspaceTab extends StatefulWidget {
  const _FundWorkspaceTab({
    super.key,
    required this.classroomId,
    required this.isAdmin,
  });

  final int classroomId;
  final bool isAdmin;

  @override
  State<_FundWorkspaceTab> createState() => _FundWorkspaceTabState();
}

class _FundWorkspaceTabState extends State<_FundWorkspaceTab> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.small,
            AppSpacing.screenHorizontal,
            AppSpacing.small,
          ),
          child: Row(
            children: [
              Expanded(
                child: _SegmentButton(
                  label: 'Khoản thu',
                  selected: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: _SegmentButton(
                  label: 'Khoản chi',
                  selected: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedIndex == 0
              ? FundTab(
                  classroomId: widget.classroomId,
                  isAdmin: widget.isAdmin,
                )
              : ExpensesScreen(
                  classroomId: widget.classroomId,
                  isAdmin: widget.isAdmin,
                ),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = selected ? AppColors.primary : AppColors.surface;
    final Color foreground = selected
        ? AppColors.onPrimary
        : AppColors.textPrimary;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Text(
            label,
            style: AppTextStyles.button.copyWith(
              color: foreground,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab();

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.groups_outlined,
      title: 'Danh sách thành viên',
      message:
          'Tính năng thành viên sẽ được bổ sung sau khi có API /classrooms/{id}/members',
    );
  }
}
