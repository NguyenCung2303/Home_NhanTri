import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Checkbox(
            value: todo.completed,
            onChanged: (v) => onChanged(v!),
            activeColor: AppColors.accent,
          ),
          Expanded(
            child: Text(
              todo.title,
              style: TextStyle(
                color: AppColors.textPrimary,
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
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
