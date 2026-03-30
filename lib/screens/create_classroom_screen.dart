import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/classroom_service.dart';

class CreateClassroomScreen extends StatefulWidget {
  const CreateClassroomScreen({super.key});

  @override
  State<CreateClassroomScreen> createState() => _CreateClassroomScreenState();
}

class _CreateClassroomScreenState extends State<CreateClassroomScreen> {
  final _classNameController = TextEditingController();
  final _facultyController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _classroomService = ClassroomService();
  bool _isLoading = false;
  String? _inviteCode;

  @override
  void dispose() {
    _classNameController.dispose();
    _facultyController.dispose();
    _academicYearController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    final result = await _classroomService.createClassroom(
      _classNameController.text.trim(),
      _facultyController.text.trim(),
      _academicYearController.text.trim(),
      userId!,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      setState(() => _inviteCode = result['data']['inviteCode']);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo lớp học mới')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _inviteCode != null ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _classNameController,
            decoration: const InputDecoration(
              labelText: 'Tên lớp',
              hintText: 'VD: 64KTPM3',
              prefixIcon: Icon(Icons.class_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Nhập tên lớp' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _facultyController,
            decoration: const InputDecoration(
              labelText: 'Khoa',
              hintText: 'VD: Công nghệ thông tin',
              prefixIcon: Icon(Icons.business_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _academicYearController,
            decoration: const InputDecoration(
              labelText: 'Khóa',
              hintText: 'VD: K64',
              prefixIcon: Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _create,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Tạo lớp', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 80, color: Colors.green),
        const SizedBox(height: 16),
        const Text(
          'Tạo lớp thành công!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        const Text('Mã tham gia lớp:', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            _inviteCode!,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: Colors.blue.shade700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _inviteCode!));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã copy mã tham gia')),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copy mã'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Gửi mã này cho sinh viên để tham gia lớp',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Quay về trang chủ'),
        ),
      ],
    );
  }
}