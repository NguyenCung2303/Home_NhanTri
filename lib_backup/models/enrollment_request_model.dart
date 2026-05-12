class EnrollmentRequestModel {
  final String id;
  final String parentName;
  final String phone;
  final String? email;
  final String studentName;
  final String? birthYear;
  final String? level;
  final String? note;
  final String status;
  final String? rejectReason;
  final String? createdAt;
  final String? updatedAt;

  EnrollmentRequestModel({
    required this.id,
    required this.parentName,
    required this.phone,
    this.email,
    required this.studentName,
    this.birthYear,
    this.level,
    this.note,
    required this.status,
    this.rejectReason,
    this.createdAt,
    this.updatedAt,
  });

  factory EnrollmentRequestModel.fromMap(Map<String, dynamic> map) {
    return EnrollmentRequestModel(
      id: map['id']?.toString() ?? '',
      parentName: map['parent_name']?.toString() ?? map['parentName']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString(),
      studentName: map['student_name']?.toString() ?? map['studentName']?.toString() ?? '',
      birthYear: map['birth_year']?.toString() ?? map['birthYear']?.toString(),
      level: map['level']?.toString(),
      note: map['note']?.toString(),
      status: map['status']?.toString() ?? 'PENDING',
      rejectReason: map['reject_reason']?.toString() ?? map['rejectReason']?.toString(),
      createdAt: map['created_at']?.toString() ?? map['createdAt']?.toString(),
      updatedAt: map['updated_at']?.toString() ?? map['updatedAt']?.toString(),
    );
  }
}