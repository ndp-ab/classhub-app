import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_button.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_empty_state.dart';
import '../core/widgets/app_loading.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClassHub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              AppSpacing.cardPadding,
              AppSpacing.screenHorizontal,
              AppSpacing.small,
            ),
            child: Row(
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
                    label: 'Tham gia',
                    icon: Icons.group_add_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        _navigateAndRefresh(const JoinClassroomScreen()),
                  ),
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

    if (_classrooms.isEmpty) {
      return AppEmptyState(
        icon: Icons.school_outlined,
        title: 'Chưa có lớp học nào',
        message:
            'Tạo một lớp mới hoặc tham gia bằng mã mời để bắt đầu sử dụng ClassHub.',
        actionLabel: 'Tạo lớp',
        onAction: () => _navigateAndRefresh(const CreateClassroomScreen()),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        AppSpacing.small,
        AppSpacing.screenHorizontal,
        AppSpacing.largeSection,
      ),
      itemCount: _classrooms.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.element),
      itemBuilder: (context, index) {
        return _ClassroomTile(classroom: _classrooms[index]);
      },
    );
  }
}

class _ClassroomTile extends StatelessWidget {
  const _ClassroomTile({required this.classroom});

  final dynamic classroom;

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = classroom['role'] == 'ADMIN';
    final String faculty = (classroom['faculty'] as String?) ?? '';
    final String year = (classroom['academicYear'] as String?) ?? '';
    final String subtitleText = <String>[faculty, year]
        .where((String s) => s.isNotEmpty)
        .join(' • ');

    return AppCard(
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
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
                Text(
                  classroom['className'] ?? '',
                  style: AppTextStyles.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitleText.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.tiny),
                  Text(
                    subtitleText,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          _RoleChip(isAdmin: isAdmin, role: classroom['role'] ?? ''),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.isAdmin, required this.role});

  final bool isAdmin;
  final String role;

  @override
  Widget build(BuildContext context) {
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
        role,
        style: AppTextStyles.small.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
