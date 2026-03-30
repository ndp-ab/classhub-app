import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/classroom_service.dart';
import 'login_screen.dart';
import 'create_classroom_screen.dart';
import 'join_classroom_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _classroomService = ClassroomService();
  List<dynamic> _classrooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClassrooms();
  }

  Future<void> _loadClassrooms() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    if (userId == null) return;

    final result = await _classroomService.getMyClassrooms(userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _classrooms = result['data'];
        }
      });
    }
  }

  Future<void> _navigateAndRefresh(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (result == true) {
      setState(() => _isLoading = true);
      _loadClassrooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ClassHub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateAndRefresh(const CreateClassroomScreen()),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo lớp'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateAndRefresh(const JoinClassroomScreen()),
                    icon: const Icon(Icons.group_add),
                    label: const Text('Tham gia'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _classrooms.isEmpty
                ? const Center(
              child: Text(
                'Chưa tham gia lớp nào\nBấm "Tạo lớp" hoặc "Tham gia" để bắt đầu',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _classrooms.length,
              itemBuilder: (context, index) {
                final c = _classrooms[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c['role'] == 'ADMIN'
                          ? Colors.blue
                          : Colors.grey.shade400,
                      child: Icon(
                        c['role'] == 'ADMIN' ? Icons.star : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      c['className'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${c['faculty'] ?? ''} • ${c['academicYear'] ?? ''}'),
                    trailing: Chip(
                      label: Text(
                        c['role'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}