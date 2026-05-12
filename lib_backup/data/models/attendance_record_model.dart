class AttendanceRecordModel {
  final String id;
  final String scheduleId;
  final String classId;
  final String studentId;
  final String attendanceDate;
  final String status;
  final String? note;
  final String createdAt;
  final String? parentUserId;
  final String? updatedAt;

  AttendanceRecordModel({
    required this.id,
    required this.scheduleId,
    required this.classId,
    required this.studentId,
    required this.attendanceDate,
    required this.status,
    this.note,
    required this.createdAt,
    this.parentUserId,
    this.updatedAt,
  });

  bool get isPresent => status == 'PRESENT';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'class_id': classId,
      'student_id': studentId,
      'attendance_date': attendanceDate,
      'status': status,
      'note': note,
      'parent_user_id': parentUserId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map) {
  return AttendanceRecordModel(
    id: map['id'] as String,
    scheduleId: map['schedule_id'] as String,
    classId: map['class_id'] as String,
    studentId: map['student_id'] as String,
    attendanceDate: map['attendance_date'] as String,
    status: map['status'] as String,
    note: map['note'] as String?,
    parentUserId: map['parent_user_id'] as String?,
    createdAt: map['created_at'] as String,
    updatedAt: map['updated_at'] as String?,
  );
}
  factory AttendanceRecordModel.fromFirestore(
  String id,
  Map<String, dynamic> fields,
) {
  String str(String key) {
    final value = fields[key];
    if (value == null) return '';

    return value['stringValue']?.toString() ??
        value['timestampValue']?.toString() ??
        '';
  }

  return AttendanceRecordModel(
    id: id,
    scheduleId: str('scheduleId'),
    classId: str('classId'),
    studentId: str('studentId'),
    attendanceDate: str('attendanceDate'),
    status: str('status'),
    note: str('note').isNotEmpty ? str('note') : null,
    
    parentUserId: str('parentUserId').isNotEmpty ? str('parentUserId') : null,
    createdAt: str('createdAt'),
    updatedAt: str('updatedAt').isNotEmpty
        ? str('updatedAt')
        : null,
  );
}
}
