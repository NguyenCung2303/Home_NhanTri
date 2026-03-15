import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/todo_item.dart';
import 'add_todo_screen.dart';

class TodoHomeScreen extends StatefulWidget {
  const TodoHomeScreen({super.key});

  @override
  State<TodoHomeScreen> createState() => _TodoHomeScreenState();
}

class _TodoHomeScreenState extends State<TodoHomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final List<TodoItem> _todos = [];

  @override
  Widget build(BuildContext context) {
    final todosOfDay = _todos.where((t) {
      if (t.dueDate == null) return false;
      return isSameDay(t.dueDate, _selectedDay);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF2B1E24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B1E24),
        elevation: 0,
        title: const Text('Thời gian biểu'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCalendar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionTitle('Todo'),
                ...todosOfDay.map(
                  (t) => _TodoItem(
                    todo: t,
                    onChanged: (v) =>
                        setState(() => t.completed = v),
                  ),
                ),
                if (todosOfDay.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Không có việc nào trong ngày',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE83E8C),
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc'),
        onPressed: () async {
          final result = await Navigator.push<TodoItem>(
            context,
            MaterialPageRoute(
              builder: (_) => AddTodoScreen(
                initialDate: _selectedDay,
              ),
            ),
          );

          if (result != null) {
            setState(() => _todos.add(result));
          }
        },
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020),
      lastDay: DateTime.utc(2030),
      focusedDay: _focusedDay,
      selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = selected;
          _focusedDay = focused;
        });
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.pinkAccent.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.pink,
          shape: BoxShape.circle,
        ),
        defaultTextStyle:
            const TextStyle(color: Colors.white),
        weekendTextStyle:
            const TextStyle(color: Colors.white70),
      ),
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        leftChevronIcon:
            Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon:
            Icon(Icons.chevron_right, color: Colors.white),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Colors.white70),
        weekendStyle: TextStyle(color: Colors.white70),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _TodoItem extends StatelessWidget {
  final TodoItem todo;
  final ValueChanged<bool> onChanged;

  const _TodoItem({
    required this.todo,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: todo.completed,
      onChanged: (v) => onChanged(v!),
      activeColor: Colors.pink,
      title: Text(
        todo.title,
        style: TextStyle(
          color: Colors.white,
          decoration:
              todo.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}
