import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/class_room_model.dart';
import '../models/user_model.dart';

class ClassRoomRepository {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  Future<List<ClassRoomModel>> getAllClassRooms() async {
    final url = Uri.parse('$_baseUrl/class_rooms?pageSize=100');

    final response = await http.get(url).timeout(
          const Duration(seconds: 15),
        );

    _throwIfFailed(response, 'Không tải được danh sách lớp');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = data['documents'] as List<dynamic>? ?? [];

    final classes = documents.map((doc) {
      final document = doc as Map<String, dynamic>;
      final name = document['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};

      return ClassRoomModel.fromFirestore(id, fields);
    }).toList();

    return classes..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<ClassRoomModel>> getClassRoomsByTeacher(String teacherId) async {
    final classes = await getAllClassRooms();

    return classes
        .where((classRoom) => classRoom.teacherId == teacherId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<ClassRoomModel>> getClassRoomsForTeacher(String teacherId) async {
    return getClassRoomsByTeacher(teacherId);
  }

  Future<ClassRoomModel?> getClassRoomById(String id) async {
    final url = Uri.parse('$_baseUrl/class_rooms/$id');

    final response = await http.get(url).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode == 404) return null;

    _throwIfFailed(response, 'Không tải được thông tin lớp');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = data['fields'] as Map<String, dynamic>? ?? {};

    return ClassRoomModel.fromFirestore(id, fields);
  }

  Future<List<UserModel>> getTeachers() async {
    final url = Uri.parse('$_baseUrl/users?pageSize=100');

    final response = await http.get(url).timeout(
          const Duration(seconds: 15),
        );

    _throwIfFailed(response, 'Không tải được danh sách giáo viên');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = data['documents'] as List<dynamic>? ?? [];

    return documents.map((doc) {
      final document = doc as Map<String, dynamic>;
      final name = document['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};

      return UserModel.fromFirestore(id, fields);
    }).where((user) {
      return user.role == 'TEACHER' && user.status == 'ACTIVE';
    }).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  Future<String?> getAssignedTeacherId(String classId) async {
    final classRoom = await getClassRoomById(classId);
    return classRoom?.teacherId;
  }

  Future<void> addClassRoom(
    ClassRoomModel classRoom, {
    String? teacherId,
    String? teacherName,
  }) async {
    final documentId = classRoom.id.trim().isEmpty
        ? _safeDocumentId('${classRoom.classCode}_${DateTime.now().millisecondsSinceEpoch}')
        : classRoom.id;

    final now = DateTime.now().toUtc().toIso8601String();

    final url = Uri.parse('$_baseUrl/class_rooms/$documentId');

    final effectiveTeacherId = teacherId ?? classRoom.teacherId ?? '';
    final effectiveTeacherName = teacherName ?? classRoom.teacherName ?? '';

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': _toFirestoreFields(
          classRoom,
          id: documentId,
          createdAt: classRoom.createdAt.isNotEmpty ? classRoom.createdAt : now,
          teacherId: effectiveTeacherId,
          teacherName: effectiveTeacherName,
        ),
      }),
    ).timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không tạo được lớp học');
  }

  Future<void> updateClassRoom(
    ClassRoomModel classRoom, {
    String? teacherId,
    String? teacherName,
  }) async {
    final effectiveTeacherId = teacherId ?? classRoom.teacherId ?? '';
    final effectiveTeacherName = teacherName ?? classRoom.teacherName ?? '';

    final url = Uri.parse('$_baseUrl/class_rooms/${classRoom.id}');

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': _toFirestoreFields(
          classRoom,
          id: classRoom.id,
          createdAt: classRoom.createdAt,
          teacherId: effectiveTeacherId,
          teacherName: effectiveTeacherName,
        ),
      }),
    ).timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không cập nhật được lớp học');
  }

  Future<void> deleteClassRoom(String id) async {
    final url = Uri.parse('$_baseUrl/class_rooms/$id');

    final response = await http.delete(url).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode == 404) return;

    _throwIfFailed(response, 'Không xóa được lớp học');
  }

  Map<String, dynamic> _toFirestoreFields(
    ClassRoomModel classRoom, {
    required String id,
    required String createdAt,
    required String teacherId,
    required String teacherName,
  }) {
    return {
      'id': {'stringValue': id},
      'classCode': {'stringValue': classRoom.classCode},
      'className': {'stringValue': classRoom.className},
      'description': {'stringValue': classRoom.description ?? ''},
      'level': {'stringValue': classRoom.level ?? ''},
      'tuitionFee': {'doubleValue': classRoom.tuitionFee},
      'maxStudents': {'integerValue': classRoom.maxStudents.toString()},
      'currentStudents': {'integerValue': classRoom.currentStudents.toString()},
      'roomName': {'stringValue': classRoom.roomName ?? ''},
      'status': {'stringValue': classRoom.status},
      'teacherId': {'stringValue': teacherId},
      'teacherName': {'stringValue': teacherName},
      'createdAt': {'timestampValue': createdAt},
    };
  }

  String _safeDocumentId(String value) {
    return value
        .replaceAll('/', '_')
        .replaceAll(' ', '_')
        .replaceAll(':', '_')
        .replaceAll('.', '_');
  }

  void _throwIfFailed(http.Response response, String message) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw Exception('$message. HTTP ${response.statusCode}: ${response.body}');
  }
}