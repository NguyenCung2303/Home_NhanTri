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
      createdAt: map['created_at'],
    );
  }
}