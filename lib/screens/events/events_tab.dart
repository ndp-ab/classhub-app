import 'package:flutter/material.dart';
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
        // B4: BE trả eventId trong EventParticipantResponse → match chuẩn
        _myEventIds = list
            .where((p) => p.eventId != null)
            .map((p) => p.eventId!)
            .toSet();
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

  String _fmtDateTime(DateTime? d) {
    if (d == null) return '';
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
                      Text(_error!, style: const TextStyle(color: Colors.red)),
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
                            final joined = _myEventIds.contains(e.id);
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
                                          child: Text(e.title,
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
                                    if (e.description != null && e.description!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(e.description!),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(_fmtDateTime(e.eventTime),
                                            style: const TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                    if (e.location != null && e.location!.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                              child: Text(e.location!,
                                                  style: const TextStyle(color: Colors.grey))),
                                        ],
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.people,
                                            size: 16, color: Colors.grey.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                            'Đăng ký: ${e.volunteerCount}  •  Check-in: ${e.checkedInCount}',
                                            style: TextStyle(color: Colors.grey.shade700)),
                                        const Spacer(),
                                        if (widget.isAdmin)
                                          TextButton.icon(
                                            icon: const Icon(Icons.checklist),
                                            label: const Text('Người tham gia'),
                                            onPressed: () async {
                                              await Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => EventParticipantsScreen(
                                                    eventId: e.id,
                                                    eventTitle: e.title,
                                                    isAdmin: widget.isAdmin,
                                                  ),
                                                ),
                                              );
                                              _load();
                                            },
                                          )
                                        else
                                          ElevatedButton.icon(
                                            icon: Icon(joined
                                                ? Icons.cancel_outlined
                                                : Icons.how_to_reg),
                                            label: Text(joined ? 'Huỷ đăng ký' : 'Đăng ký'),
                                            onPressed: () => _toggleVolunteer(e),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: joined ? Colors.orange : null,
                                            ),
                                          ),
                                      ],
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
