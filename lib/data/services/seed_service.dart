import 'package:uuid/uuid.dart';
import 'database_service.dart';

class SeedService {
  static final _uuid = Uuid();

  static Future<void> seedInitialData() async {
    final db = await DatabaseService.instance.database;

    final users = await db.query('users');
    if (users.isNotEmpty) return;

    final nowIso = DateTime.now().toIso8601String();

    // ── Users ──────────────────────────────────────────────
    final adminId = _uuid.v4();
    final teacherId = _uuid.v4();
    final parent1Id = _uuid.v4();
    final parent2Id = _uuid.v4();
    final parent3Id = _uuid.v4();

    await db.insert('users', {
      'id': adminId,
      'full_name': 'Admin Nhân Trí',
      'phone': '0900000001',
      'email': 'admin@nhantri.com',
      'password_hash': '123456',
      'role': 'ADMIN',
      'status': 'ACTIVE',
      'created_at': nowIso,
    });
    await db.insert('users', {
      'id': teacherId,
      'full_name': 'Giáo viên Nguyễn Phương',
      'phone': '0900000003',
      'email': 'teacher@nhantri.com',
      'password_hash': '123456',
      'role': 'TEACHER',
      'status': 'ACTIVE',
      'created_at': nowIso,
    });
    await db.insert('users', {
      'id': parent1Id,
      'full_name': 'Nguyễn Thị Lan',
      'phone': '0900000002',
      'email': 'lan@gmail.com',
      'password_hash': '123456',
      'role': 'PARENT',
      'status': 'ACTIVE',
      'created_at': nowIso,
    });
    await db.insert('users', {
      'id': parent2Id,
      'full_name': 'Trần Văn Hùng',
      'phone': '0902222222',
      'email': 'hung@gmail.com',
      'password_hash': '123456',
      'role': 'PARENT',
      'status': 'ACTIVE',
      'created_at': nowIso,
    });
    await db.insert('users', {
      'id': parent3Id,
      'full_name': 'Lê Thị Mai',
      'phone': '0903333333',
      'email': 'mai@gmail.com',
      'password_hash': '123456',
      'role': 'PARENT',
      'status': 'ACTIVE',
      'created_at': nowIso,
    });

    // ── Parents ─────────────────────────────────────────────
    final p1 = _uuid.v4();
    final p2 = _uuid.v4();
    final p3 = _uuid.v4();

    await db.insert('parents', {
      'id': p1,
      'user_id': parent1Id,
      'full_name': 'Nguyễn Thị Lan',
      'phone': '0900000002',
      'email': 'lan@gmail.com',
      'address': 'Hà Nội',
      'relationship_to_student': 'Mẹ',
      'note': '',
      'created_at': nowIso,
    });
    await db.insert('parents', {
      'id': p2,
      'user_id': parent2Id,
      'full_name': 'Trần Văn Hùng',
      'phone': '0902222222',
      'email': 'hung@gmail.com',
      'address': 'Hà Nội',
      'relationship_to_student': 'Bố',
      'note': '',
      'created_at': nowIso,
    });
    await db.insert('parents', {
      'id': p3,
      'user_id': parent3Id,
      'full_name': 'Lê Thị Mai',
      'phone': '0903333333',
      'email': 'mai@gmail.com',
      'address': 'Hà Nội',
      'relationship_to_student': 'Mẹ',
      'note': '',
      'created_at': nowIso,
    });

    // ── Classes ──────────────────────────────────────────────
    final cls1 = _uuid.v4();
    final cls2 = _uuid.v4();
    final cls3 = _uuid.v4();

    await db.insert('class_rooms', {
      'id': cls1,
      'class_code': 'CLS001',
      'class_name': 'Cờ Vua Căn Bản',
      'description': 'Lớp dành cho học sinh mới bắt đầu học cờ vua',
      'level': 'Cơ bản',
      'tuition_fee': 500000.0,
      'max_students': 15,
      'current_students': 3,
      'room_name': 'Phòng 101',
      'status': 'OPENING',
      'created_at': nowIso,
    });
    await db.insert('class_rooms', {
      'id': cls2,
      'class_code': 'CLS002',
      'class_name': 'Cờ Vua Trung Cấp',
      'description': 'Học sinh đã biết các nước đi cơ bản',
      'level': 'Trung cấp',
      'tuition_fee': 700000.0,
      'max_students': 12,
      'current_students': 2,
      'room_name': 'Phòng 102',
      'status': 'OPENING',
      'created_at': nowIso,
    });
    await db.insert('class_rooms', {
      'id': cls3,
      'class_code': 'CLS003',
      'class_name': 'Cờ Vua Nâng Cao',
      'description': 'Thi đấu và chiến thuật chuyên sâu',
      'level': 'Nâng cao',
      'tuition_fee': 900000.0,
      'max_students': 10,
      'current_students': 1,
      'room_name': 'Phòng 103',
      'status': 'OPENING',
      'created_at': nowIso,
    });

    // ── Teacher assignments ─────────────────────────────────
    await db.insert('class_teacher_assignments', {
      'id': _uuid.v4(),
      'class_id': cls1,
      'teacher_id': teacherId,
      'assigned_at': nowIso,
      'status': 'ACTIVE',
    });
    await db.insert('class_teacher_assignments', {
      'id': _uuid.v4(),
      'class_id': cls2,
      'teacher_id': teacherId,
      'assigned_at': nowIso,
      'status': 'ACTIVE',
    });

    // ── Students ─────────────────────────────────────────────
    final joinDate = '2026-03-01';

    final s1 = _uuid.v4();
    final s2 = _uuid.v4();
    final s3 = _uuid.v4();
    final s4 = _uuid.v4();
    final s5 = _uuid.v4();
    final s6 = _uuid.v4();

    final students = [
      {
        'id': s1,
        'full_name': 'Nguyễn Cung',
        'date_of_birth': '2015-04-10',
        'gender': 'MALE',
        'school': 'TH Nguyễn Du',
        'grade': 'Lớp 4',
        'address': 'Hoàn Kiếm, HN',
        'lichess_username': 'NguyenCung',
        'class': cls1,
      },
      {
        'id': s2,
        'full_name': 'Trần Thu Hà',
        'date_of_birth': '2016-08-20',
        'gender': 'FEMALE',
        'school': 'TH Lý Thường Kiệt',
        'grade': 'Lớp 3',
        'address': 'Đống Đa, HN',
        'lichess_username': 'thuha_queen',
        'class': cls1,
      },
      {
        'id': s3,
        'full_name': 'Phạm Đức Thành',
        'date_of_birth': '2014-12-05',
        'gender': 'MALE',
        'school': 'TH Trần Phú',
        'grade': 'Lớp 5',
        'address': 'Hai Bà Trưng, HN',
        'lichess_username': 'ducthanh_2014',
        'class': cls1,
      },
      {
        'id': s4,
        'full_name': 'Lê Khánh Linh',
        'date_of_birth': '2014-03-15',
        'gender': 'FEMALE',
        'school': 'TH Đinh Tiên Hoàng',
        'grade': 'Lớp 5',
        'address': 'Cầu Giấy, HN',
        'lichess_username': 'khanhlinh_chess',
        'class': cls2,
      },
      {
        'id': s5,
        'full_name': 'Hoàng Tuấn Kiệt',
        'date_of_birth': '2013-07-22',
        'gender': 'MALE',
        'school': 'THCS Đống Đa',
        'grade': 'Lớp 6',
        'address': 'Ba Đình, HN',
        'lichess_username': 'tuankiet_rook',
        'class': cls2,
      },
      {
        'id': s6,
        'full_name': 'Vũ Ngọc Bảo',
        'date_of_birth': '2012-11-30',
        'gender': 'MALE',
        'school': 'THCS Nguyễn Trãi',
        'grade': 'Lớp 7',
        'address': 'Thanh Xuân, HN',
        'lichess_username': 'ngocbao_knight',
        'class': cls3,
      },
    ];

    for (final s in students) {
      await db.insert('students', {
        'id': s['id'],
        'full_name': s['full_name'],
        'date_of_birth': s['date_of_birth'],
        'gender': s['gender'],
        'school': s['school'],
        'grade': s['grade'],
        'address': s['address'],
        'health_note': null,
        'join_date': joinDate,
        'status': 'ACTIVE',
        'avatar_url': null,
        'note': null,
        'lichess_username': s['lichess_username'],
        'created_at': nowIso,
      });
      await db.insert('class_student', {
        'id': _uuid.v4(),
        'class_id': s['class'],
        'student_id': s['id'],
        'joined_at': nowIso,
        'status': 'ACTIVE',
      });
    }


    // ── Student tags / level groups ─────────────────────────
    final tagNhapMon = 'tag_nhap_mon';
    final tagCoBan = 'tag_co_ban';
    final tagTuyenTruong = 'tag_tuyen_truong';
    final tagNangCao = 'tag_nang_cao';

    final tags = [
      {
        'id': tagNhapMon,
        'tag_code': 'NHAP_MON',
        'tag_name': 'Nhập môn',
        'description': 'Học sinh mới làm quen luật cờ và tư duy cơ bản',
        'sort_order': 1,
      },
      {
        'id': tagCoBan,
        'tag_code': 'CO_BAN',
        'tag_name': 'Cơ bản',
        'description': 'Học sinh đã biết luật và bắt đầu luyện bài tập chiến thuật',
        'sort_order': 2,
      },
      {
        'id': tagTuyenTruong,
        'tag_code': 'TUYEN_TRUONG',
        'tag_name': 'Tuyển trường',
        'description': 'Nhóm học sinh luyện thi đấu, tuyển trường hoặc giải phong trào',
        'sort_order': 3,
      },
      {
        'id': tagNangCao,
        'tag_code': 'NANG_CAO',
        'tag_name': 'Nâng cao',
        'description': 'Học sinh cần giáo án nâng cao và phân tích ván sâu hơn',
        'sort_order': 4,
      },
    ];

    for (final tag in tags) {
      await db.insert('student_tags', {
        ...tag,
        'status': 'ACTIVE',
        'created_at': nowIso,
      });
    }

    final tagAssignments = [
      {'tag': tagNhapMon, 'student': s1},
      {'tag': tagNhapMon, 'student': s2},
      {'tag': tagNhapMon, 'student': s3},
      {'tag': tagCoBan, 'student': s4},
      {'tag': tagCoBan, 'student': s5},
      {'tag': tagTuyenTruong, 'student': s6},
      {'tag': tagNangCao, 'student': s6},
    ];

    for (final item in tagAssignments) {
      await db.insert('student_tag_assignments', {
        'id': _uuid.v4(),
        'tag_id': item['tag'],
        'student_id': item['student'],
        'assigned_at': nowIso,
        'status': 'ACTIVE',
      });
    }

    await db.insert('parent_student', {
      'id': _uuid.v4(),
      'parent_id': p1,
      'student_id': s1,
      'is_primary_contact': 1,
    });
    await db.insert('parent_student', {
      'id': _uuid.v4(),
      'parent_id': p2,
      'student_id': s2,
      'is_primary_contact': 1,
    });
    await db.insert('parent_student', {
      'id': _uuid.v4(),
      'parent_id': p3,
      'student_id': s4,
      'is_primary_contact': 1,
    });

    // ── Study shifts ──────────────────────────────────────────
    final sh1 = _uuid.v4();
    final sh2 = _uuid.v4();
    final sh3 = _uuid.v4();
    final sh4 = _uuid.v4();

    await db.insert('study_shifts', {
      'id': sh1,
      'shift_code': 'SH001',
      'shift_name': 'Tối Thứ 2',
      'day_of_week': 1,
      'start_time': '18:00',
      'end_time': '20:00',
      'note': null,
      'status': 'ACTIVE',
    });
    await db.insert('study_shifts', {
      'id': sh2,
      'shift_code': 'SH002',
      'shift_name': 'Tối Thứ 4',
      'day_of_week': 3,
      'start_time': '18:00',
      'end_time': '20:00',
      'note': null,
      'status': 'ACTIVE',
    });
    await db.insert('study_shifts', {
      'id': sh3,
      'shift_code': 'SH003',
      'shift_name': 'Sáng Thứ 7',
      'day_of_week': 6,
      'start_time': '08:00',
      'end_time': '10:00',
      'note': null,
      'status': 'ACTIVE',
    });
    await db.insert('study_shifts', {
      'id': sh4,
      'shift_code': 'SH004',
      'shift_name': 'Chiều Chủ Nhật',
      'day_of_week': 7,
      'start_time': '14:00',
      'end_time': '16:00',
      'note': null,
      'status': 'ACTIVE',
    });

    // ── Schedules ──────────────────────────────────────────────
    await db.insert('schedules', {
      'id': _uuid.v4(),
      'class_id': cls1,
      'shift_id': sh1,
      'study_date': '2026-04-21',
      'room_name': 'Phòng 101',
      'lesson_topic': 'Giới thiệu bàn cờ và quân cờ',
      'note': null,
      'status': 'SCHEDULED',
    });
    await db.insert('schedules', {
      'id': _uuid.v4(),
      'class_id': cls1,
      'shift_id': sh3,
      'study_date': '2026-04-26',
      'room_name': 'Phòng 101',
      'lesson_topic': 'Cách di chuyển các quân cơ bản',
      'note': null,
      'status': 'SCHEDULED',
    });
    await db.insert('schedules', {
      'id': _uuid.v4(),
      'class_id': cls2,
      'shift_id': sh2,
      'study_date': '2026-04-23',
      'room_name': 'Phòng 102',
      'lesson_topic': 'Khai cuộc - Sicilian Defense',
      'note': null,
      'status': 'SCHEDULED',
    });
    await db.insert('schedules', {
      'id': _uuid.v4(),
      'class_id': cls3,
      'shift_id': sh4,
      'study_date': '2026-04-27',
      'room_name': 'Phòng 103',
      'lesson_topic': 'Chiến thuật tấn công cánh vua',
      'note': null,
      'status': 'SCHEDULED',
    });

    // ── Attendance records ───────────────────────────────────
    for (final entry in [
      {'sid': s1, 'cid': cls1, 'date': '2026-04-21', 'status': 'PRESENT'},
      {'sid': s2, 'cid': cls1, 'date': '2026-04-21', 'status': 'PRESENT'},
      {'sid': s3, 'cid': cls1, 'date': '2026-04-21', 'status': 'ABSENT'},
      {'sid': s1, 'cid': cls1, 'date': '2026-04-14', 'status': 'PRESENT'},
      {'sid': s2, 'cid': cls1, 'date': '2026-04-14', 'status': 'ABSENT'},
      {'sid': s3, 'cid': cls1, 'date': '2026-04-14', 'status': 'PRESENT'},
      {'sid': s4, 'cid': cls2, 'date': '2026-04-23', 'status': 'PRESENT'},
      {'sid': s5, 'cid': cls2, 'date': '2026-04-23', 'status': 'PRESENT'},
    ]) {
      await db.insert('attendance_records', {
        'id': _uuid.v4(),
        'schedule_id': '${entry['cid']}_${entry['date']}',
        'class_id': entry['cid'],
        'student_id': entry['sid'],
        'attendance_date': entry['date'],
        'status': entry['status'],
        'note': null,
        'created_at': nowIso,
        'updated_at': null,
      });
    }

    // ── Learning guidance ────────────────────────────────────
    await db.insert('learning_guidance', {
      'id': _uuid.v4(),
      'teacher_id': teacherId,
      'class_id': cls1,
      'student_id': s1,
      'strengths': 'Tư duy tốt, nhớ luật nhanh',
      'improvements': 'Cần tập trung hơn ở phần tàn cuộc',
      'orientation': 'Tiếp tục luyện khai cuộc cơ bản và làm bài tập chiến thuật 2 buổi/tuần.',
      'created_at': nowIso,
    });

    // ── Tuitions ─────────────────────────────────────────────
    final dueDate = '2026-04-30';

    for (final entry in [
      {'sid': s1, 'cid': cls1, 'amount': 500000.0},
      {'sid': s2, 'cid': cls1, 'amount': 500000.0},
      {'sid': s4, 'cid': cls2, 'amount': 700000.0},
      {'sid': s6, 'cid': cls3, 'amount': 900000.0},
    ]) {
      await db.insert('tuitions', {
        'id': _uuid.v4(),
        'student_id': entry['sid'],
        'class_id': entry['cid'],
        'amount': entry['amount'],
        'due_date': dueDate,
        'paid_date': null,
        'status': 'UNPAID',
        'payment_method': null,
        'transaction_code': null,
        'qr_content': null,
        'note': 'Học phí tháng 4/2026',
        'tuition_period': '2026-04',
        'created_at': nowIso,
      });
    }

    for (final entry in [
      {'sid': s3, 'cid': cls1, 'amount': 500000.0},
      {'sid': s5, 'cid': cls2, 'amount': 700000.0},
    ]) {
      await db.insert('tuitions', {
        'id': _uuid.v4(),
        'student_id': entry['sid'],
        'class_id': entry['cid'],
        'amount': entry['amount'],
        'due_date': dueDate,
        'paid_date': '2026-04-12',
        'status': 'PAID',
        'payment_method': 'BANK_TRANSFER',
        'transaction_code': 'GD${DateTime.now().millisecondsSinceEpoch}',
        'qr_content': null,
        'note': 'Đã thanh toán',
        'tuition_period': '2026-04',
        'created_at': nowIso,
      });
    }
  }
}
