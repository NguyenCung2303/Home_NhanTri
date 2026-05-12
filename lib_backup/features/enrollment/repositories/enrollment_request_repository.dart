import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../data/models/enrollment_request_model.dart';

class EnrollmentApprovalResult {
  final String parentUserId;
  final String parentId;
  final String studentId;
  final String defaultPassword;

  EnrollmentApprovalResult({
    required this.parentUserId,
    required this.parentId,
    required this.studentId,
    required this.defaultPassword,
  });

  String get phone => parentUserId;
  String get password => defaultPassword;
}

class EnrollmentRequestRepository {
  static const String _projectId = 'nhantri-52a8d';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  static const String _defaultPassword = '123456';

  Future<String> createEnrollmentRequest({
    required String parentName,
    required String phone,
    String? email,
    required String studentName,
    String? studentBirthYear,
    required String gender,
    required String school,
    required String grade,
    required String lichessUsername,
    required String address,
    required String healthNote,
    required String currentLevel,
    required String learningGoal,
    String? note,
  }) async {
    final url = Uri.parse('$_baseUrl/enrollment_requests');
    final now = DateTime.now().toUtc().toIso8601String();

    final body = {
      'fields': {
        'parentName': {'stringValue': parentName.trim()},
        'phone': {'stringValue': _normalizePhone(phone)},
        'email': {'stringValue': _normalizeEmail(email)},
        'studentName': {'stringValue': studentName.trim()},
        'studentBirthYear': {'stringValue': studentBirthYear?.trim() ?? ''},
        'gender': {'stringValue': gender.trim()},
        'school': {'stringValue': school.trim()},
        'grade': {'stringValue': grade.trim()},
        'lichessUsername': {'stringValue': lichessUsername.trim()},
        'address': {'stringValue': address.trim()},
        'healthNote': {'stringValue': healthNote.trim()},
        'currentLevel': {'stringValue': currentLevel},
        'learningGoal': {'stringValue': learningGoal},
        'note': {'stringValue': note?.trim() ?? ''},
        'status': {'stringValue': 'PENDING'},
        'createdAt': {'timestampValue': now},
        'updatedAt': {'timestampValue': now},
      }
    };

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Gửi đăng ký thất bại');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final name = data['name']?.toString() ?? '';

    return name.split('/').last;
  }

