import 'package:flutter/material.dart';
import '../models/todo_item.dart';

class TodoTile extends StatelessWidget {
  final TodoItem todo;
  final ValueChanged<bool> onChanged;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4A4A4A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Checkbox(
            value: todo.completed,
            onChanged: (v) => onChanged(v!),
            activeColor: const Color(0xFFE85B7A),
          ),
          Expanded(
            child: Text(
              todo.title,
              style: TextStyle(
                color: Colors.white,
                decoration: todo.completed
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          if (todo.dueDate != null)
            Text(
              '${todo.dueDate!.day}/${todo.dueDate!.month}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
