class UserModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final String passwordHash;
  final String role;
  final String status;
  final String createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.passwordHash,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'password_hash': passwordHash,
      'role': role,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      fullName: map['full_name'],
      phone: map['phone'],
      email: map['email'],
      passwordHash: map['password_hash'],
      role: map['role'],
      status: map['status'],
      createdAt: map['created_at'],
    );
  }
}