class StudentModel {
  final String id;
  final String fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? school;
  final String? grade;
  final String? address;
  final String? healthNote;
  final String? joinDate;
  final String status;
  final String? avatarUrl;
  final String? note;
  final String? classId;
  final String? lichessUsername;
  final String createdAt;
  

  StudentModel({
    required this.id,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.school,
    this.grade,
    this.address,
    this.healthNote,
    this.joinDate,
    required this.status,
    this.avatarUrl,
    this.note,
    this.classId,
    this.lichessUsername,
    required this.createdAt,

  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'school': school,
      'grade': grade,
      'address': address,
      'health_note': healthNote,
      'join_date': joinDate,
      'status': status,
      'avatar_url': avatarUrl,
      'note': note,
      'class_id': classId,
      'lichess_username': lichessUsername,
      'created_at': createdAt,
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'],
      fullName: map['full_name'],
      dateOfBirth: map['date_of_birth'],
      gender: map['gender'],
      school: map['school'],
      grade: map['grade'],
      address: map['address'],
      healthNote: map['health_note'],
      joinDate: map['join_date'],
      status: map['status'],
      avatarUrl: map['avatar_url'],
      note: map['note'],
      classId: map['class_id'],
      lichessUsername: map['lichess_username'],
      createdAt: map['created_at'],
    );
  }

factory StudentModel.fromFirestore(String id, Map<String, dynamic> fields) {
  String str(String key) {
    final value = fields[key];
    if (value == null) return '';

    return value['stringValue']?.toString() ??
        value['integerValue']?.toString() ??
        value['booleanValue']?.toString() ??
        value['timestampValue']?.toString() ??
        
        '';
  }

  return StudentModel(
    id: id,
    fullName: str('fullName').isNotEmpty ? str('fullName') : str('studentName'),
    dateOfBirth: str('dateOfBirth').isNotEmpty ? str('dateOfBirth') : null,
    gender: str('gender').isNotEmpty ? str('gender') : null,
    school: str('school').isNotEmpty ? str('school') : null,
    grade: str('grade').isNotEmpty ? str('grade') : null,
    address: str('address').isNotEmpty ? str('address') : null,
    healthNote: str('healthNote').isNotEmpty ? str('healthNote') : null,
    joinDate: str('joinDate').isNotEmpty ? str('joinDate') : null,
    status: str('status').isNotEmpty ? str('status') : 'ACTIVE',
    avatarUrl: str('avatarUrl').isNotEmpty ? str('avatarUrl') : null,
    note: str('note').isNotEmpty ? str('note') : null,
    classId: str('classId').isNotEmpty ? str('classId') : null,
    lichessUsername: str('lichessUsername').isNotEmpty ? str('lichessUsername') : null,
    createdAt: str('createdAt').isNotEmpty ? str('createdAt') : DateTime.now().toIso8601String(),
  );
}
  StudentModel copyWith({
    String? id,
    String? fullName,
    String? dateOfBirth,
    String? gender,
    String? school,
    String? grade,
    String? address,
    String? healthNote,
    String? joinDate,
    String? status,
    String? avatarUrl,
    String? note,
    String? classId,
    String? lichessUsername,
    String? createdAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      school: school ?? this.school,
      grade: grade ?? this.grade,
      address: address ?? this.address,
      healthNote: healthNote ?? this.healthNote,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      note: note ?? this.note,
      classId: classId ?? this.classId,
      lichessUsername: lichessUsername ?? this.lichessUsername,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
