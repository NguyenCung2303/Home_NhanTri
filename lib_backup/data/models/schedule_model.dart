class ScheduleModel {
  final String id;
  final String classId;
  final String shiftId;
  final String studyDate;
  final String? roomName;
  final String? lessonTopic;
  final String? note;
  final String status;

  ScheduleModel({
    required this.id,
    required this.classId,
    required this.shiftId,
    required this.studyDate,
    this.roomName,
    this.lessonTopic,
    this.note,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'class_id': classId,
      'shift_id': shiftId,
      'study_date': studyDate,
      'room_name': roomName,
      'lesson_topic': lessonTopic,
      'note': note,
      'status': status,
    };
  }

  factory ScheduleModel.fromMap(Map<String, dynamic> map) {
    return ScheduleModel(
      id: map['id']?.toString() ?? '',
      classId: map['class_id']?.toString() ?? '',
      shiftId: map['shift_id']?.toString() ?? '',
      studyDate: map['study_date']?.toString() ?? '',
      roomName: map['room_name']?.toString(),
      lessonTopic: map['lesson_topic']?.toString(),
      note: map['note']?.toString(),
      status: map['status']?.toString() ?? 'ACTIVE',
    );
  }

  factory ScheduleModel.fromFirestore(String id, Map<String, dynamic> fields) {
    String str(String key) {
      final value = fields[key];
      if (value == null) return '';
      return value['stringValue']?.toString() ?? value['timestampValue']?.toString() ?? '';
    }

    return ScheduleModel(
      id: id,
      classId: str('classId'),
      shiftId: str('shiftId'),
      studyDate: str('studyDate'),
      roomName: str('roomName').isNotEmpty ? str('roomName') : null,
      lessonTopic: str('lessonTopic').isNotEmpty ? str('lessonTopic') : null,
      note: str('note').isNotEmpty ? str('note') : null,
      status: str('status').isNotEmpty ? str('status') : 'ACTIVE',
    );
  }
}
