class EnrollmentRequestModel {
  final String id;
  final String parentName;
  final String phone;
  final String? email;
  final String studentName;
  final String? studentBirthYear;
  final String? currentLevel;
  final String? learningGoal;
  final String? note;
  final String status;
  final String createdAt;
  final String? updatedAt;
  final String? approvedAt;
  final String? approvedBy;
  final String? parentUserId;
  final String? parentId;
  final String? studentId;
  final String? rejectionReason;
  final String? gender;
  final String? school;
  final String? grade;
  final String? lichessUsername;
  final String? address;
  final String? healthNote;

  const EnrollmentRequestModel({
    required this.id,
    required this.parentName,
    required this.phone,
    this.email,
    required this.studentName,
    this.studentBirthYear,
    this.currentLevel,
    this.learningGoal,
    this.note,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.approvedBy,
    this.parentUserId,
    this.parentId,
    this.studentId,
    this.rejectionReason,
    this.gender,
    this.school,
    this.grade,
    this.lichessUsername,
    this.address,
    this.healthNote,
  });

  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
  bool get isContacted => status == 'CONTACTED';

  String get statusText {
    switch (status) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'CONTACTED':
        return 'Đã liên hệ';
      case 'APPROVED':
        return 'Đã duyệt';
      case 'REJECTED':
        return 'Từ chối';
      default:
        return status;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_name': parentName,
      'phone': phone,
      'email': email,
      'student_name': studentName,
      'student_birth_year': studentBirthYear,
      'current_level': currentLevel,
      'learning_goal': learningGoal,
      'note': note,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'approved_at': approvedAt,
      'approved_by': approvedBy,
      'parent_user_id': parentUserId,
      'parent_id': parentId,
      'student_id': studentId,
      'rejection_reason': rejectionReason,
      'gender': gender,
      'school': school,
      'grade': grade,
      'lichess_username': lichessUsername,
      'address': address,
      'health_note': healthNote,
    };
  }

  factory EnrollmentRequestModel.fromMap(Map<String, dynamic> map) {
    return EnrollmentRequestModel(
      id: map['id']?.toString() ?? '',
      parentName: map['parent_name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString(),
      studentName: map['student_name']?.toString() ?? '',
      studentBirthYear: map['student_birth_year']?.toString(),
      currentLevel: map['current_level']?.toString(),
      learningGoal: map['learning_goal']?.toString(),
      note: map['note']?.toString(),
      status: map['status']?.toString() ?? 'PENDING',
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString(),
      approvedAt: map['approved_at']?.toString(),
      approvedBy: map['approved_by']?.toString(),
      parentUserId: map['parent_user_id']?.toString(),
      parentId: map['parent_id']?.toString(),
      studentId: map['student_id']?.toString(),
      rejectionReason: map['rejection_reason']?.toString(),
      gender: map['gender']?.toString(),
      school: map['school']?.toString(),
      grade: map['grade']?.toString(),
      lichessUsername: map['lichess_username']?.toString(),
      address: map['address']?.toString(),
      healthNote: map['health_note']?.toString(),
    );
  }
}
