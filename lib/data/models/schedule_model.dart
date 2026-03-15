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
      id: map['id'],
      classId: map['class_id'],
      shiftId: map['shift_id'],
      studyDate: map['study_date'],
      roomName: map['room_name'],
      lessonTopic: map['lesson_topic'],
      note: map['note'],
      status: map['status'],
    );
  }
}