import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/parent_model.dart';
import '../models/student_model.dart';
import 'student_repository.dart';

class ParentRepository {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  final StudentRepository _studentRepository = StudentRepository();

  Future<List<ParentModel>> getAllParents() async {
    final url = Uri.parse('$_baseUrl/parents?pageSize=200');
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return [];
    _throwIfFailed(response, 'Không tải được danh sách phụ huynh');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = data['documents'] as List<dynamic>? ?? [];
    final parents = documents.map((doc) {
      final document = doc as Map<String, dynamic>;
      final name = document['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      return ParentModel.fromFirestore(id, fields);
    }).toList();
    return parents..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addParent(ParentModel parent) async {
    final documentId = parent.id.trim().isEmpty
        ? _safeDocumentId('${parent.phone ?? parent.fullName}_${DateTime.now().millisecondsSinceEpoch}')
        : parent.id;
    final url = Uri.parse('$_baseUrl/parents/$documentId');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': _parentFields(parent, id: documentId)}),
    ).timeout(const Duration(seconds: 15));
    _throwIfFailed(response, 'Không thêm được phụ huynh');
  }

  Future<void> deleteParent(String id) async {
    final url = Uri.parse('$_baseUrl/parents/$id');
    final response = await http.delete(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return;
    _throwIfFailed(response, 'Không xóa được phụ huynh');
  }

  Future<List<StudentModel>> getStudentsByParent(String parentId) async {
    final docs = await _getStudentDocs();
    return docs
        .where((doc) => doc.str('parentId') == parentId || doc.str('parent_id') == parentId)
        .map((doc) => doc.student)
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  Future<List<StudentModel>> getAvailableStudentsForParent(String parentId) async {
    final docs = await _getStudentDocs();
    return docs
        .where((doc) => doc.str('parentId').isEmpty && doc.str('parent_id').isEmpty)
        .map((doc) => doc.student)
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  Future<void> assignStudentsToParent(String parentId, List<String> studentIds) async {
    final parents = await getAllParents();
    ParentModel? parent;
    for (final p in parents) {
      if (p.id == parentId) {
        parent = p;
        break;
      }
    }

    for (final studentId in studentIds) {
      final fields = <String, dynamic>{
        'parentId': {'stringValue': parentId},
      };
      final masks = ['parentId'];
      if (parent != null) {
        fields['parentUserId'] = {'stringValue': parent.userId};
        fields['parentName'] = {'stringValue': parent.fullName};
        fields['parentPhone'] = {'stringValue': parent.phone ?? ''};
        masks.addAll(['parentUserId', 'parentName', 'parentPhone']);
      }
      await _patchStudent(studentId, fields, masks);
    }
  }

  Future<void> removeStudentFromParent(String parentId, String studentId) async {
    await _patchStudent(studentId, {
      'parentId': {'stringValue': ''},
      'parentUserId': {'stringValue': ''},
    }, ['parentId', 'parentUserId']);
  }

  Future<List<_StudentDoc>> _getStudentDocs() async {
    final url = Uri.parse('$_baseUrl/students?pageSize=500');
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return [];
    _throwIfFailed(response, 'Không tải được danh sách học sinh');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = data['documents'] as List<dynamic>? ?? [];
    return documents.map((doc) {
      final document = doc as Map<String, dynamic>;
      final name = document['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      return _StudentDoc(id, fields);
    }).toList();
  }

  Future<void> _patchStudent(String studentId, Map<String, dynamic> fields, List<String> masks) async {
    final mask = masks.map((e) => 'updateMask.fieldPaths=$e').join('&');
    final url = Uri.parse('$_baseUrl/students/$studentId?$mask');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': fields}),
    ).timeout(const Duration(seconds: 15));
    _throwIfFailed(response, 'Không cập nhật phụ huynh cho học sinh');
  }

  Map<String, dynamic> _parentFields(ParentModel p, {required String id}) => {
        'id': {'stringValue': id},
        'userId': {'stringValue': p.userId},
        'fullName': {'stringValue': p.fullName},
        'phone': {'stringValue': p.phone ?? ''},
        'email': {'stringValue': p.email ?? ''},
        'address': {'stringValue': p.address ?? ''},
        'relationshipToStudent': {'stringValue': p.relationshipToStudent ?? ''},
        'note': {'stringValue': p.note ?? ''},
        'createdAt': {'stringValue': p.createdAt},
      };

  String _safeDocumentId(String value) => value.replaceAll('/', '_').replaceAll(' ', '_').replaceAll(':', '_').replaceAll('.', '_');

  void _throwIfFailed(http.Response response, String message) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('$message. HTTP ${response.statusCode}: ${response.body}');
  }
}

class _StudentDoc {
  final String id;
  final Map<String, dynamic> fields;
  _StudentDoc(this.id, this.fields);
  StudentModel get student => StudentModel.fromFirestore(id, fields);
  String str(String key) {
    final value = fields[key];
    if (value == null) return '';
    return value['stringValue']?.toString() ?? value['timestampValue']?.toString() ?? value['integerValue']?.toString() ?? '';
  }
}
