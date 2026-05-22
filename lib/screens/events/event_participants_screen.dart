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
      tiles.add(_ParticipantTile(
        participant: _participants[i],
        isAdmin: widget.isAdmin,
        onCheckIn: () => _checkIn(_participants[i]),
      ));
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
  });

  final EventParticipant participant;
  final bool isAdmin;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final bool checkedIn = participant.checkedIn;
    final Color tone = checkedIn ? AppColors.success : AppColors.warning;
    final IconData icon =
        checkedIn ? Icons.check_rounded : Icons.person_outline;
    final String subtitle =
        checkedIn ? 'Đã check-in' : 'Đã đăng ký, chưa check-in';
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
              ],
            ),
          ),
          if (isAdmin && !checkedIn) ...[
            const SizedBox(width: AppSpacing.small),
            AppButton(
              label: 'Check-in',
              size: AppButtonSize.small,
              fullWidth: false,
              onPressed: onCheckIn,
            ),
          ],
        ],
      ),
    );
  }
}
