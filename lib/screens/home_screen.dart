import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/user_roles.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_empty_state.dart';
import '../core/widgets/app_error_state.dart';
import '../core/widgets/app_loading.dart';
import '../core/widgets/app_section_title.dart';
import '../providers/auth_provider.dart';
import '../services/classroom_service.dart';
import 'login_screen.dart';
import 'create_classroom_screen.dart';
import 'join_classroom_screen.dart';
import 'classroom_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _classroomService = ClassroomService();
  List<dynamic> _classrooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId == null) return;

    final result = await _classroomService.getMyClassrooms(userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _classrooms = result['data'];
          _errorMessage = null;
        } else {
          final message = result['message'];
          _errorMessage = message is String && message.isNotEmpty
              ? message
              : 'Không thể tải danh sách lớp.';
        }
      });
    }
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (result == true) {
      setState(() => _isLoading = true);
      _loadClassrooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final String fullName =
        auth.fullName?.trim().isNotEmpty == true ? auth.fullName!.trim() : 'bạn';

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.largeVertical,
              AppSpacing.screenHorizontal,
              AppSpacing.cardPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ClassHub',
                        style: AppTextStyles.headingLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _HeaderIconButton(
                      icon: Icons.notifications_none_outlined,
                      tooltip: 'Thông báo',
                      onPressed: () {},
                    ),
                    const SizedBox(width: AppSpacing.small),
                    _HeaderIconButton(
                      icon: Icons.logout_outlined,
                      tooltip: 'Đăng xuất',
                      onPressed: () async {
                        await auth.logout();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.largeSection),
                Text(
                  'Xin chào, $fullName',
                  style: AppTextStyles.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  'Chọn lớp để tiếp tục quản lý',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.largeSection),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Tạo lớp',
                        icon: Icons.add,
                        onPressed: () =>
                            _navigateAndRefresh(const CreateClassroomScreen()),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.element),
                    Expanded(
                      child: AppButton(
                        label: 'Nhập mã lớp',
                        icon: Icons.login_rounded,
                        variant: AppButtonVariant.secondary,
                        onPressed: () =>
                            _navigateAndRefresh(const JoinClassroomScreen()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoading();
    }

    if (_errorMessage != null) {
      return AppErrorState(
        message: _errorMessage,
        onRetry: () {
          setState(() => _isLoading = true);
          _loadClassrooms();
        },
      );
    }

    if (_classrooms.isEmpty) {
      return AppEmptyState(
        icon: Icons.school_outlined,
        title: 'Bạn chưa tham gia lớp nào',
        message: 'Tạo lớp mới hoặc nhập mã mời để bắt đầu',
        actionLabel: 'Tạo lớp',
        onAction: () => _navigateAndRefresh(const CreateClassroomScreen()),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.small,
        AppSpacing.screenHorizontal,
        AppSpacing.largeSection,
      ),
      itemCount: _classrooms.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const AppSectionTitle(
            title: 'Lớp học của bạn',
            subtitle: 'Danh sách lớp bạn đang tham gia',
            padding: EdgeInsets.only(bottom: AppSpacing.element),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.element),
          child: _ClassroomTile(classroom: _classrooms[index - 1]),
        );
      },
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

class _ClassroomTile extends StatelessWidget {
  const _ClassroomTile({required this.classroom});

  final dynamic classroom;

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = UserRoles.isAdminLike(classroom['role'] as String?);
    final String faculty = (classroom['faculty'] as String?) ?? '';
    final String year = (classroom['academicYear'] as String?) ?? '';
    final String subtitleText = <String>[faculty, year]
        .where((String s) => s.isNotEmpty)
        .join(' • ');
    final String inviteCode = (classroom['inviteCode'] as String?) ?? '';

    return AppCard(
      backgroundColor: AppColors.surface,
      borderColor: AppColors.border,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClassroomDetailScreen(
              classroomId: (classroom['id'] as num).toInt(),
              classroomName: classroom['className'] ?? '',
              inviteCode: classroom['inviteCode'],
              role: classroom['role'],
              faculty: classroom['faculty'],
              academicYear: classroom['academicYear'],
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isAdmin
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              isAdmin ? Icons.star_rounded : Icons.person_outline,
              size: 22,
              color: isAdmin ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.element),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        classroom['className'] ?? '',
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    _RoleChip(isAdmin: isAdmin),
                  ],
                ),
                if (subtitleText.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    subtitleText,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (inviteCode.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.element),
                  Text(
                    'Mã lớp: $inviteCode',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.element),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final String label = isAdmin ? 'Admin' : 'Member';
    final Color background = isAdmin
        ? AppColors.primary.withValues(alpha: 0.1)
        : AppColors.surfaceMuted;
    final Color foreground =
        isAdmin ? AppColors.primary : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.element,
        vertical: AppSpacing.tiny,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: AppTextStyles.small.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
