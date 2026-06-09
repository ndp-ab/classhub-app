import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/app_empty_state.dart';
import '../core/widgets/app_error_state.dart';
import '../core/widgets/app_loading.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, this.classroomId, this.classroomName});

  final int? classroomId;
  final String? classroomName;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = NotificationService();

  List<AppNotification> _notifications = <AppNotification>[];
  bool _isLoading = true;
  bool _isMarkingAll = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _service.getNotifications(
        classroomId: widget.classroomId,
      );
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _cleanException(e);
      });
    }
  }

  Future<void> _refresh() async {
    if (_errorMessage != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    await _loadNotifications();
  }

  Future<void> _markAsRead(int index) async {
    final notification = _notifications[index];
    if (notification.isRead) return;

    try {
      await _service.markAsRead(notification.recipientId);
      if (!mounted) return;
      setState(() {
        _notifications[index] = notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      });
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Không thể đánh dấu thông báo đã đọc');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll || !_notifications.any((item) => !item.isRead)) return;

    setState(() => _isMarkingAll = true);
    try {
      await _service.markAllAsRead(classroomId: widget.classroomId);
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _notifications = _notifications
            .map((item) => item.copyWith(isRead: true, readAt: now))
            .toList();
        _isMarkingAll = false;
      });
      _showSnackBar('Đã đánh dấu tất cả là đã đọc');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isMarkingAll = false);
      _showSnackBar('Không thể đánh dấu tất cả đã đọc');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanException(Object error) {
    return error.toString().replaceAll('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((item) => !item.isRead);
    final classroomName = widget.classroomName?.trim();
    final title = widget.classroomId == null
        ? 'Thông báo'
        : classroomName != null && classroomName.isNotEmpty
        ? 'Thông báo $classroomName'
        : 'Thông báo lớp';

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.largeSection,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: AppSpacing.small),
              Row(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.textPrimary,
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: hasUnread && !_isMarkingAll
                        ? _markAllAsRead
                        : null,
                    child: Text(
                      'Đánh dấu tất cả đã đọc',
                      style: AppTextStyles.caption.copyWith(
                        color: hasUnread
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.largeSection),
              Text(title, style: AppTextStyles.headingLarge),
              const SizedBox(height: AppSpacing.sectionPadding),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const AppLoading(message: 'Đang tải thông báo');
    }

    if (_errorMessage != null) {
      return AppErrorState(
        message: _errorMessage,
        onRetry: () {
          setState(() {
            _isLoading = true;
            _errorMessage = null;
          });
          _loadNotifications();
        },
      );
    }

    if (_notifications.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const <Widget>[
            SizedBox(height: 96),
            AppEmptyState(
              icon: Icons.notifications_none_outlined,
              title: 'Chưa có thông báo',
              message:
                  'Các cập nhật về quỹ lớp, sự kiện và điểm danh sẽ xuất hiện tại đây.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.largeSection),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
        itemBuilder: (context, index) {
          return _NotificationTile(
            notification: _notifications[index],
            onTap: () => _markAsRead(index),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    notification.title,
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.tiny),
                  Text(
                    notification.message,
                    style: AppTextStyles.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    formatDateTime(notification.createdAt),
                    style: AppTextStyles.small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isUnread) ...<Widget>[
              const SizedBox(width: AppSpacing.element),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: AppSpacing.small),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
