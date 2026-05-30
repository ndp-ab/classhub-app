import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/fund_collection.dart';
import '../../models/payment.dart';
import '../../providers/auth_provider.dart';
import '../../services/fund_service.dart';
import 'collection_payments_screen.dart';
import 'create_collection_screen.dart';
import 'payment_qr_screen.dart';

class FundTab extends StatefulWidget {
  final int classroomId;
  final bool isAdmin;

  const FundTab({super.key, required this.classroomId, required this.isAdmin});

  @override
  State<FundTab> createState() => _FundTabState();
}

class _FundTabState extends State<FundTab> {
  final _service = FundService();
  bool _loading = true;
  String? _error;
  List<FundCollection> _collections = [];
  List<Payment> _myPayments = [];

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

    final col = await _service.getCollections(widget.classroomId, userId);
    final my = await _service.getMyPayments(widget.classroomId, userId);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (col['success']) {
        _collections = (col['data'] as List).cast<FundCollection>();
      } else {
        _error = col['message'];
      }
      if (my['success']) {
        _myPayments = (my['data'] as List).cast<Payment>();
      }
    });
  }

  String _fmtAmount(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()} đ';
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (!widget.isAdmin) _buildMySection(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                widget.isAdmin ? 'Danh sách đợt thu' : 'Tất cả đợt thu',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (_collections.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: Text('Chưa có khoản thu nào', style: TextStyle(color: Colors.grey))),
              )
            else
              ..._collections.map(_buildCollectionCard),
          ],
        ),
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateCollectionScreen(classroomId: widget.classroomId),
                  ),
                );
                if (ok == true) _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo đợt thu'),
            )
          : null,
    );
  }

  Widget _buildMySection() {
    // GP1: 3 trạng thái
    final unpaid = _myPayments.where((p) => p.isUnpaid).toList();
    final pending = _myPayments.where((p) => p.isPending).toList();
    final confirmed = _myPayments.where((p) => p.isConfirmed).toList();

    String subtitle(p) {
      if (p.amount == null) return '';
      final money = _fmtAmount(p.amount!);
      final hasDeadline = p.deadline != null;
      return hasDeadline ? '$money  •  Hạn: ${_fmtDate(p.deadline)}' : money;
    }

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Khoản của bạn',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_myPayments.isEmpty)
              const Text('Bạn chưa có khoản nào', style: TextStyle(color: Colors.grey))
            else ...[
              Text('Chưa CK: ${unpaid.length}  •  Đã báo: ${pending.length}  •  Đã xác nhận: ${confirmed.length}'),
              const SizedBox(height: 8),

              // Chưa CK — màu cam, có nút "Xem QR"
              ...unpaid.map((p) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.error_outline, color: Colors.orange),
                    title: Text(p.collectionTitle ?? 'Khoản #${p.id}'),
                    subtitle: Text(subtitle(p)),
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Xem QR'),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PaymentQrScreen(paymentId: p.id)),
                        );
                        _load();
                      },
                    ),
                  )),

              // Đã báo CK — màu xanh dương, chờ admin (vẫn xem được QR nếu muốn)
              ...pending.map((p) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.hourglass_top, color: Colors.blue),
                    title: Text(p.collectionTitle ?? 'Khoản #${p.id}'),
                    subtitle: Text('${subtitle(p)}\nĐã báo CK — chờ Admin xác nhận'),
                    isThreeLine: true,
                    trailing: TextButton.icon(
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Xem QR'),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PaymentQrScreen(paymentId: p.id)),
                        );
                        _load();
                      },
                    ),
                  )),

              // Đã xác nhận — màu xanh lá
              ...confirmed.map((p) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(p.collectionTitle ?? 'Khoản #${p.id}'),
                    subtitle: Text(p.confirmedByName != null
                        ? 'Đã xác nhận bởi ${p.confirmedByName}'
                        : 'Đã xác nhận'),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard(FundCollection c) {
    return Card(
      child: ListTile(
        title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số tiền: ${_fmtAmount(c.amount)}'),
            if (c.deadline != null) Text('Hạn: ${_fmtDate(c.deadline)}'),
            Text('Đã đóng: ${c.paidCount}/${c.totalMembers}'),
          ],
        ),
        trailing: widget.isAdmin ? const Icon(Icons.chevron_right) : null,
        onTap: widget.isAdmin
            ? () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CollectionPaymentsScreen(
                      collectionId: c.id,
                      collectionTitle: c.title,
                      isAdmin: widget.isAdmin,
                    ),
                  ),
                );
                _load();
              }
            : null,
      ),
    );
  }
}
