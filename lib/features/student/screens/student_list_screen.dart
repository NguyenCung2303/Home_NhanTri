import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/student_model.dart';
import '../providers/student_provider.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<StudentProvider>().loadStudents());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách học sinh')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.students.length,
              itemBuilder: (context, index) {
                final student = provider.students[index];
                return ListTile(
                  title: Text(student.fullName),
                  subtitle: Text(student.school ?? 'Chưa có trường'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => provider.deleteStudent(student.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final student = StudentModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            fullName: 'Học sinh mới',
            school: 'Tiểu học B',
            status: 'ACTIVE',
            createdAt: DateTime.now().toIso8601String(),
          );
          await provider.addStudent(student);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}