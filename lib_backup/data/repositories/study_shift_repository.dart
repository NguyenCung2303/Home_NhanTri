import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/study_shift_model.dart';

class StudyShiftRepository {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  Future<List<StudyShiftModel>> getAllStudyShifts() async {
    final url = Uri.parse('$_baseUrl/study_shifts?pageSize=100');
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return [];
    _throwIfFailed(response, 'Không tải được ca học');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = data['documents'] as List<dynamic>? ?? [];
    final shifts = documents.map((doc) {
      final document = doc as Map<String, dynamic>;
      final name = document['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      return StudyShiftModel.fromFirestore(id, fields);
    }).toList();
    return shifts..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
  }

  Future<void> addStudyShift(StudyShiftModel shift) async {
    final id = shift.id.trim().isEmpty ? _safeDocumentId('${shift.shiftCode}_${DateTime.now().millisecondsSinceEpoch}') : shift.id;
    final url = Uri.parse('$_baseUrl/study_shifts/$id');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': _fields(shift)}),
    ).timeout(const Duration(seconds: 15));
    _throwIfFailed(response, 'Không thêm được ca học');
  }

  Future<void> deleteStudyShift(String id) async {
    final url = Uri.parse('$_baseUrl/study_shifts/$id');
    final response = await http.delete(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return;
    _throwIfFailed(response, 'Không xóa được ca học');
  }

  Map<String, dynamic> _fields(StudyShiftModel s) => {
        'shiftCode': {'stringValue': s.shiftCode},
        'shiftName': {'stringValue': s.shiftName},
        'dayOfWeek': {'integerValue': s.dayOfWeek.toString()},
        'startTime': {'stringValue': s.startTime},
        'endTime': {'stringValue': s.endTime},
        'note': {'stringValue': s.note ?? ''},
        'status': {'stringValue': s.status},
      };

  String _safeDocumentId(String value) => value.replaceAll('/', '_').replaceAll(' ', '_').replaceAll(':', '_').replaceAll('.', '_');
  void _throwIfFailed(http.Response response, String message) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('$message. HTTP ${response.statusCode}: ${response.body}');
  }
}