  Future<List<EnrollmentRequestModel>> getAll({String? status}) async {
    final url = Uri.parse(
      '$_baseUrl/enrollment_requests?pageSize=100&orderBy=createdAt%20desc',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không tải được danh sách đơn đăng ký');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final documents = (data['documents'] as List<dynamic>?) ?? [];

    final result = documents.map((item) {
      final doc = item as Map<String, dynamic>;
      final name = doc['name']?.toString() ?? '';
      final id = name.split('/').last;
      final fields = doc['fields'] as Map<String, dynamic>? ?? {};

      final map = _fieldsToLegacyMap(fields);
      map['id'] = id;

      return EnrollmentRequestModel.fromMap(map);
    }).toList();

    if (status == null) return result;
    return result.where((item) => item.status == status).toList();
  }

  Future<int> countPending() async {
    final all = await getAll();
    return all
        .where((item) => item.status == 'PENDING' || item.status == 'CONTACTED')
        .length;
  }

  Future<void> markContacted(String requestId) async {
    await _patchDocument(
      collection: 'enrollment_requests',
      documentId: requestId,
      updateMask: ['status', 'updatedAt'],
      fields: {
        'status': {'stringValue': 'CONTACTED'},
        'updatedAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
      errorMessage: 'Không cập nhật được trạng thái đã liên hệ',
    );
  }

  Future<void> reject(String requestId, {String? reason}) async {
    await _patchDocument(
      collection: 'enrollment_requests',
      documentId: requestId,
      updateMask: ['status', 'rejectReason', 'updatedAt'],
      fields: {
        'status': {'stringValue': 'REJECTED'},
        'rejectReason': {'stringValue': reason ?? ''},
        'updatedAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String(),
        },
      },
      errorMessage: 'Không từ chối được đơn đăng ký',
    );
  }

  Future<EnrollmentApprovalResult> approveAndCreateAccount({
    required String requestId,
    required String classId,
  }) async {
    final request = await _getById(requestId);
    final now = DateTime.now().toUtc().toIso8601String();

    final parentUserId = await _createParentUser(request: request, now: now);

    final parentId = await _createParentProfile(
      request: request,
      parentUserId: parentUserId,
      now: now,
    );

    final studentId = await _createStudentFromRequest(
      request: request,
      classId: classId,
      parentUserId: parentUserId,
      parentId: parentId,
      now: now,
    );

    await _patchDocument(
      collection: 'enrollment_requests',
      documentId: requestId,
      updateMask: [
        'status',
        'approvedAt',
        'updatedAt',
        'parentUserId',
        'parentId',
        'studentId',
        'classId',
      ],
      fields: {
        'status': {'stringValue': 'APPROVED'},
        'approvedAt': {'timestampValue': now},
        'updatedAt': {'timestampValue': now},
        'parentUserId': {'stringValue': parentUserId},
        'parentId': {'stringValue': parentId},
        'studentId': {'stringValue': studentId},
        'classId': {'stringValue': classId},
      },
      errorMessage: 'Không cập nhật trạng thái duyệt đơn',
    );

    return EnrollmentApprovalResult(
      parentUserId: parentUserId,
      parentId: parentId,
      studentId: studentId,
      defaultPassword: _defaultPassword,
    );
  }

  Future<EnrollmentRequestModel> _getById(String requestId) async {
    final url = Uri.parse('$_baseUrl/enrollment_requests/$requestId');
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không tải được thông tin đơn đăng ký');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = data['fields'] as Map<String, dynamic>? ?? {};

    final map = _fieldsToLegacyMap(fields);
    map['id'] = requestId;

    return EnrollmentRequestModel.fromMap(map);
  }

  Future<String> _createParentUser({
    required EnrollmentRequestModel request,
    required String now,
  }) async {
    final phone = _normalizePhone(request.phone);
    final email = _normalizeEmail(request.email);
    final parentUserId = _safeDocumentId(phone.isNotEmpty ? phone : email);

    final url = Uri.parse('$_baseUrl/users/$parentUserId');

    final response = await http
        .patch(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fields': {
              'id': {'stringValue': parentUserId},
              'fullName': {'stringValue': request.parentName},
              'phone': {'stringValue': phone},
              'email': {'stringValue': email},
              'passwordHash': {'stringValue': _defaultPassword},
              'role': {'stringValue': 'PARENT'},
              'status': {'stringValue': 'ACTIVE'},
              'createdAt': {'timestampValue': now},
              'updatedAt': {'timestampValue': now},
              'source': {'stringValue': 'enrollment_request'},
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không tạo được tài khoản phụ huynh');

    return parentUserId;
  }

  Future<String> _createParentProfile({
    required EnrollmentRequestModel request,
    required String parentUserId,
    required String now,
  }) async {
    final parentId = parentUserId;
    final url = Uri.parse('$_baseUrl/parents/$parentId');

    final response = await http
        .patch(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fields': {
              'id': {'stringValue': parentId},
              'userId': {'stringValue': parentUserId},
              'fullName': {'stringValue': request.parentName},
              'phone': {'stringValue': _normalizePhone(request.phone)},
              'email': {'stringValue': _normalizeEmail(request.email)},
              'address': {'stringValue': request.address ?? ''},
              'status': {'stringValue': 'ACTIVE'},
              'createdAt': {'timestampValue': now},
              'updatedAt': {'timestampValue': now},
              'source': {'stringValue': 'enrollment_request'},
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không tạo được hồ sơ phụ huynh');

    return parentId;
  }

  Future<String> _createStudentFromRequest({
    required EnrollmentRequestModel request,
    required String classId,
    required String parentUserId,
    required String parentId,
    required String now,
  }) async {
    final url = Uri.parse('$_baseUrl/students');

    final body = {
      'fields': {
        'fullName': {'stringValue': request.studentName},
        'studentName': {'stringValue': request.studentName},
        'dateOfBirth': {'stringValue': ''},
        'birthYear': {'stringValue': request.studentBirthYear ?? ''},
        'gender': {'stringValue': request.gender ?? ''},
        'school': {'stringValue': request.school ?? ''},
        'grade': {'stringValue': request.grade ?? ''},
        'address': {'stringValue': request.address ?? ''},
        'healthNote': {'stringValue': request.healthNote ?? ''},
        'lichessUsername': {'stringValue': request.lichessUsername ?? ''},
        'joinDate': {'stringValue': now.substring(0, 10)},
        'status': {'stringValue': 'ACTIVE'},
        'avatarUrl': {'stringValue': ''},
        'note': {'stringValue': request.note ?? ''},
        'tag': {'stringValue': request.currentLevel ?? 'Nhập môn'},
        'currentLevel': {'stringValue': request.currentLevel ?? 'Nhập môn'},
        'learningGoal': {'stringValue': request.learningGoal ?? ''},
        'parentUserId': {'stringValue': parentUserId},
        'parentId': {'stringValue': parentId},
        'parentName': {'stringValue': request.parentName},
        'parentPhone': {'stringValue': _normalizePhone(request.phone)},
        'parentEmail': {'stringValue': _normalizeEmail(request.email)},
        'classId': {'stringValue': classId},
        'enrollmentRequestId': {'stringValue': request.id},
        'createdAt': {'timestampValue': now},
        'updatedAt': {'timestampValue': now},
        'source': {'stringValue': 'enrollment_request'},
      }
    };

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không tạo được học sinh từ đơn đăng ký');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final name = data['name']?.toString() ?? '';

    return name.split('/').last;
  }

  Future<void> _createInitialTuitionForPreviousMonth({
    required String studentId,
    required String parentUserId,
    required String classId,
    required String now,
  }) async {
    final today = DateTime.now();
    final previousMonth = DateTime(today.year, today.month - 1, 1);

    final tuitionPeriod =
        '${previousMonth.year}-${previousMonth.month.toString().padLeft(2, '0')}';

    final dueDate =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-05';

    final classUrl = Uri.parse('$_baseUrl/class_rooms/$classId');
    final classResponse = await http.get(classUrl).timeout(
          const Duration(seconds: 15),
        );

    _throwIfFailed(classResponse, 'Không tải được thông tin lớp học');

    final classData = jsonDecode(classResponse.body) as Map<String, dynamic>;
    final classFields = classData['fields'] as Map<String, dynamic>? ?? {};

    final rawFee = classFields['tuitionFee'];

    final unitPrice = double.tryParse(
          rawFee?['doubleValue']?.toString() ??
              rawFee?['integerValue']?.toString() ??
              rawFee?['stringValue']?.toString() ??
              '0',
        ) ??
        0;

    final sessionCount = await _countClassSessionsInPeriod(
      classId: classId,
      period: tuitionPeriod,
    );

    if (sessionCount == 0) {
      throw Exception(
        'Lớp chưa có buổi học nào trong tháng $tuitionPeriod nên chưa thể tạo học phí.',
      );
    }

    final amount = unitPrice * sessionCount;
    final tuitionId = _safeDocumentId('${studentId}_$tuitionPeriod');

    final url = Uri.parse('$_baseUrl/tuitions/$tuitionId');

    final response = await http
        .patch(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fields': {
              'id': {'stringValue': tuitionId},
              'studentId': {'stringValue': studentId},
              'parentUserId': {'stringValue': parentUserId},
              'classId': {'stringValue': classId},
              'amount': {'doubleValue': amount},
              'unitPrice': {'doubleValue': unitPrice},
              'sessionCount': {'integerValue': sessionCount.toString()},
              'paidAmount': {'doubleValue': 0},
              'status': {'stringValue': 'UNPAID'},
              'tuitionPeriod': {'stringValue': tuitionPeriod},
              'dueDate': {'stringValue': dueDate},
              'note': {'stringValue': 'Học phí tháng $tuitionPeriod'},
              'createdAt': {'timestampValue': now},
              'updatedAt': {'timestampValue': now},
            },
          }),
        )
        .timeout(const Duration(seconds: 15));

    _throwIfFailed(response, 'Không tạo được học phí ban đầu');
  }


