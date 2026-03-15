import 'package:uuid/uuid.dart';
import 'database_service.dart';

class SeedService {
  static final _uuid = Uuid();

  static Future<void> seedInitialData() async {
    final db = await DatabaseService.instance.database;

    final users = await db.query('users');
    if (users.isNotEmpty) return;

    final adminUserId = _uuid.v4();
    final parentUserId = _uuid.v4();
    final parentId = _uuid.v4();
    final studentId = _uuid.v4();
    final classId = _uuid.v4();
    final shiftId = _uuid.v4();
    final scheduleId = _uuid.v4();
    final tuitionId = _uuid.v4();

    await db.insert('users', {
      'id': adminUserId,
      'full_name': 'Admin Home Nhân Trí',
      'phone': '0900000001',
      'email': 'admin@homent.com',
      'password_hash': '123456',
      'role': 'ADMIN',
      'status': 'ACTIVE',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('users', {
      'id': parentUserId,
      'full_name': 'Nguyễn Thị Phụ Huynh',
      'phone': '0900000002',
      'email': 'parent@homent.com',
      'password_hash': '123456',
      'role': 'PARENT',
      'status': 'ACTIVE',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('parents', {
      'id': parentId,
      'user_id': parentUserId,
      'full_name': 'Nguyễn Thị Phụ Huynh',
      'phone': '0900000002',
      'email': 'parent@homent.com',
      'address': 'Hà Nội',
      'relationship_to_student': 'Mẹ',
      'note': '',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('students', {
      'id': studentId,
      'full_name': 'Nguyễn Văn Bé',
      'date_of_birth': '2015-09-20',
      'gender': 'MALE',
      'school': 'Tiểu học A',
      'grade': 'Lớp 4',
      'address': 'Hà Nội',
      'health_note': '',
      'join_date': '2026-03-01',
      'status': 'ACTIVE',
      'avatar_url': '',
      'note': '',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('parent_student', {
      'id': _uuid.v4(),
      'parent_id': parentId,
      'student_id': studentId,
      'is_primary_contact': 1,
    });

    await db.insert('class_rooms', {
      'id': classId,
      'class_code': 'CLS001',
      'class_name': 'Lớp Cờ Vua Căn Bản',
      'description': 'Lớp học cờ vua cho học sinh mới bắt đầu',
      'level': 'Cơ bản',
      'tuition_fee': 500000,
      'max_students': 20,
      'current_students': 1,
      'room_name': 'Phòng 101',
      'status': 'OPENING',
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('class_student', {
      'id': _uuid.v4(),
      'class_id': classId,
      'student_id': studentId,
      'joined_at': DateTime.now().toIso8601String(),
      'status': 'ACTIVE',
    });

    await db.insert('study_shifts', {
      'id': shiftId,
      'shift_code': 'SHIFT001',
      'shift_name': 'Ca tối thứ 2',
      'day_of_week': 1,
      'start_time': '18:00',
      'end_time': '20:00',
      'note': '',
      'status': 'ACTIVE',
    });

    await db.insert('schedules', {
      'id': scheduleId,
      'class_id': classId,
      'shift_id': shiftId,
      'study_date': '2026-03-16',
      'room_name': 'Phòng 101',
      'lesson_topic': 'Nhập môn cờ vua',
      'note': '',
      'status': 'SCHEDULED',
    });

    await db.insert('tuitions', {
      'id': tuitionId,
      'student_id': studentId,
      'class_id': classId,
      'amount': 500000,
      'due_date': '2026-03-25',
      'paid_date': null,
      'status': 'UNPAID',
      'payment_method': null,
      'transaction_code': null,
      'qr_content': null,
      'note': 'Học phí tháng 3',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}