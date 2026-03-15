class TodoItem {
  final String id;
  String title;
  bool completed;
  DateTime? dueDate;
  String note;

  TodoItem({
    required this.id,
    required this.title,
    this.completed = false,
    this.dueDate,
    this.note = '',
  });
}
