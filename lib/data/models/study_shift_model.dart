class StudyShiftModel {
  final String id;
  final String shiftCode;
  final String shiftName;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? note;
  final String status;

  StudyShiftModel({
    required this.id,
    required this.shiftCode,
    required this.shiftName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.note,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shift_code': shiftCode,
      'shift_name': shiftName,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'note': note,
      'status': status,
    };
  }

  factory StudyShiftModel.fromMap(Map<String, dynamic> map) {
    return StudyShiftModel(
      id: map['id'],
      shiftCode: map['shift_code'],
      shiftName: map['shift_name'],
      dayOfWeek: map['day_of_week'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      note: map['note'],
      status: map['status'],
    );
  }
}