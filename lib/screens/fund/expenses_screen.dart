import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../providers/auth_provider.dart';
import '../../services/fund_service.dart';
import 'create_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final int classroomId;
  final bool isAdmin;

  const ExpensesScreen({super.key, required this.classroomId, required this.isAdmin});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _service = FundService();
  bool _loading = true;
  String? _error;
  List<Expense> _expenses = [];

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
    final r = await _service.getExpenses(widget.classroomId, userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success']) {
        _expenses = (r['data'] as List).cast<Expense>();
      } else {
        _error = r['message'];
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

  @override
  Widget build(BuildContext context) {
    final total = _expenses.fold<double>(0, (s, e) => s + e.amount);

    return Scaffold(
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
                        color: Colors.red.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.account_balance_wallet_outlined),
                          title: const Text('Tổng chi'),
                          subtitle: Text(_fmtAmount(total),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_expenses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: Text('Chưa có khoản chi nào')),
                        )
                      else
                        ..._expenses.map((e) => Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.redAccent,
                                  child: Icon(Icons.remove, color: Colors.white),
                                ),
                                title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_fmtAmount(e.amount)),
                                    if (e.reason != null && e.reason!.isNotEmpty) Text('Lý do: ${e.reason}'),
                                    if (e.createdByName != null) Text('Bởi: ${e.createdByName}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateExpenseScreen(classroomId: widget.classroomId),
                  ),
                );
                if (ok == true) _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Thêm khoản chi'),
            )
          : null,
    );
  }
}