  Future<void> _patchDocument({
    required String collection,
    required String documentId,
    required List<String> updateMask,
    required Map<String, dynamic> fields,
    required String errorMessage,
  }) async {
    final maskQuery =
        updateMask.map((field) => 'updateMask.fieldPaths=$field').join('&');

    final url = Uri.parse('$_baseUrl/$collection/$documentId?$maskQuery');

    final response = await http
        .patch(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'fields': fields}),
        )
        .timeout(const Duration(seconds: 15));

    _throwIfFailed(response, errorMessage);
  }

  Map<String, dynamic> _fieldsToLegacyMap(Map<String, dynamic> fields) {
    String str(String key) {
      final value = fields[key];
      if (value == null) return '';

      return value['stringValue']?.toString() ??
          value['integerValue']?.toString() ??
          value['booleanValue']?.toString() ??
          value['timestampValue']?.toString() ??
          '';
    }

    return {
      'parent_name': str('parentName'),
      'phone': str('phone'),
      'email': str('email'),
      'student_name': str('studentName'),
      'student_birth_year': str('studentBirthYear'),
      'gender': str('gender'),
      'school': str('school'),
      'grade': str('grade'),
      'lichess_username': str('lichessUsername'),
      'address': str('address'),
      'health_note': str('healthNote'),
      'current_level': str('currentLevel'),
      'learning_goal': str('learningGoal'),
      'note': str('note'),
      'status': str('status').isEmpty ? 'PENDING' : str('status'),
      'rejection_reason': str('rejectReason'),
      'created_at': str('createdAt'),
      'updated_at': str('updatedAt'),
      'approved_at': str('approvedAt'),
      'parent_user_id': str('parentUserId'),
      'parent_id': str('parentId'),
      'student_id': str('studentId'),
      'class_id': str('classId'),
    };
  }

  String _normalizePhone(String value) {
    return value.trim().replaceAll(' ', '');
  }

  String _normalizeEmail(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  String _safeDocumentId(String value) {
    final normalized = value.trim().isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : value.trim();

    return normalized
        .replaceAll('/', '_')
        .replaceAll(' ', '_')
        .replaceAll(':', '_')
        .replaceAll('.', '_')
        .replaceAll('@', '_at_');
  }

  void _throwIfFailed(http.Response response, String message) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw Exception('$message. HTTP ${response.statusCode}: ${response.body}');
  }


  Future<int> _countClassSessionsInPeriod({
  required String classId,
  required String period,
}) async {
  final url = Uri.parse('$_baseUrl/schedules?pageSize=500');

  final response = await http.get(url).timeout(
        const Duration(seconds: 15),
      );

  if (response.statusCode == 404) {
    return 0;
  }

  _throwIfFailed(response, 'Không tải được lịch học để tính học phí');

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final documents = data['documents'] as List<dynamic>? ?? [];

  var count = 0;

  for (final item in documents) {
    final doc = item as Map<String, dynamic>;
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};

    String str(String key) {
      final value = fields[key];
      if (value == null) return '';

      return value['stringValue']?.toString() ??
          value['timestampValue']?.toString() ??
          '';
    }

    final scheduleClassId = str('classId');

    final scheduleDate = str('studyDate').isNotEmpty
        ? str('studyDate')
        : (str('scheduleDate').isNotEmpty ? str('scheduleDate') : str('date'));

    final status = str('status').isNotEmpty ? str('status') : 'ACTIVE';

    if (scheduleClassId == classId &&
        scheduleDate.startsWith(period) &&
        status != 'CANCELLED') {
      count++;
    }
  }

  return count;
}
}

