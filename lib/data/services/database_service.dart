import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('home_nhan_tri.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        phone TEXT UNIQUE,
        email TEXT UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE parents (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL UNIQUE,
        full_name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        relationship_to_student TEXT,
        note TEXT,
        lichess_username TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        date_of_birth TEXT,
        gender TEXT,
        school TEXT,
        grade TEXT,
        address TEXT,
        health_note TEXT,
        join_date TEXT,
        status TEXT NOT NULL,
        avatar_url TEXT,
        note TEXT,
        lichess_username TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE parent_student (
        id TEXT PRIMARY KEY,
        parent_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        is_primary_contact INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE class_rooms (
        id TEXT PRIMARY KEY,
        class_code TEXT NOT NULL UNIQUE,
        class_name TEXT NOT NULL,
        description TEXT,
        level TEXT,
        tuition_fee REAL NOT NULL,
        max_students INTEGER NOT NULL,
        current_students INTEGER NOT NULL DEFAULT 0,
        room_name TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE class_student (
        id TEXT PRIMARY KEY,
        class_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        joined_at TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');


    await db.execute('''
      CREATE TABLE student_tags (
        id TEXT PRIMARY KEY,
        tag_code TEXT NOT NULL UNIQUE,
        tag_name TEXT NOT NULL,
        description TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE student_tag_assignments (
        id TEXT PRIMARY KEY,
        tag_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        assigned_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        UNIQUE(tag_id, student_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE class_teacher_assignments (
        id TEXT PRIMARY KEY,
        class_id TEXT NOT NULL,
        teacher_id TEXT NOT NULL,
        assigned_at TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE study_shifts (
        id TEXT PRIMARY KEY,
        shift_code TEXT NOT NULL UNIQUE,
        shift_name TEXT NOT NULL,
        day_of_week INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        note TEXT,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules (
        id TEXT PRIMARY KEY,
        class_id TEXT NOT NULL,
        shift_id TEXT NOT NULL,
        study_date TEXT NOT NULL,
        room_name TEXT,
        lesson_topic TEXT,
        note TEXT,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_records (
        id TEXT PRIMARY KEY,
        schedule_id TEXT NOT NULL,
        class_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        attendance_date TEXT NOT NULL,
        status TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE learning_guidance (
        id TEXT PRIMARY KEY,
        teacher_id TEXT NOT NULL,
        class_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        strengths TEXT,
        improvements TEXT,
        orientation TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'DRAFT',
        sent_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tuitions (
        id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL,
        class_id TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date TEXT NOT NULL,
        paid_date TEXT,
        status TEXT NOT NULL,
        payment_method TEXT,
        transaction_code TEXT,
        qr_content TEXT,
        note TEXT,
        tuition_period TEXT,
        created_at TEXT NOT NULL
      )
    ''');


    await db.execute('''
      CREATE TABLE enrollment_requests (
        id TEXT PRIMARY KEY,
        parent_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        student_name TEXT NOT NULL,
        student_birth_year TEXT,
        current_level TEXT,
        learning_goal TEXT,
        note TEXT,
        status TEXT NOT NULL DEFAULT 'PENDING',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        approved_at TEXT,
        approved_by TEXT,
        parent_user_id TEXT,
        parent_id TEXT,
        student_id TEXT,
        rejection_reason TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS attendance_records (
          id TEXT PRIMARY KEY,
          schedule_id TEXT NOT NULL,
          class_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          attendance_date TEXT NOT NULL,
          status TEXT NOT NULL,
          note TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS class_teacher_assignments (
          id TEXT PRIMARY KEY,
          class_id TEXT NOT NULL,
          teacher_id TEXT NOT NULL,
          assigned_at TEXT NOT NULL,
          status TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS learning_guidance (
          id TEXT PRIMARY KEY,
          teacher_id TEXT NOT NULL,
          class_id TEXT NOT NULL,
          student_id TEXT NOT NULL,
          strengths TEXT,
          improvements TEXT,
          orientation TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      final studentColumns = await db.rawQuery('PRAGMA table_info(students)');
      final hasLichess = studentColumns.any((c) => c['name'] == 'lichess_username');
      if (!hasLichess) {
        await db.execute('ALTER TABLE students ADD COLUMN lichess_username TEXT');
      }

      final tuitionColumns = await db.rawQuery('PRAGMA table_info(tuitions)');
      final hasPeriod = tuitionColumns.any((c) => c['name'] == 'tuition_period');
      if (!hasPeriod) {
        await db.execute('ALTER TABLE tuitions ADD COLUMN tuition_period TEXT');
      }
    }

    if (oldVersion < 5) {
      final guidanceColumns = await db.rawQuery('PRAGMA table_info(learning_guidance)');
      final hasStatus = guidanceColumns.any((c) => c['name'] == 'status');
      if (!hasStatus) {
        await db.execute("ALTER TABLE learning_guidance ADD COLUMN status TEXT NOT NULL DEFAULT 'DRAFT'");
      }

      final hasSentAt = guidanceColumns.any((c) => c['name'] == 'sent_at');
      if (!hasSentAt) {
        await db.execute('ALTER TABLE learning_guidance ADD COLUMN sent_at TEXT');
      }
    }

    if (oldVersion < 6) {
      await _createStudentTagTables(db);
      await _seedDefaultStudentTags(db);
    }


    if (oldVersion < 7) {
      await _createEnrollmentRequestTable(db);
    }
  }


  Future<void> _createEnrollmentRequestTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS enrollment_requests (
        id TEXT PRIMARY KEY,
        parent_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        student_name TEXT NOT NULL,
        student_birth_year TEXT,
        current_level TEXT,
        learning_goal TEXT,
        note TEXT,
        status TEXT NOT NULL DEFAULT 'PENDING',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        approved_at TEXT,
        approved_by TEXT,
        parent_user_id TEXT,
        parent_id TEXT,
        student_id TEXT,
        rejection_reason TEXT
      )
    ''');
  }

  Future<void> _createStudentTagTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS student_tags (
        id TEXT PRIMARY KEY,
        tag_code TEXT NOT NULL UNIQUE,
        tag_name TEXT NOT NULL,
        description TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS student_tag_assignments (
        id TEXT PRIMARY KEY,
        tag_id TEXT NOT NULL,
        student_id TEXT NOT NULL,
        assigned_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        UNIQUE(tag_id, student_id)
      )
    ''');
  }

  Future<void> _seedDefaultStudentTags(Database db) async {
    final now = DateTime.now().toIso8601String();
    final tags = [
      {
        'id': 'tag_nhap_mon',
        'tag_code': 'NHAP_MON',
        'tag_name': 'Nhập môn',
        'description': 'Học sinh mới làm quen luật cờ và tư duy cơ bản',
        'sort_order': 1,
      },
      {
        'id': 'tag_co_ban',
        'tag_code': 'CO_BAN',
        'tag_name': 'Cơ bản',
        'description': 'Học sinh đã biết luật và bắt đầu luyện bài tập chiến thuật',
        'sort_order': 2,
      },
      {
        'id': 'tag_tuyen_truong',
        'tag_code': 'TUYEN_TRUONG',
        'tag_name': 'Tuyển trường',
        'description': 'Nhóm học sinh luyện thi đấu, tuyển trường hoặc giải phong trào',
        'sort_order': 3,
      },
      {
        'id': 'tag_nang_cao',
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
        'created_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await db.rawInsert('''
      INSERT OR IGNORE INTO student_tag_assignments (id, tag_id, student_id, assigned_at, status)
      SELECT 'tag_assign_' || s.id || '_nhap_mon', 'tag_nhap_mon', s.id, ?, 'ACTIVE'
      FROM students s
      INNER JOIN class_student cs ON cs.student_id = s.id AND cs.status = 'ACTIVE'
      INNER JOIN class_rooms c ON c.id = cs.class_id
      WHERE c.level LIKE '%Cơ bản%'
    ''', [now]);

    await db.rawInsert('''
      INSERT OR IGNORE INTO student_tag_assignments (id, tag_id, student_id, assigned_at, status)
      SELECT 'tag_assign_' || s.id || '_co_ban', 'tag_co_ban', s.id, ?, 'ACTIVE'
      FROM students s
      INNER JOIN class_student cs ON cs.student_id = s.id AND cs.status = 'ACTIVE'
      INNER JOIN class_rooms c ON c.id = cs.class_id
      WHERE c.level LIKE '%Trung cấp%'
    ''', [now]);

    await db.rawInsert('''
      INSERT OR IGNORE INTO student_tag_assignments (id, tag_id, student_id, assigned_at, status)
      SELECT 'tag_assign_' || s.id || '_tuyen_truong', 'tag_tuyen_truong', s.id, ?, 'ACTIVE'
      FROM students s
      INNER JOIN class_student cs ON cs.student_id = s.id AND cs.status = 'ACTIVE'
      INNER JOIN class_rooms c ON c.id = cs.class_id
      WHERE c.level LIKE '%Nâng cao%'
    ''', [now]);
  }
}
