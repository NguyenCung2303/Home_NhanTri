import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/student_provider.dart';
import 'student_form_screen.dart';

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
          : provider.students.isEmpty
              ? const Center(child: Text('Chưa có học sinh'))
              : ListView.builder(
                  itemCount: provider.students.length,
                  itemBuilder: (context, index) {
                    final student = provider.students[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(student.fullName),
                        subtitle: Text(
                          '${student.school ?? 'Chưa có trường'}\nLichess: ${student.lichessUsername?.isNotEmpty == true ? student.lichessUsername : 'Chưa nhập'}',
                        ),
                        isThreeLine: true,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => StudentFormScreen(student: student)),
                          );
                          if (!mounted) return;
                          context.read<StudentProvider>().loadStudents();
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_rounded),
                          onPressed: () => provider.deleteStudent(student.id),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StudentFormScreen()),
          );
          if (!mounted) return;
          context.read<StudentProvider>().loadStudents();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
