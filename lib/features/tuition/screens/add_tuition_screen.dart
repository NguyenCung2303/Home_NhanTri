import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/class_room_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/tuition_model.dart';
import '../../../features/class_room/providers/class_room_provider.dart';
import '../../../features/student/providers/student_provider.dart';
import '../providers/tuition_provider.dart';

class AddTuitionScreen extends StatefulWidget {
  const AddTuitionScreen({super.key});

  @override
  State<AddTuitionScreen> createState() => _AddTuitionScreenState();
}

class _AddTuitionScreenState extends State<AddTuitionScreen> {
  StudentModel? selectedStudent;
  ClassRoomModel? selectedClassRoom;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<StudentProvider>().loadStudents();
      await context.read<ClassRoomProvider>().loadClassRooms();
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    dueDateController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: now,
    );

    if (picked != null) {
      dueDateController.text = picked.toIso8601String().split('T').first;
    }
  }

  Future<void> _save() async {
    if (selectedStudent == null || selectedClassRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn học sinh và lớp học')),
      );
      return;
    }

    if (amountController.text.trim().isEmpty || dueDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền và hạn đóng')),
      );
      return;
    }

    final tuition = TuitionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      studentId: selectedStudent!.id,
      classId: selectedClassRoom!.id,
      amount: double.tryParse(amountController.text.trim()) ?? 0,
      dueDate: dueDateController.text.trim(),
      paidDate: null,
      status: 'UNPAID',
      paymentMethod: null,
      transactionCode: null,
      qrContent: null,
      note: noteController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );

    await context.read<TuitionProvider>().addTuition(tuition);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;
    final classRooms = context.watch<ClassRoomProvider>().classRooms;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm học phí'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<StudentModel>(
              value: selectedStudent,
              decoration: const InputDecoration(
                labelText: 'Chọn học sinh',
                border: OutlineInputBorder(),
              ),
              items: students.map((student) {
                return DropdownMenuItem<StudentModel>(
                  value: student,
                  child: Text(student.fullName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStudent = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ClassRoomModel>(
              value: selectedClassRoom,
              decoration: const InputDecoration(
                labelText: 'Chọn lớp học',
                border: OutlineInputBorder(),
              ),
              items: classRooms.map((classRoom) {
                return DropdownMenuItem<ClassRoomModel>(
                  value: classRoom,
                  child: Text('${classRoom.className} - ${classRoom.classCode}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedClassRoom = value;
                  if (value != null) {
                    amountController.text = value.tuitionFee.toStringAsFixed(0);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: dueDateController,
              readOnly: true,
              onTap: _pickDueDate,
              decoration: const InputDecoration(
                labelText: 'Hạn đóng',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Lưu học phí'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}