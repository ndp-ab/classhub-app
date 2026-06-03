import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/user_roles.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/widgets/app_card.dart';
import '../core/widgets/app_empty_state.dart';
import '../core/widgets/app_error_state.dart';
import '../core/widgets/app_loading.dart';
import '../providers/auth_provider.dart';
import '../services/classroom_service.dart';

class ClassroomSwitcherSheet extends StatefulWidget {
  const ClassroomSwitcherSheet({
    super.key,
    required this.currentClassroomId,
  });

  final int currentClassroomId;

  @override
  State<ClassroomSwitcherSheet> createState() => _ClassroomSwitcherSheetState();
}

class _ClassroomSwitcherSheetState extends State<ClassroomSwitcherSheet> {
  final ClassroomService _classroomService = ClassroomService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _classrooms = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final int? userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không tìm thấy thông tin người dùng.';
      });
      return;
    } 

    final result = await _classroomService.getMyClassrooms(userId);
    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];
      final classrooms = data is List
          ? data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _classrooms = classrooms;
        _loading = false;
      });
    } else {
      final message = result['message'];
      setState(() {
        _loading = false;
        _error = message is String && message.isNotEmpty
            ? message
            : 'Không thể tải danh sách lớp.';
      });
    }
  }

  int? _classroomId(Map<String, dynamic> classroom) {
    final id = classroom['id'];
    return id is num ? id.toInt() : null;
  }

  void _selectClassroom(Map<String, dynamic> classroom) {
    final int? classroomId = _classroomId(classroom);
    if (classroomId == null) return;

    if (classroomId == widget.currentClassroomId) {
      Navigator.pop(context);
      return;
    }

    Navigator.pop(context, classroom);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.cardPadding,
            AppSpacing.screenHorizontal,
            AppSpacing.largeSection,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.cardPadding),
              Text('Đổi lớp', style: AppTextStyles.title),
              const SizedBox(height: AppSpacing.tiny),
              Text(
                'Chọn lớp bạn muốn chuyển sang',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSpacing.cardPadding),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AppLoading(message: 'Đang tải danh sách lớp');
    }

    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _loadClassrooms);
    }

    if (_classrooms.isEmpty) {
      return const AppEmptyState(
        icon: Icons.school_outlined,
        title: 'Chưa có lớp học nào',
        message: 'Danh sách lớp bạn tham gia sẽ hiển thị ở đây.',
      );
    }

    return ListView.separated(
      itemCount: _classrooms.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.element),
      itemBuilder: (context, index) {
        final classroom = _classrooms[index];
        final int? classroomId = _classroomId(classroom);
        final bool selected = classroomId == widget.currentClassroomId;
        return _ClassroomOptionCard(
          classroom: classroom,
          selected: selected,
          onTap: () => _selectClassroom(classroom),
        );
      },
    );
  }
}

class _ClassroomOptionCard extends StatelessWidget {
  const _ClassroomOptionCard({
    required this.classroom,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> classroom;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String className = classroom['className']?.toString() ?? 'Lớp không tên';
    final String faculty = classroom['faculty']?.toString() ?? '';
    final String academicYear = classroom['academicYear']?.toString() ?? '';
    final String role = classroom['role']?.toString() ?? '';
    final bool isAdmin = UserRoles.isAdminLike(role);
    final String subtitle = <String>[
      if (faculty.trim().isNotEmpty) faculty.trim(),
      if (academicYear.trim().isNotEmpty) academicYear.trim(),
    ].join(' • ');

    return AppCard(
      onTap: onTap,
      borderColor: selected ? AppColors.primary : AppColors.border,
      backgroundColor: selected
          ? AppColors.primary.withValues(alpha: 0.04)
          : AppColors.surface,
      child: Row(
        children: <Widget>[
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
              color: isAdmin ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.element),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  className,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.tiny),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  selected ? 'Đang chọn' : (isAdmin ? 'Admin' : 'Member'),
                  style: AppTextStyles.small.copyWith(
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          else
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}
