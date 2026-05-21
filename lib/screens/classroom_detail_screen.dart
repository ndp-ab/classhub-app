import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'events/events_tab.dart';
import 'fund/fund_tab.dart';
import 'fund/expenses_screen.dart';

class ClassroomDetailScreen extends StatelessWidget {
  final int classroomId;
  final String classroomName;
  final String? inviteCode;
  final String? role;
  final String? faculty;
  final String? academicYear;

  const ClassroomDetailScreen({
    super.key,
    required this.classroomId,
    required this.classroomName,
    this.inviteCode,
    this.role,
    this.faculty,
    this.academicYear,
  });

  bool get _isAdmin => role == 'ADMIN' || role == 'OWNER';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(classroomName),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: 'Tổng quan'),
              Tab(icon: Icon(Icons.payments_outlined), text: 'Khoản thu'),
              Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Khoản chi'),
              Tab(icon: Icon(Icons.event_outlined), text: 'Sự kiện'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(
              classroomName: classroomName,
              inviteCode: inviteCode,
              role: role,
              faculty: faculty,
              academicYear: academicYear,
            ),
            FundTab(classroomId: classroomId, isAdmin: _isAdmin),
            ExpensesScreen(classroomId: classroomId, isAdmin: _isAdmin),
            EventsTab(classroomId: classroomId, isAdmin: _isAdmin),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final String classroomName;
  final String? inviteCode;
  final String? role;
  final String? faculty;
  final String? academicYear;

  const _OverviewTab({
    required this.classroomName,
    this.inviteCode,
    this.role,
    this.faculty,
    this.academicYear,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.class_outlined),
            title: const Text('Tên lớp'),
            subtitle: Text(classroomName),
          ),
        ),
        if (faculty != null && faculty!.isNotEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.business_outlined),
              title: const Text('Khoa'),
              subtitle: Text(faculty!),
            ),
          ),
        if (academicYear != null && academicYear!.isNotEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Khóa'),
              subtitle: Text(academicYear!),
            ),
          ),
        if (role != null)
          Card(
            child: ListTile(
              leading: Icon(role == 'ADMIN' ? Icons.star : Icons.person),
              title: const Text('Vai trò'),
              subtitle: Text(role!),
            ),
          ),
        if (inviteCode != null && inviteCode!.isNotEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.key_outlined),
              title: const Text('Mã tham gia'),
              subtitle: Text(
                inviteCode!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã copy mã tham gia')),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

