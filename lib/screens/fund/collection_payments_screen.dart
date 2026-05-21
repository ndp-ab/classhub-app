import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment.dart';
import '../../providers/auth_provider.dart';
import '../../services/fund_service.dart';

class CollectionPaymentsScreen extends StatefulWidget {
  final int collectionId;
  final String collectionTitle;
  final bool isAdmin;

  const CollectionPaymentsScreen({
    super.key,
    required this.collectionId,
    required this.collectionTitle,
    required this.isAdmin,
  });

  @override
  State<CollectionPaymentsScreen> createState() => _CollectionPaymentsScreenState();
}

class _CollectionPaymentsScreenState extends State<CollectionPaymentsScreen> {
  final _service = FundService();
  bool _loading = true;
  String? _error;
  List<Payment> _payments = [];

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
    final r = await _service.getCollectionPayments(widget.collectionId, userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success']) {
        _payments = (r['data'] as List).cast<Payment>();
      } else {
        _error = r['message'];
      }
    });
  }

  Future<void> _confirm(Payment p) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    // Confirm dialog — chặn admin lỡ tay (BE giờ idempotent nên không sửa được sau khi xác nhận)
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã đóng?'),
        content: Text('Xác nhận ${p.fullName ?? "sinh viên"} đã đóng khoản này?\n'
            'Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final r = await _service.confirmPayment(p.id, userId);
    if (!mounted) return;
    if (r['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xác nhận thanh toán'), backgroundColor: Colors.green),
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
    // GP1: 3 nhóm
    final pending = _payments.where((p) => p.isPending).toList();
    final unpaid = _payments.where((p) => p.isUnpaid).toList();
    final confirmed = _payments.where((p) => p.isConfirmed).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.collectionTitle)),
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
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Card(
                        color: Colors.blue.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.assessment_outlined),
                          title: Text('Đã xác nhận: ${confirmed.length} / ${_payments.length}'),
                          subtitle: Text(
                            'Chờ xác nhận: ${pending.length}  •  Chưa CK: ${unpaid.length}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // GP1: PENDING lên đầu — admin ưu tiên xử lý
                      if (pending.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Chờ xác nhận',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ),
                        ...pending.map((p) => _buildCard(p)),
                      ],

                      if (unpaid.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Chưa CK',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        ),
                        ...unpaid.map((p) => _buildCard(p)),
                      ],

                      if (confirmed.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('Đã xác nhận',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                        ...confirmed.map((p) => _buildCard(p)),
                      ],

                      if (_payments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('Chưa có dữ liệu')),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCard(Payment p) {
    final Color color;
    final IconData icon;
    final String subtitle;
    switch (p.status) {
      case PaymentStatus.confirmed:
        color = Colors.green;
        icon = Icons.check;
        subtitle = p.confirmedByName != null
            ? 'Đã xác nhận bởi ${p.confirmedByName}'
            : 'Đã xác nhận';
        break;
      case PaymentStatus.pendingVerification:
        color = Colors.blue;
        icon = Icons.hourglass_top;
        subtitle = 'Sinh viên đã báo CK — cần đối chiếu sao kê';
        break;
      case PaymentStatus.unpaid:
        color = Colors.orange;
        icon = Icons.close;
        subtitle = 'Chưa CK';
        break;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(p.fullName ?? 'User #${p.userId}'),
        subtitle: Text(subtitle),
        // Admin xác nhận được cho cả UNPAID (vd nộp tiền mặt) lẫn PENDING
        trailing: widget.isAdmin && !p.isConfirmed
            ? ElevatedButton(
                onPressed: () => _confirm(p),
                child: const Text('Xác nhận'),
              )
            : null,
      ),
    );
  }
}
