import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/todo_item.dart';

class AddTodoScreen extends StatefulWidget {
  final DateTime initialDate;

  const AddTodoScreen({
    super.key,
    required this.initialDate,
  });

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _titleCtrl = TextEditingController();
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3F3F3F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F3F3F),
        elevation: 0,
        title: const Text('Thêm việc cần làm'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Việc cần làm',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF4A4A4A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chọn ngày
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: const Color(0xFF4A4A4A),
              leading: const Icon(Icons.calendar_today, color: Colors.white70),
              title: Text(
                '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: _pickDate,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE85B7A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _save,
                child: const Text(
                  'Lưu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _dueDate,
    );
    if (d != null) {
      setState(() => _dueDate = d);
    }
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;

    Navigator.pop(
      context,
      TodoItem(
        id: const Uuid().v4(),
        title: _titleCtrl.text.trim(),
        dueDate: _dueDate,
        completed: false,
      ),
    );
  }
}
