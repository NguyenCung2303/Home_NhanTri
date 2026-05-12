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
      id: map['id']?.toString() ?? '',
      tagCode: map['tag_code']?.toString() ?? '',
      tagName: map['tag_name']?.toString() ?? '',
      description: map['description']?.toString(),
      sortOrder: int.tryParse(map['sort_order']?.toString() ?? '') ?? 0,
      status: map['status']?.toString() ?? 'ACTIVE',
      createdAt: map['created_at']?.toString() ?? '',
      studentCount: int.tryParse(map['student_count']?.toString() ?? '') ?? 0,
    );
  }

  factory StudentTagModel.fromFirestore(
    String id,
    Map<String, dynamic> fields, {
    int studentCount = 0,
  }) {
    String str(String key) {
      final value = fields[key];
      if (value == null) return '';
      return value['stringValue']?.toString() ??
          value['integerValue']?.toString() ??
          value['timestampValue']?.toString() ??
          '';
    }

    return StudentTagModel(
      id: id,
      tagCode: str('tagCode'),
      tagName: str('tagName'),
      description: str('description').isNotEmpty ? str('description') : null,
      sortOrder: int.tryParse(str('sortOrder')) ?? 0,
      status: str('status').isNotEmpty ? str('status') : 'ACTIVE',
      createdAt: str('createdAt').isNotEmpty ? str('createdAt') : DateTime.now().toIso8601String(),
      studentCount: studentCount,
    );
  }
}
