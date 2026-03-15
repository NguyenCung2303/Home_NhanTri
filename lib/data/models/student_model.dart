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
      createdAt: map['created_at'],
    );
  }
}