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
      id: map['id'],
      userId: map['user_id'],
      fullName: map['full_name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      relationshipToStudent: map['relationship_to_student'],
      note: map['note'],
      createdAt: map['created_at'],
    );
  }
}