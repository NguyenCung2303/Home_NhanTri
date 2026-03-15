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
      version: 1,
      onCreate: _createDB,
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
        created_at TEXT NOT NULL
      )
    ''');
  }
}