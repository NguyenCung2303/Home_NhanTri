import 'package:flutter/material.dart';

import '../../data/models/student_model.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../theme/app_colors.dart';

enum AttendanceMode { classRoom, tag }

class TeacherAttendanceScreen extends StatefulWidget {
  final String classId;
  final String className;
  final AttendanceMode attendanceMode;

  const TeacherAttendanceScreen({
    super.key,
    required this.classId,
    required this.className,
    this.attendanceMode = AttendanceMode.classRoom,
  });

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final TextEditingController _searchController = TextEditingController();

  List<StudentModel> _students = [];
  final Map<String, Map<String, bool>> _monthPresentMap = {};
  final Set<String> _dirtyDates = {};

  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  String _searchText = '';
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isTagMode => widget.attendanceMode == AttendanceMode.tag;

  String get _groupId => _isTagMode ? 'TAG_${widget.classId}' : widget.classId;

  String get _selectedDateKey => _dateKey(_selectedDate);

  int get _daysInMonth => DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);

  List<StudentModel> get _filteredStudents {
    final keyword = _searchText.trim().toLowerCase();
    if (keyword.isEmpty) return _students;
    return _students.where((student) => student.fullName.toLowerCase().contains(keyword)).toList();
  }

  int get _selectedPresentCount {
    final dayMap = _monthPresentMap[_selectedDateKey] ?? {};
    return _students.where((student) => dayMap[student.id] == true).length;
  }

  int get _selectedAbsentCount => _students.length - _selectedPresentCount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final students = _isTagMode
        ? await _attendanceRepository.getStudentsForTag(widget.classId)
        : await _attendanceRepository.getStudentsForClass(widget.classId);

    final records = await _attendanceRepository.getAttendanceForGroupInMonth(
      classId: _groupId,
      year: _currentMonth.year,
      month: _currentMonth.month,
    );

    final map = <String, Map<String, bool>>{};
    for (int day = 1; day <= _daysInMonth; day++) {
      final key = _dateKey(DateTime(_currentMonth.year, _currentMonth.month, day));
      map[key] = {for (final student in students) student.id: false};
    }

    for (final record in records) {
      map.putIfAbsent(record.attendanceDate, () => <String, bool>{});
      map[record.attendanceDate]![record.studentId] = record.isPresent;
    }

    if (!mounted) return;
    setState(() {
      _students = students;
      _monthPresentMap
        ..clear()
        ..addAll(map);
      _dirtyDates.clear();
      _isLoading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
      helpText: 'Chọn ngày điểm danh',
    );

    if (picked == null) return;

    final needReload = picked.year != _currentMonth.year || picked.month != _currentMonth.month;
    setState(() {
      _selectedDate = picked;
      _currentMonth = DateTime(picked.year, picked.month);
    });

    if (needReload) await _loadData();
  }

  Future<void> _changeMonth(int delta) async {
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    final nextDay = _selectedDate.day.clamp(1, DateUtils.getDaysInMonth(nextMonth.year, nextMonth.month)) as int;
    setState(() {
      _currentMonth = nextMonth;
      _selectedDate = DateTime(nextMonth.year, nextMonth.month, nextDay);
    });
    await _loadData();
  }

  void _toggleAttendance(String studentId, int day) {
    final date = DateTime(_currentMonth.year, _currentMonth.month, day);
    final dateKey = _dateKey(date);
    final dayMap = _monthPresentMap.putIfAbsent(dateKey, () => <String, bool>{});

    setState(() {
      dayMap[studentId] = !(dayMap[studentId] ?? false);
      _selectedDate = date;
      _dirtyDates.add(dateKey);
    });
  }

  Future<void> _saveAttendance() async {
    if (_dirtyDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có thay đổi điểm danh để lưu')),
      );
      return;
    }

    setState(() => _isSaving = true);

    for (final dateKey in _dirtyDates.toList()) {
      final dayMap = _monthPresentMap[dateKey] ?? {};
      final studentPresentMap = {for (final student in _students) student.id: dayMap[student.id] ?? false};

      if (_isTagMode) {
        await _attendanceRepository.saveTagAttendance(
          tagId: widget.classId,
          attendanceDate: dateKey,
          studentPresentMap: studentPresentMap,
        );
      } else {
        await _attendanceRepository.saveAttendance(
          classId: widget.classId,
          attendanceDate: dateKey,
          studentPresentMap: studentPresentMap,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _dirtyDates.clear();
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu bảng điểm danh theo tháng')),
    );
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _monthText(DateTime date) => 'Tháng ${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(_isTagMode ? 'Điểm danh nhóm · ${widget.className}' : 'Điểm danh lớp · ${widget.className}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _isTagMode ? 'Nhóm này chưa có học sinh để điểm danh' : 'Lớp này chưa có học sinh để điểm danh',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              : Column(
                  children: [
                    _HeaderCard(
                      monthText: _monthText(_currentMonth),
                      selectedDate: _selectedDateKey,
                      presentCount: _selectedPresentCount,
                      absentCount: _selectedAbsentCount,
                      dirtyCount: _dirtyDates.length,
                      onPrevMonth: () => _changeMonth(-1),
                      onNextMonth: () => _changeMonth(1),
                      onPickDate: _pickDate,
                      searchController: _searchController,
                      onSearchChanged: (value) => setState(() => _searchText = value),
                    ),
                    Expanded(
                      child: _AttendanceSheet(
                        students: _filteredStudents,
                        daysInMonth: _daysInMonth,
                        selectedDay: _selectedDate.day,
                        monthPresentMap: _monthPresentMap,
                        currentMonth: _currentMonth,
                        onToggle: _toggleAttendance,
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: (_isLoading || _isSaving || _students.isEmpty) ? null : _saveAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            icon: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, color: Colors.white),
            label: Text(
              _dirtyDates.isEmpty ? 'Lưu điểm danh' : 'Lưu ${_dirtyDates.length} ngày đã sửa',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String monthText;
  final String selectedDate;
  final int presentCount;
  final int absentCount;
  final int dirtyCount;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onPickDate;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const _HeaderCard({
    required this.monthText,
    required this.selectedDate,
    required this.presentCount,
    required this.absentCount,
    required this.dirtyCount,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onPickDate,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: onPrevMonth, icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: Text(
                  monthText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
              IconButton(onPressed: onNextMonth, icon: const Icon(Icons.chevron_right)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text('Ngày: $selectedDate'),
                ),
              ),
              const SizedBox(width: 10),
              _MiniStat(label: 'Có mặt', value: presentCount.toString(), color: AppColors.success),
              const SizedBox(width: 8),
              _MiniStat(label: 'Vắng', value: absentCount.toString(), color: AppColors.danger),
            ],
          ),
          if (dirtyCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Có $dirtyCount ngày đã chỉnh sửa, nhớ bấm lưu để ghi vào hệ thống.',
              style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm tên học sinh để điểm danh nhanh',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.accent)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bấm vào ô ngày để tích X. Cột tên học sinh được giữ cố định, phần ngày có thể kéo ngang như bảng điểm danh theo tháng.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.3, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSheet extends StatefulWidget {
  final List<StudentModel> students;
  final int daysInMonth;
  final int selectedDay;
  final Map<String, Map<String, bool>> monthPresentMap;
  final DateTime currentMonth;
  final void Function(String studentId, int day) onToggle;

  const _AttendanceSheet({
    required this.students,
    required this.daysInMonth,
    required this.selectedDay,
    required this.monthPresentMap,
    required this.currentMonth,
    required this.onToggle,
  });

  @override
  State<_AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends State<_AttendanceSheet> {
  static const double _indexWidth = 44;
  static const double _nameWidth = 146;
  static const double _dayWidth = 38;
  static const double _headerHeight = 46;
  static const double _rowHeight = 48;

  final ScrollController _nameVerticalController = ScrollController();
  final ScrollController _daysVerticalController = ScrollController();
  bool _syncingScroll = false;

  @override
  void dispose() {
    _nameVerticalController.dispose();
    _daysVerticalController.dispose();
    super.dispose();
  }

  String _dateKey(int day) {
    final month = widget.currentMonth.month.toString().padLeft(2, '0');
    final dayText = day.toString().padLeft(2, '0');
    return '${widget.currentMonth.year}-$month-$dayText';
  }

  bool _syncVerticalScroll(ScrollNotification notification, ScrollController targetController) {
    if (_syncingScroll || !targetController.hasClients) return false;
    if (notification.metrics.axis != Axis.vertical) return false;

    _syncingScroll = true;
    final max = targetController.position.maxScrollExtent;
    final offset = notification.metrics.pixels.clamp(0.0, max);
    targetController.jumpTo(offset);
    _syncingScroll = false;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final daysWidth = widget.daysInMonth * _dayWidth;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: widget.students.isEmpty
            ? const Center(
                child: Text('Không tìm thấy học sinh phù hợp', style: TextStyle(color: AppColors.textSecondary)),
              )
            : Row(
                children: [
                  SizedBox(
                    width: _indexWidth + _nameWidth,
                    child: Column(
                      children: [
                        const _FixedNameHeader(
                          indexWidth: _indexWidth,
                          nameWidth: _nameWidth,
                          headerHeight: _headerHeight,
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) => _syncVerticalScroll(notification, _daysVerticalController),
                            child: ListView.separated(
                              controller: _nameVerticalController,
                              itemCount: widget.students.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                              itemBuilder: (_, index) {
                                final student = widget.students[index];
                                return _FixedNameCell(
                                  index: index + 1,
                                  student: student,
                                  indexWidth: _indexWidth,
                                  nameWidth: _nameWidth,
                                  rowHeight: _rowHeight,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: daysWidth,
                        child: Column(
                          children: [
                            _DaysHeader(
                              daysInMonth: widget.daysInMonth,
                              selectedDay: widget.selectedDay,
                              dayWidth: _dayWidth,
                              headerHeight: _headerHeight,
                            ),
                            const Divider(height: 1, color: AppColors.border),
                            Expanded(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) => _syncVerticalScroll(notification, _nameVerticalController),
                                child: ListView.separated(
                                  controller: _daysVerticalController,
                                  itemCount: widget.students.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                                  itemBuilder: (_, index) {
                                    final student = widget.students[index];
                                    return _DaysCellRow(
                                      daysInMonth: widget.daysInMonth,
                                      selectedDay: widget.selectedDay,
                                      dayWidth: _dayWidth,
                                      rowHeight: _rowHeight,
                                      isPresent: (day) => widget.monthPresentMap[_dateKey(day)]?[student.id] == true,
                                      onToggle: (day) => widget.onToggle(student.id, day),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _FixedNameHeader extends StatelessWidget {
  final double indexWidth;
  final double nameWidth;
  final double headerHeight;

  const _FixedNameHeader({
    required this.indexWidth,
    required this.nameWidth,
    required this.headerHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: headerHeight,
      color: AppColors.accentSoft,
      child: Row(
        children: [
          SizedBox(
            width: indexWidth,
            child: const Center(
              child: Text('STT', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          SizedBox(
            width: nameWidth,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Họ và tên HS', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FixedNameCell extends StatelessWidget {
  final int index;
  final StudentModel student;
  final double indexWidth;
  final double nameWidth;
  final double rowHeight;

  const _FixedNameCell({
    required this.index,
    required this.student,
    required this.indexWidth,
    required this.nameWidth,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: indexWidth,
            child: Center(
              child: Text('$index', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          SizedBox(
            width: nameWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  student.fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaysHeader extends StatelessWidget {
  final int daysInMonth;
  final int selectedDay;
  final double dayWidth;
  final double headerHeight;

  const _DaysHeader({
    required this.daysInMonth,
    required this.selectedDay,
    required this.dayWidth,
    required this.headerHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: headerHeight,
      color: AppColors.accentSoft,
      child: Row(
        children: [
          for (int day = 1; day <= daysInMonth; day++)
            Container(
              width: dayWidth,
              decoration: BoxDecoration(
                color: day == selectedDay ? AppColors.accent.withOpacity(0.16) : null,
                border: const Border(left: BorderSide(color: AppColors.border)),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: day == selectedDay ? AppColors.accent : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DaysCellRow extends StatelessWidget {
  final int daysInMonth;
  final int selectedDay;
  final double dayWidth;
  final double rowHeight;
  final bool Function(int day) isPresent;
  final ValueChanged<int> onToggle;

  const _DaysCellRow({
    required this.daysInMonth,
    required this.selectedDay,
    required this.dayWidth,
    required this.rowHeight,
    required this.isPresent,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          for (int day = 1; day <= daysInMonth; day++)
            InkWell(
              onTap: () => onToggle(day),
              child: Container(
                width: dayWidth,
                height: rowHeight,
                decoration: BoxDecoration(
                  color: day == selectedDay ? AppColors.accent.withOpacity(0.08) : null,
                  border: const Border(left: BorderSide(color: AppColors.border)),
                ),
                child: Center(
                  child: isPresent(day)
                      ? const Text('x', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w900, fontSize: 16))
                      : const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
