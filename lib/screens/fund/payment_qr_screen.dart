import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/fund_service.dart';

class PaymentQrScreen extends StatefulWidget {
  final int paymentId;

  const PaymentQrScreen({super.key, required this.paymentId});

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  final _service = FundService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _qr;

  // GP1: 3 trạng thái — UNPAID | PENDING_VERIFICATION | CONFIRMED
  String _status = 'UNPAID';
  bool _markedPaid = false;
  bool _confirmed = false;
  bool _markingPaid = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadQr();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQr() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'Chưa đăng nhập';
      });
      return;
    }
    final r = await _service.getPaymentQr(widget.paymentId, userId);
    if (!mounted) return;
    if (r['success']) {
      setState(() {
        _qr = r['data'] as Map<String, dynamic>;
        _loading = false;
      });
      // Lấy status lần đầu để biết user đã từng báo CK chưa (nếu mở lại màn này)
      _pollStatus();
      _startPolling();
    } else {
      setState(() {
        _loading = false;
        _error = r['message'];
      });
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _pollStatus());
  }

  Future<void> _pollStatus() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    final r = await _service.getPaymentStatus(widget.paymentId, userId);
    if (!mounted) return;
    if (r['success']) {
      final data = r['data'] as Map<String, dynamic>;
      final status = (data['status'] ?? 'UNPAID').toString();
      final marked = data['markedPaid'] == true;
      final confirmed = data['confirmedByAdmin'] == true;
      setState(() {
        _status = status;
        _markedPaid =
            marked || status == 'PENDING_VERIFICATION' || status == 'CONFIRMED';
        _confirmed = confirmed;
      });
      if (confirmed || status == 'CONFIRMED') {
        _timer?.cancel();
      }
    }
  }

  Future<void> _markPaid() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã chuyển khoản?'),
        content: const Text(
          'Chỉ bấm sau khi đã chuyển khoản thành công qua app ngân hàng.\n\n'
          'Admin sẽ đối chiếu sao kê + nội dung CK để xác nhận.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tôi đã CK'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _markingPaid = true);
    final r = await _service.markPaymentAsPaid(widget.paymentId, userId);
    if (!mounted) return;
    setState(() => _markingPaid = false);

    if (r['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã báo chuyển khoản. Đang chờ Admin xác nhận.'),
          backgroundColor: Colors.green,
        ),
      );
      _pollStatus(); // cập nhật UI ngay
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(r['message'] ?? 'Lỗi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _fmtAmount(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán QR')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    if (_qr == null) return const SizedBox.shrink();

    final qrUrl = _qr!['qrUrl']?.toString();
    final amount = _qr!['amount'];
    final paymentCode = _qr!['paymentCode']?.toString() ?? '';
    final collectionTitle = _qr!['collectionTitle']?.toString() ?? '';
    final deadline = _qr!['deadline']?.toString();
    final bankName = _qr!['bankName']?.toString() ?? '';
    final accountNo = _qr!['accountNo']?.toString() ?? '';
    final accountName = _qr!['accountName']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (collectionTitle.isNotEmpty)
            Text(
              collectionTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 8),
          if (amount is num)
            Text(
              _fmtAmount(amount),
              style: const TextStyle(
                fontSize: 24,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (deadline != null) ...[
            const SizedBox(height: 4),
            Text('Hạn: $deadline', style: const TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 16),
          if (qrUrl != null && qrUrl.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.network(
                qrUrl,
                height: 280,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 280,
                  child: Center(child: Text('Không tải được QR')),
                ),
              ),
            )
          else
            const Text('Không có URL QR', style: TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          if (bankName.isNotEmpty ||
              accountNo.isNotEmpty ||
              accountName.isNotEmpty) ...[
            _buildBankInfoBox(
              bankName: bankName,
              accountNo: accountNo,
              accountName: accountName,
            ),
            const SizedBox(height: 16),
          ],
          if (paymentCode.isNotEmpty)
            Card(
              color: Colors.amber.shade50,
              child: ListTile(
                title: const Text('Nội dung chuyển khoản'),
                subtitle: Text(
                  paymentCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: paymentCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã copy nội dung CK')),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildStatusBox(),
          const SizedBox(height: 12),
          // GP1: chỉ hiện nút khi UNPAID. Khi PENDING/CONFIRMED thì ẩn.
          if (!_markedPaid && !_confirmed)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _markingPaid ? null : _markPaid,
                icon: const Icon(Icons.check),
                label: _markingPaid
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Tôi đã chuyển khoản',
                        style: TextStyle(fontSize: 16),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBankInfoBox({
    required String bankName,
    required String accountNo,
    required String accountName,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Tài khoản nhận tiền',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (bankName.isNotEmpty) Text('Ngân hàng: $bankName'),
            if (accountNo.isNotEmpty)
              Row(
                children: [
                  Expanded(child: Text('Số tài khoản: $accountNo')),
                  IconButton(
                    tooltip: 'Copy số tài khoản',
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: accountNo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã copy số tài khoản')),
                      );
                    },
                  ),
                ],
              ),
            if (accountName.isNotEmpty) Text('Chủ tài khoản: $accountName'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox() {
    // 3 trạng thái — màu / icon / text khác nhau
    late final Color color;
    late final IconData icon;
    late final String text;
    late final bool showSpinner;

    if (_confirmed || _status == 'CONFIRMED') {
      color = Colors.green;
      icon = Icons.check_circle;
      text = 'Đã thanh toán & được Admin xác nhận';
      showSpinner = false;
    } else if (_markedPaid || _status == 'PENDING_VERIFICATION') {
      color = Colors.blue;
      icon = Icons.hourglass_top;
      text = 'Đã báo chuyển khoản — đang chờ Admin xác nhận';
      showSpinner = true;
    } else {
      color = Colors.orange;
      icon = Icons.payments_outlined;
      text = 'Quét QR để chuyển khoản, sau đó bấm "Tôi đã chuyển khoản"';
      showSpinner = false;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (showSpinner)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
