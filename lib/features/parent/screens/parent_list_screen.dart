import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/parent_model.dart';
import '../../../theme/app_colors.dart';
import '../providers/parent_provider.dart';
import 'parent_student_management_screen.dart';

class ParentListScreen extends StatefulWidget {
  const ParentListScreen({super.key});

  @override
  State<ParentListScreen> createState() => _ParentListScreenState();
}

class _ParentListScreenState extends State<ParentListScreen> {
  static final _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ParentProvider>().loadParents());
  }

  Future<void> _addSampleParent() async {
    final now = DateTime.now();
    final suffix = now.millisecondsSinceEpoch.toString().substring(7);

    final parent = ParentModel(
      id: _uuid.v4(),
      userId: 'manual_parent_$suffix',
      fullName: 'Phụ huynh mới $suffix',
      phone: '09$suffix',
      email: 'parent$suffix@gmail.com',
      address: 'Hà Nội',
      relationshipToStudent: 'Phụ huynh',
      note: '',
      createdAt: now.toIso8601String(),
    );

    await context.read<ParentProvider>().addParent(parent);
  }

  Future<void> _deleteParent(ParentModel parent) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Xóa phụ huynh', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Xóa ${parent.fullName}? Các liên kết với học sinh cũng sẽ bị xóa.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await context.read<ParentProvider>().deleteParent(parent.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParentProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Quản lý phụ huynh'),
        centerTitle: true,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.parents.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có phụ huynh',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.parents.length,
                  itemBuilder: (context, index) {
                    final parent = provider.parents[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accent.withOpacity(0.18),
                          child: const Icon(Icons.family_restroom, color: AppColors.accent),
                        ),
                        title: Text(
                          parent.fullName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _parentSubtitle(parent),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ParentStudentManagementScreen(parent: parent),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.manage_accounts, color: AppColors.accent),
                              tooltip: 'Gán học sinh',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ParentStudentManagementScreen(parent: parent),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Xóa phụ huynh',
                              onPressed: () => _deleteParent(parent),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accent,
        onPressed: _addSampleParent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm mẫu', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  String _parentSubtitle(ParentModel parent) {
    final values = [
      parent.phone,
      parent.relationshipToStudent,
      parent.address,
    ].where((e) => e != null && e!.trim().isNotEmpty).cast<String>().toList();
    return values.isEmpty ? 'Chưa có thông tin liên hệ' : values.join(' • ');
  }
}
