import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class TodoCalendarScreen extends StatefulWidget {
  const TodoCalendarScreen({super.key});

  @override
  State<TodoCalendarScreen> createState() => _TodoCalendarScreenState();
}

class _TodoCalendarScreenState extends State<TodoCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // MOCK DATA
  final Map<String, List<String>> _events = {
    '2024-07-10': ['Họp ban quản trị', 'Kiểm tra tiến độ dự án'],
  };

  final Map<String, List<String>> _todos = {
    '2024-07-10': ['Hoàn thành báo cáo', 'Gửi email cho khách hàng'],
  };

  @override
  Widget build(BuildContext context) {
    final key = _keyOf(_selectedDay);

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
                _Section(
                  title: 'Sự kiện',
                  items: _events[key] ?? [],
                  icon: Icons.event,
                ),
                const SizedBox(height: 16),
                _TodoSection(
                  todos: _todos[key] ?? [],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE83E8C),
        icon: const Icon(Icons.add),
        label: const Text('Thêm sự kiện'),
        onPressed: () {},
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
        defaultTextStyle: const TextStyle(color: Colors.white),
        weekendTextStyle: const TextStyle(color: Colors.white70),
      ),
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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

  String _keyOf(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}


class _Section extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;

  const _Section({
    required this.title,
    required this.items,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (e) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: Colors.white70),
            title: Text(e, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
class _TodoSection extends StatelessWidget {
  final List<String> todos;

  const _TodoSection({required this.todos});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Todo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...todos.map(
          (t) => CheckboxListTile(
            value: false,
            onChanged: (_) {},
            activeColor: Colors.pink,
            title:
                Text(t, style: const TextStyle(color: Colors.white)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
