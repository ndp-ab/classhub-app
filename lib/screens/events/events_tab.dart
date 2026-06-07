import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/event.dart';
import '../../providers/auth_provider.dart';
import '../../services/event_service.dart';
import 'create_event_screen.dart';
import 'event_participants_screen.dart';

class EventsTab extends StatefulWidget {
  final int classroomId;
  final bool isAdmin;

  const EventsTab({super.key, required this.classroomId, required this.isAdmin});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  final _service = EventService();
  bool _loading = true;
  String? _error;
  List<ClassEvent> _events = [];
  Set<int> _myEventIds = {};
  Map<int, EventParticipant> _myParticipants = {};

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

    final ev = await _service.getEvents(widget.classroomId, userId);
    final my = await _service.getMyEvents(widget.classroomId, userId);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (ev['success']) {
        _events = (ev['data'] as List).cast<ClassEvent>();
      } else {
        _error = ev['message'];
      }
      if (my['success']) {
        final list = (my['data'] as List).cast<EventParticipant>();
        final participants = <int, EventParticipant>{};
        for (final p in list) {
          final eventId = p.eventId;
          if (eventId != null) participants[eventId] = p;
        }
        _myParticipants = participants;
        _myEventIds = participants.keys.toSet();
      }
    });
  }

  Future<void> _toggleVolunteer(ClassEvent e) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    final isJoined = _myEventIds.contains(e.id);
    final r = isJoined
        ? await _service.cancelVolunteer(e.id, userId)
        : await _service.volunteer(e.id, userId);

    if (!mounted) return;
    if (r['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isJoined ? 'Đã huỷ đăng ký' : 'Đã đăng ký tham gia'),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r['message'] ?? 'Lỗi'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _captureCheckinImage(int eventId) async {
    while (mounted) {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (image == null || !mounted) return;

      final action = await _showCheckinPreview(eventId, image.path);
      if (action == _CheckinPreviewAction.retake) continue;
      return;
    }
  }

  Future<_CheckinPreviewAction?> _showCheckinPreview(
    int eventId,
    String imagePath,
  ) {
    bool submitting = false;

    return showDialog<_CheckinPreviewAction>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Gửi ảnh minh chứng'),
              content: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  width: double.maxFinite,
                  height: 320,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.pop(
                          dialogContext,
                          _CheckinPreviewAction.retake,
                        ),
                  child: const Text('Chụp lại'),
                ),
                ElevatedButton.icon(
                  icon: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Gửi minh chứng'),
                  onPressed: submitting
                      ? null
                      : () async {
                          setDialogState(() => submitting = true);
                          final navigator = Navigator.of(dialogContext);
                          final messenger = ScaffoldMessenger.of(context);
                          final r = await _service.submitCheckinImage(
                            eventId: eventId,
                            imagePath: imagePath,
                          );
                          // Guard: parent widget phải còn mounted
                          if (!mounted) return;
                          // Guard: dialog context phải còn mounted trước khi gọi setDialogState/navigator
                          if (!dialogContext.mounted) return;
                          if (r['success']) {
                            navigator.pop(_CheckinPreviewAction.submitted);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Đã gửi ảnh minh chứng, vui lòng chờ Ban cán sự xác nhận',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _load();
                          } else {
                            setDialogState(() => submitting = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(r['message'] ?? 'Lỗi'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCheckinControl(int eventId, EventParticipant? participant) {
    if (participant == null) return const SizedBox.shrink();

    final status = participant.checkinSubmissionStatus;
    if (participant.checkedIn || status == 'APPROVED') {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          avatar: Icon(Icons.verified_outlined, size: 16, color: Colors.green),
          label: Text('Đã điểm danh', style: TextStyle(fontSize: 12)),
          backgroundColor: Color(0xFFE8F5E9),
        ),
      );
    }

    if (status == 'PENDING') {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          avatar: Icon(Icons.hourglass_top, size: 16, color: Colors.orange),
          label: Text(
            'Chờ ban cán sự xác nhận',
            style: TextStyle(fontSize: 12),
          ),
          backgroundColor: Color(0xFFFFF8E1),
        ),
      );
    }

    final rejected = status == 'REJECTED';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rejected)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Ảnh bị từ chối, vui lòng gửi lại',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(rejected ? 'Gửi lại ảnh' : 'Chụp ảnh điểm danh'),
            onPressed: () => _captureCheckinImage(eventId),
          ),
        ),
      ],
    );
  }

  String _fmtDateTime(DateTime? d) {
    if (d == null) return 'Chưa có thời gian';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error ?? 'Đã xảy ra lỗi',
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _events.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(
                              child: Text('Chưa có sự kiện nào',
                                  style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _events.length,
                          itemBuilder: (_, i) {
                            final e = _events[i];
                            final myParticipant = _myParticipants[e.id];
                            final joined = _myEventIds.contains(e.id);
                            final title = e.title.trim().isNotEmpty
                                ? e.title.trim()
                                : 'Sự kiện không tên';
                            final description = e.description?.trim();
                            final location = e.location?.trim();
                            final eventTimeText = _fmtDateTime(e.eventTime);
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.event, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(title,
                                              style: const TextStyle(
                                                  fontSize: 16, fontWeight: FontWeight.bold)),
                                        ),
                                        if (joined)
                                          const Chip(
                                            label: Text('Đã đăng ký',
                                                style: TextStyle(fontSize: 11)),
                                            backgroundColor: Color(0xFFE3F2FD),
                                          ),
                                      ],
                                    ),
                                    if (description != null && description.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(description),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(eventTimeText,
                                            style: const TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                    if (location != null && location.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                              child: Text(location,
                                                  style: const TextStyle(color: Colors.grey))),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.people,
                                            size: 16, color: Colors.grey.shade700),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Đăng ký: ${e.volunteerCount}  •  Check-in: ${e.checkedInCount}',
                                            style: TextStyle(color: Colors.grey.shade700),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    if (joined && !widget.isAdmin) ...[
                                      _buildCheckinControl(e.id, myParticipant),
                                      const SizedBox(height: 8),
                                    ],
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: widget.isAdmin
                                          ? TextButton.icon(
                                              icon: const Icon(Icons.checklist),
                                              label: const Text('Người tham gia'),
                                              style: TextButton.styleFrom(
                                                minimumSize: const Size(0, 48),
                                              ),
                                              onPressed: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => EventParticipantsScreen(
                                                      eventId: e.id,
                                                      eventTitle: title,
                                                      isAdmin: widget.isAdmin,
                                                    ),
                                                  ),
                                                );
                                                _load();
                                              },
                                            )
                                          : ElevatedButton.icon(
                                              icon: Icon(joined
                                                  ? Icons.cancel_outlined
                                                  : Icons.how_to_reg),
                                              label: Text(joined ? 'Huỷ đăng ký' : 'Đăng ký'),
                                              onPressed: () => _toggleVolunteer(e),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: joined ? Colors.orange : null,
                                                minimumSize: const Size(0, 48),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              heroTag: 'events_create_event_fab',
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateEventScreen(classroomId: widget.classroomId),
                  ),
                );
                if (ok == true) _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo sự kiện'),
            )
          : null,
    );
  }
}

enum _CheckinPreviewAction { retake, submitted }
