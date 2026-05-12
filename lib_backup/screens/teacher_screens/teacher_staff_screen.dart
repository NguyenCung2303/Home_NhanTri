import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_colors.dart';
import 'teacher_add_staff_screen.dart';
import 'teacher_staff_detail_screen.dart';

class TeacherStaffScreen extends StatefulWidget {
  const TeacherStaffScreen({super.key});

  @override
  State<TeacherStaffScreen> createState() => _TeacherStaffScreenState();
}

class _TeacherStaffScreenState extends State<TeacherStaffScreen> {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  late Future<List<_StaffModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadStaffs();
  }

  Future<void> _reload() async {
    final future = _loadStaffs();

    setState(() {
      _future = future;
    });

    await future;
  }

  Future<List<_StaffModel>> _loadStaffs() async {
    final url = Uri.parse('$_baseUrl/users?pageSize=200');
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 404) return [];
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không tải được danh sách nhân viên: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = data['documents'] as List<dynamic>? ?? [];

    final staffs = documents.map((doc) {
      final document = doc as Map<String, dynamic>;
      final name = document['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      return _StaffModel.fromFirestore(id, fields);
    }).where((staff) {
      return staff.status == 'ACTIVE' &&
          ['TEACHER', 'ASSISTANT', 'MANAGER', 'ADMIN'].contains(staff.role);
    }).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return staffs;
  }

  Future<void> _openAddStaff() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TeacherAddStaffScreen()),
    );

    if (result == true && mounted) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Nhân viên'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _openAddStaff,
          ),
        ],
      ),
      body: FutureBuilder<List<_StaffModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          final staffs = snapshot.data ?? [];

          if (staffs.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 260),
                  Center(
                    child: Text(
                      'Chưa có nhân viên nào',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: staffs.length,
              itemBuilder: (_, i) {
                final staff = staffs[i];
                return _StaffItem(
                  name: staff.fullName,
                  role: staff.roleLabel,
                  salary: staff.baseSalary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherStaffDetailScreen(
                          name: staff.fullName,
                          role: staff.roleLabel,
                          baseSalary: staff.baseSalary,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _StaffModel {
  final String id;
  final String fullName;
  final String role;
  final String status;
  final int baseSalary;

  const _StaffModel({
    required this.id,
    required this.fullName,
    required this.role,
    required this.status,
    required this.baseSalary,
  });

  String get roleLabel {
    switch (role) {
      case 'TEACHER':
        return 'Giáo viên';
      case 'ASSISTANT':
        return 'Trợ giảng';
      case 'MANAGER':
        return 'Quản lý';
      case 'ADMIN':
        return 'Admin';
      default:
        return role;
    }
  }

  factory _StaffModel.fromFirestore(
    String id,
    Map<String, dynamic> fields,
  ) {
    String str(String key) {
      final value = fields[key];
      if (value == null) return '';

      return value['stringValue']?.toString() ??
          value['integerValue']?.toString() ??
          value['doubleValue']?.toString() ??
          value['timestampValue']?.toString() ??
          '';
    }

    int intValue(String key) {
      return int.tryParse(str(key)) ?? 0;
    }

    return _StaffModel(
      id: id,
      fullName: str('fullName').isNotEmpty ? str('fullName') : str('full_name'),
      role: str('role').isNotEmpty ? str('role').toUpperCase() : 'TEACHER',
      status: str('status').isNotEmpty ? str('status').toUpperCase() : 'ACTIVE',
      baseSalary: intValue('baseSalary'),
    );
  }
}

class _StaffItem extends StatelessWidget {
  final String name;
  final String role;
  final int salary;
  final VoidCallback onTap;

  const _StaffItem({
    required this.name,
    required this.role,
    required this.salary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              salary > 0 ? _format(salary) : 'Chưa set',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _format(int v) => v.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => '.',
      );
}
