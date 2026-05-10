class StudentTagModel {
  final String id;
  final String tagCode;
  final String tagName;
  final String? description;
  final int sortOrder;
  final String status;
  final String createdAt;
  final int studentCount;

  const StudentTagModel({
    required this.id,
    required this.tagCode,
    required this.tagName,
    this.description,
    required this.sortOrder,
    required this.status,
    required this.createdAt,
    this.studentCount = 0,
  });

  factory StudentTagModel.fromMap(Map<String, dynamic> map) {
    return StudentTagModel(
      id: map['id'] as String,
      tagCode: map['tag_code'] as String,
      tagName: map['tag_name'] as String,
      description: map['description'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      status: (map['status'] as String?) ?? 'ACTIVE',
      createdAt: (map['created_at'] as String?) ?? '',
      studentCount: (map['student_count'] as int?) ?? 0,
    );
  }
}
