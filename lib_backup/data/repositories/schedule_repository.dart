import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/schedule_model.dart';

class ScheduleRepository {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  Future<List<ScheduleModel>> getAllSchedules() async {
    final url = Uri.parse('$_baseUrl/schedules?pageSize=300');
    final response = await http.get(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return [];
    _throwIfFailed(response, 'Không tải được lịch học');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = data['documents'] as List<dynamic>? ?? [];
    final schedules = documents.map((doc) {
      final document = doc as Map<String, dynamic>;
      final name = document['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      return ScheduleModel.fromFirestore(id, fields);
    }).toList();
    return schedules..sort((a, b) => a.studyDate.compareTo(b.studyDate));
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    final id = schedule.id.trim().isEmpty
        ? _safeDocumentId('${schedule.classId}_${schedule.studyDate}_${DateTime.now().millisecondsSinceEpoch}')
        : schedule.id;
    final url = Uri.parse('$_baseUrl/schedules/$id');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': _fields(schedule)}),
    ).timeout(const Duration(seconds: 15));
    _throwIfFailed(response, 'Không thêm được lịch học');
  }

  Future<void> deleteSchedule(String id) async {
    final url = Uri.parse('$_baseUrl/schedules/$id');
    final response = await http.delete(url).timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) return;
    _throwIfFailed(response, 'Không xóa được lịch học');
  }

  Map<String, dynamic> _fields(ScheduleModel s) => {
        'classId': {'stringValue': s.classId},
        'shiftId': {'stringValue': s.shiftId},
        'studyDate': {'stringValue': s.studyDate},
        'roomName': {'stringValue': s.roomName ?? ''},
        'lessonTopic': {'stringValue': s.lessonTopic ?? ''},
        'note': {'stringValue': s.note ?? ''},
        'status': {'stringValue': s.status},
      };

  String _safeDocumentId(String value) => value.replaceAll('/', '_').replaceAll(' ', '_').replaceAll(':', '_').replaceAll('.', '_');
  void _throwIfFailed(http.Response response, String message) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('$message. HTTP ${response.statusCode}: ${response.body}');
  }
}
