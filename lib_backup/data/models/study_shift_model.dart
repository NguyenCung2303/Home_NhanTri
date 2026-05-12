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
      id: map['id']?.toString() ?? '',
      shiftCode: map['shift_code']?.toString() ?? '',
      shiftName: map['shift_name']?.toString() ?? '',
      dayOfWeek: int.tryParse(map['day_of_week']?.toString() ?? '') ?? 1,
      startTime: map['start_time']?.toString() ?? '',
      endTime: map['end_time']?.toString() ?? '',
      note: map['note']?.toString(),
      status: map['status']?.toString() ?? 'ACTIVE',
    );
  }

  factory StudyShiftModel.fromFirestore(String id, Map<String, dynamic> fields) {
    String str(String key) {
      final value = fields[key];
      if (value == null) return '';
      return value['stringValue']?.toString() ??
          value['integerValue']?.toString() ??
          value['timestampValue']?.toString() ??
          '';
    }

    return StudyShiftModel(
      id: id,
      shiftCode: str('shiftCode'),
      shiftName: str('shiftName'),
      dayOfWeek: int.tryParse(str('dayOfWeek')) ?? 1,
      startTime: str('startTime'),
      endTime: str('endTime'),
      note: str('note').isNotEmpty ? str('note') : null,
      status: str('status').isNotEmpty ? str('status') : 'ACTIVE',
    );
  }
}
