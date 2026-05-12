class ClassRoomModel {
  final String id;
  final String classCode;
  final String className;
  final String? description;
  final String? level;
  final double tuitionFee;
  final int maxStudents;
  final int currentStudents;
  final String? roomName;
  final String status;
  final String? teacherId;
  final String? teacherName;
  final String createdAt;

  ClassRoomModel({
  required this.id,
  required this.classCode,
  required this.className,
  this.description,
  this.level,
  required this.tuitionFee,
  required this.maxStudents,
  required this.currentStudents,
  this.roomName,
  required this.status,
  this.teacherId,
  this.teacherName,
  required this.createdAt,
});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_code': classCode,
      'class_name': className,
      'description': description,
      'level': level,
      'tuition_fee': tuitionFee,
      'max_students': maxStudents,
      'current_students': currentStudents,
      'room_name': roomName,
      'status': status,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'created_at': createdAt,
    };
  }

  factory ClassRoomModel.fromMap(Map<String, dynamic> map) {
    return ClassRoomModel(
      id: map['id'],
      classCode: map['class_code'],
      className: map['class_name'],
      description: map['description'],
      level: map['level'],
      tuitionFee: (map['tuition_fee'] as num).toDouble(),
      maxStudents: map['max_students'],
      currentStudents: map['current_students'],
      roomName: map['room_name'],
      status: map['status'],
      teacherId: map['teacher_id'],
      teacherName: map['teacher_name'],
      createdAt: map['created_at'],
    );
  }
  factory ClassRoomModel.fromFirestore(
  String id,
  Map<String, dynamic> fields,
) {
  String str(String key) {
    final value = fields[key];
    if (value == null) return '';

    return value['stringValue']?.toString() ??
        value['integerValue']?.toString() ??
        value['doubleValue']?.toString() ??
        value['timestampValue']?.toString() ??
        '';
  }

  int intValue(String key) => int.tryParse(str(key)) ?? 0;
  double doubleValue(String key) => double.tryParse(str(key)) ?? 0;

  return ClassRoomModel(
    id: id,
    classCode: str('classCode'),
    className: str('className'),
    description: str('description').isNotEmpty ? str('description') : null,
    level: str('level').isNotEmpty ? str('level') : null,
    tuitionFee: doubleValue('tuitionFee'),
    maxStudents: intValue('maxStudents'),
    currentStudents: intValue('currentStudents'),
    roomName: str('roomName').isNotEmpty ? str('roomName') : null,
    status: str('status').isNotEmpty ? str('status') : 'ACTIVE',
    teacherId: str('teacherId').isNotEmpty ? str('teacherId') : null,
    teacherName: str('teacherName').isNotEmpty ? str('teacherName') : null,
    createdAt: str('createdAt').isNotEmpty
        ? str('createdAt')
        : DateTime.now().toIso8601String(),
  );
}
}