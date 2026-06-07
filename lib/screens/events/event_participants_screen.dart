import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_empty_state.dart';
import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_service.dart';

class EventParticipantsScreen extends StatefulWidget {
  final int eventId;
  final String eventTitle;
  final bool isAdmin;

  const EventParticipantsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.isAdmin,
  });

  @override
  State<EventParticipantsScreen> createState() =>
      _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends State<EventParticipantsScreen> {
  final _service = EventService();
  bool _loading = true;
  String? _error;
  List<EventParticipant> _participants = [];
  // Fix 7: chống double-tap approve/reject
  bool _actionInProgress = false;

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
    final r = await _service.getParticipants(widget.eventId, userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success']) {
        _participants = (r['data'] as List).cast<EventParticipant>();
      } else {
        _error = r['message'];
      }
    });
  }

  Future<void> _checkIn(EventParticipant p) async {
    final adminId = context.read<AuthProvider>().userId;
    if (adminId == null || p.userId == null) return;

    // Confirm dialog — BE chặn check-in 2 lần, nên cần chắc chắn trước khi gọi
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Check-in?'),
        content: Text(
          'Xác nhận ${p.fullName ?? "sinh viên"} có mặt tại sự kiện?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Check-in'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final r = await _service.checkIn(widget.eventId, p.userId!, adminId);
    if (!mounted) return;
    if (r['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã check-in'),
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

  // Fix 4: thêm mounted guard để an toàn khi gọi sau async
  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _showCheckinImage(EventParticipant p) async {
    final imageUrl = _service.resolveFileUrl(p.checkinImageUrl);
    if (imageUrl.isEmpty) {
      _showSnack('Không có ảnh minh chứng', AppColors.danger);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ảnh minh chứng'),
        content: SizedBox(
          width: double.maxFinite,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                height: 180,
                child: Center(child: Text('Không tải được ảnh minh chứng')),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveCheckinSubmission(EventParticipant p) async {
    final submissionId = p.checkinSubmissionId;
    if (submissionId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duyệt ảnh điểm danh?'),
        content: const Text('Sinh viên này sẽ được đánh dấu là đã check-in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    // Fix 7: chống double-tap
    if (_actionInProgress) return;

    setState(() => _actionInProgress = true);
    final r = await _service.approveCheckinSubmission(submissionId);
    if (!mounted) return;
    setState(() => _actionInProgress = false);
    if (r['success']) {
      _showSnack('Đã duyệt ảnh và check-in sinh viên', AppColors.success);
      _load();
    } else {
      _showSnack(r['message'] ?? 'Lỗi', AppColors.danger);
    }
  }

  Future<void> _rejectCheckinSubmission(EventParticipant p) async {
    final submissionId = p.checkinSubmissionId;
    if (submissionId == null) return;

    final controller = TextEditingController();
    String? errorText;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Từ chối ảnh minh chứng'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Lý do',
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  setDialogState(() => errorText = 'Vui lòng nhập lý do');
                  return;
                }
                Navigator.pop(ctx, value);
              },
              child: const Text('Từ chối'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    // Fix 7: chống double-tap
    if (_actionInProgress) return;

    setState(() => _actionInProgress = true);
    final r = await _service.rejectCheckinSubmission(submissionId, reason);
    if (!mounted) return;
    setState(() => _actionInProgress = false);
    if (r['success']) {
      _showSnack('Đã từ chối ảnh minh chứng', AppColors.success);
      _load();
    } else {
      _showSnack(r['message'] ?? 'Lỗi', AppColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.eventTitle)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoading();

    if (_error != null) {
      return AppErrorState(message: _error, onRetry: _load);
    }

    if (_participants.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: AppSpacing.largeVertical),
            AppEmptyState(
              icon: Icons.people_outline,
              title: 'Chưa có ai đăng ký',
              message:
                  'Khi sinh viên đăng ký tham gia sự kiện này, danh sách sẽ hiện ở đây.',
            ),
          ],
        ),
      );
    }

    final int checked = _participants.where((p) => p.checkedIn).length;

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
          _SummaryCard(
            checked: checked,
            total: _participants.length,
          ),
          const SizedBox(height: AppSpacing.cardPadding),
          ..._buildParticipantList(),
        ],
      ),
    );
  }

  List<Widget> _buildParticipantList() {
    final List<Widget> tiles = [];
    for (int i = 0; i < _participants.length; i++) {
      if (i > 0) tiles.add(const SizedBox(height: AppSpacing.element));
      tiles.add(
        _ParticipantTile(
          participant: _participants[i],
          isAdmin: widget.isAdmin,
          onCheckIn: () => _checkIn(_participants[i]),
          onViewImage: () => _showCheckinImage(_participants[i]),
          onApproveSubmission: () =>
              _approveCheckinSubmission(_participants[i]),
          onRejectSubmission: () => _rejectCheckinSubmission(_participants[i]),
        ),
      );
    }
    return tiles;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.checked, required this.total});

  final int checked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final int notChecked = total - checked;

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
              Icons.fact_check_outlined,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.element),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tiến độ check-in', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.tiny),
                Text('$checked / $total', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  'Chưa check-in: $notChecked',
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

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.participant,
    required this.isAdmin,
    required this.onCheckIn,
    required this.onViewImage,
    required this.onApproveSubmission,
    required this.onRejectSubmission,
  });

  final EventParticipant participant;
  final bool isAdmin;
  final VoidCallback onCheckIn;
  final VoidCallback onViewImage;
  final VoidCallback onApproveSubmission;
  final VoidCallback onRejectSubmission;

  @override
  Widget build(BuildContext context) {
    final bool checkedIn = participant.checkedIn;
    final Color tone = checkedIn ? AppColors.success : AppColors.warning;
    final IconData icon =
        checkedIn ? Icons.check_rounded : Icons.person_outline;
    final String status = participant.checkinSubmissionStatus ?? '';
    final bool pendingSubmission = status == 'PENDING';
    final bool approvedSubmission = status == 'APPROVED';
    final bool rejectedSubmission = status == 'REJECTED';
    final bool hasImage = (participant.checkinImageUrl ?? '').trim().isNotEmpty;
    final bool canReview =
        pendingSubmission && participant.checkinSubmissionId != null;
    final String subtitle = checkedIn
        ? 'Đã check-in'
        : pendingSubmission
        ? 'Chờ duyệt ảnh'
        : rejectedSubmission
        ? 'Đã từ chối ảnh'
        : 'Đã đăng ký, chưa check-in';
    final String displayName =
        participant.fullName ?? 'User #${participant.userId}';

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: tone),
          ),
          const SizedBox(width: AppSpacing.element),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.tiny),
                Text(subtitle, style: AppTextStyles.caption),
                if (pendingSubmission ||
                    approvedSubmission ||
                    rejectedSubmission) ...[
                  const SizedBox(height: AppSpacing.small),
                  _SubmissionStatusChip(status: status, checkedIn: checkedIn),
                ],
                if (isAdmin) ...[
                  const SizedBox(height: AppSpacing.small),
                  Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.small,
                    children: [
                      if (pendingSubmission)
                        AppButton(
                          label: 'Xem ảnh',
                          icon: Icons.image_outlined,
                          variant: AppButtonVariant.secondary,
                          size: AppButtonSize.small,
                          fullWidth: false,
                          onPressed: hasImage ? onViewImage : null,
                        ),
                      if (pendingSubmission)
                        AppButton(
                          label: 'Duyệt',
                          icon: Icons.check_circle_outline,
                          size: AppButtonSize.small,
                          fullWidth: false,
                          onPressed: canReview ? onApproveSubmission : null,
                        ),
                      if (pendingSubmission)
                        AppButton(
                          label: 'Từ chối',
                          icon: Icons.cancel_outlined,
                          variant: AppButtonVariant.danger,
                          size: AppButtonSize.small,
                          fullWidth: false,
                          onPressed: canReview ? onRejectSubmission : null,
                        ),
                      // Fix 3: ẩn nút Check-in thủ công khi đang có PENDING submission
                      if (!checkedIn && !pendingSubmission)
                        AppButton(
                          label: 'Check-in',
                          size: AppButtonSize.small,
                          fullWidth: false,
                          onPressed: onCheckIn,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionStatusChip extends StatelessWidget {
  const _SubmissionStatusChip({required this.status, required this.checkedIn});

  final String status;
  final bool checkedIn;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;

    if (checkedIn || status == 'APPROVED') {
      color = AppColors.success;
      icon = Icons.verified_outlined;
      label = 'Đã duyệt ảnh';
    } else if (status == 'REJECTED') {
      color = AppColors.danger;
      icon = Icons.cancel_outlined;
      label = 'Đã từ chối ảnh';
    } else {
      color = AppColors.warning;
      icon = Icons.hourglass_top;
      label = 'Chờ duyệt ảnh';
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: color.withValues(alpha: 0.1),
      ),
    );
  }
}
