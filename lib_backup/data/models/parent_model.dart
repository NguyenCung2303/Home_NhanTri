class ParentModel {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final String? email;
  final String? address;
  final String? relationshipToStudent;
  final String? note;
  final String createdAt;

  ParentModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    this.email,
    this.address,
    this.relationshipToStudent,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'address': address,
      'relationship_to_student': relationshipToStudent,
      'note': note,
      'created_at': createdAt,
    };
  }

  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      fullName: map['full_name']?.toString() ?? '',
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      address: map['address']?.toString(),
      relationshipToStudent: map['relationship_to_student']?.toString(),
      note: map['note']?.toString(),
      createdAt: map['created_at']?.toString() ?? '',
    );
  }

  factory ParentModel.fromFirestore(String id, Map<String, dynamic> fields) {
    String str(String key) {
      final value = fields[key];
      if (value == null) return '';
      return value['stringValue']?.toString() ??
          value['timestampValue']?.toString() ??
          '';
    }

    return ParentModel(
      id: id,
      userId: str('userId').isNotEmpty ? str('userId') : str('user_id'),
      fullName: str('fullName').isNotEmpty ? str('fullName') : str('full_name'),
      phone: str('phone').isNotEmpty ? str('phone') : null,
      email: str('email').isNotEmpty ? str('email') : null,
      address: str('address').isNotEmpty ? str('address') : null,
      relationshipToStudent: str('relationshipToStudent').isNotEmpty
          ? str('relationshipToStudent')
          : (str('relationship_to_student').isNotEmpty ? str('relationship_to_student') : null),
      note: str('note').isNotEmpty ? str('note') : null,
      createdAt: str('createdAt').isNotEmpty
          ? str('createdAt')
          : (str('created_at').isNotEmpty ? str('created_at') : DateTime.now().toIso8601String()),
    );
  }
}
