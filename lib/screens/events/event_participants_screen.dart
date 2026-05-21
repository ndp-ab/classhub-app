import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  State<EventParticipantsScreen> createState() => _EventParticipantsScreenState();
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
        content: Text('Xác nhận ${p.fullName ?? "sinh viên"} có mặt tại sự kiện?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Check-in')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final r = await _service.checkIn(widget.eventId, p.userId!, adminId);
    if (!mounted) return;
    if (r['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã check-in'), backgroundColor: Colors.green),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r['message'] ?? 'Lỗi'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final checked = _participants.where((p) => p.checkedIn).length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.eventTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Card(
                        color: Colors.blue.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.fact_check_outlined),
                          title: Text('Check-in: $checked / ${_participants.length}'),
                          subtitle: Text('Chưa check-in: ${_participants.length - checked}'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_participants.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('Chưa có ai đăng ký')),
                        )
                      else
                        ..._participants.map((p) => Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: p.checkedIn ? Colors.green : Colors.orange,
                                  child: Icon(
                                    p.checkedIn ? Icons.check : Icons.person_outline,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(p.fullName ?? 'User #${p.userId}'),
                                subtitle: Text(p.checkedIn
                                    ? 'Đã check-in'
                                    : 'Đã đăng ký, chưa check-in'),
                                trailing: widget.isAdmin && !p.checkedIn
                                    ? ElevatedButton(
                                        onPressed: () => _checkIn(p),
                                        child: const Text('Check-in'),
                                      )
                                    : null,
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }
}
