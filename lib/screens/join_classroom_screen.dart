import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/classroom_service.dart';

class JoinClassroomScreen extends StatefulWidget {
  const JoinClassroomScreen({super.key});

  @override
  State<JoinClassroomScreen> createState() => _JoinClassroomScreenState();
}

class _JoinClassroomScreenState extends State<JoinClassroomScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _classroomService = ClassroomService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    final result = await _classroomService.joinClassroom(
      _codeController.text.trim().toUpperCase(),
      userId!,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      final data = result['data'];
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tham gia thành công!'),
          content: Text('Bạn đã tham gia lớp ${data['className']} với vai trò ${data['role']}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tham gia lớp học')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.group_add, size: 80, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Nhập mã tham gia',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhận mã từ ban cán sự lớp',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'VD: X7A9KQ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Nhập mã tham gia' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _join,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Tham gia', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}