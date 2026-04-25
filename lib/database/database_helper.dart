import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/attendance_session_model.dart';
import '../models/timetable_model.dart';
import '../models/subject_model.dart';
import '../models/class_model.dart';
import '../models/leave_request_model.dart';

class DatabaseHelper {
  static const _databaseName = "attendance_v4.db";
  static const _databaseVersion = 8;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db
          .execute('ALTER TABLE students ADD COLUMN division TEXT DEFAULT "A"');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE subjects ADD COLUMN elective_group TEXT');
    }
    if (oldVersion < 4) {
      await db
          .execute('ALTER TABLE attendance_sessions ADD COLUMN timestamp TEXT');
      await db.execute(
          'ALTER TABLE attendance_sessions ADD COLUMN present_count INTEGER DEFAULT 0');
      await db.execute(
          'ALTER TABLE attendance_sessions ADD COLUMN absent_count INTEGER DEFAULT 0');
      await db.execute(
          'ALTER TABLE attendance_sessions ADD COLUMN total_students INTEGER DEFAULT 0');
    }
    if (oldVersion < 5) {
      await db.execute(
          'ALTER TABLE attendance_sessions ADD COLUMN subject_name TEXT');
      await db.execute(
          'ALTER TABLE attendance_sessions ADD COLUMN professor_name TEXT');
      await db
          .execute('ALTER TABLE attendance_sessions ADD COLUMN course_id TEXT');
      await db.execute(
          'ALTER TABLE attendance_sessions ADD COLUMN course_name TEXT');
    }
    if (oldVersion < 6) {
      await db
          .execute('ALTER TABLE attendance_sessions ADD COLUMN division TEXT');
    }
    if (oldVersion < 7) {
      await db.execute('''CREATE TABLE leave_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        student_name TEXT NOT NULL,
        from_date TEXT NOT NULL,
        to_date TEXT NOT NULL,
        reason TEXT NOT NULL,
        status TEXT NOT NULL,
        applied_at TEXT NOT NULL
      )''');
    }
    if (oldVersion < 8) {
      await db.execute(
          'ALTER TABLE attendance_sessions ADD COLUMN leave_count INTEGER DEFAULT 0');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(
        '''CREATE TABLE courses (course_id TEXT PRIMARY KEY, course_name TEXT NOT NULL, total_semesters INTEGER NOT NULL)''');

    await db.execute('''CREATE TABLE subjects (
      subject_id TEXT PRIMARY KEY, 
      subject_name TEXT NOT NULL, 
      subject_code TEXT NOT NULL, 
      semester INTEGER NOT NULL, 
      course_id TEXT NOT NULL, 
      is_elective INTEGER DEFAULT 0, 
      elective_group TEXT,
      academic_year TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE students (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      enrollment_no TEXT UNIQUE NOT NULL, 
      password TEXT NOT NULL,
      name TEXT NOT NULL, 
      semester INTEGER NOT NULL, 
      course_id TEXT NOT NULL, 
      course_name TEXT NOT NULL,
      elective_confirmed INTEGER DEFAULT 0, 
      division TEXT DEFAULT "A",
      created_at TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE student_subject_mapping (
      mapping_id TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      subject_id TEXT NOT NULL,
      academic_year TEXT NOT NULL,
      FOREIGN KEY (student_id) REFERENCES students (enrollment_no) ON DELETE CASCADE,
      FOREIGN KEY (subject_id) REFERENCES subjects (subject_id) ON DELETE CASCADE
    )''');

    await db.execute('''CREATE TABLE attendance_sessions (
      session_id TEXT PRIMARY KEY, 
      subject_id TEXT NOT NULL, 
      subject_name TEXT,
      professor_id TEXT NOT NULL, 
      professor_name TEXT,
      course_id TEXT,
      course_name TEXT,
      academic_year TEXT NOT NULL, 
      semester INTEGER NOT NULL, 
      date TEXT NOT NULL, 
      division TEXT,
      locked_after_4_hours INTEGER DEFAULT 0,
      timestamp TEXT,
      present_count INTEGER DEFAULT 0,
      absent_count INTEGER DEFAULT 0,
      leave_count INTEGER DEFAULT 0,
      total_students INTEGER DEFAULT 0
    )''');

    await db.execute('''CREATE TABLE attendance (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      session_id TEXT NOT NULL, 
      student_id TEXT NOT NULL, 
      status TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE classes (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      name TEXT NOT NULL, 
      subject TEXT NOT NULL, 
      created_at TEXT NOT NULL, 
      is_from_timetable INTEGER DEFAULT 0, 
      course_id TEXT, 
      semester INTEGER, 
      subject_id TEXT, 
      professor_id TEXT, 
      professor_name TEXT
    )''');

    await db.execute('''CREATE TABLE timetable (
      id INTEGER PRIMARY KEY AUTOINCREMENT, 
      day TEXT NOT NULL, 
      start_time TEXT NOT NULL, 
      end_time TEXT NOT NULL, 
      class_name TEXT NOT NULL, 
      subject TEXT NOT NULL
    )''');

    await db.execute('''CREATE TABLE leave_requests (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_id TEXT NOT NULL,
      student_name TEXT NOT NULL,
      from_date TEXT NOT NULL,
      to_date TEXT NOT NULL,
      reason TEXT NOT NULL,
      status TEXT NOT NULL,
      applied_at TEXT NOT NULL
    )''');
  }

  // ===================== AUTHENTICATION =====================
  Future<StudentModel?> authenticateStudent(
      String enrollmentNo, String password) async {
    final db = await database;
    final res = await db.query('students',
        where: 'enrollment_no = ? AND password = ?',
        whereArgs: [enrollmentNo, password]);
    if (res.isNotEmpty) {
      return StudentModel.fromMap(res.first);
    }
    return null;
  }

  // ===================== STUDENT CRUD =====================
  Future<int> insertStudent(StudentModel student) async {
    final db = await database;
    return await db.insert('students', student.toLocalMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertStudents(List<StudentModel> students) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final student in students) {
        await txn.insert('students', student.toLocalMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<StudentModel>> getStudentsByClass(int classId) async {
    final db = await database;
    final res = await db.query('students');
    return res.map((m) => StudentModel.fromMap(m)).toList();
  }

  Future<int> updateStudent(StudentModel student) async {
    final db = await database;
    return await db.update('students', student.toLocalMap(),
        where: 'id = ?', whereArgs: [student.id]);
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteStudents(List<int> ids) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.delete('students', where: 'id = ?', whereArgs: [id]);
      }
    });
  }

  // ===================== CLASS CRUD =====================
  Future<int> insertClass(ClassModel classModel) async {
    final db = await database;
    return await db.insert('classes', classModel.toMap());
  }

  Future<List<ClassModel>> getClasses() async {
    final db = await database;
    final res = await db.query('classes', orderBy: 'created_at DESC');
    return res.map((m) => ClassModel.fromMap(m)).toList();
  }

  Future<int> updateClass(ClassModel classModel) async {
    final db = await database;
    return await db.update('classes', classModel.toMap(),
        where: 'id = ?', whereArgs: [classModel.id]);
  }

  Future<int> deleteClass(int id) async {
    final db = await database;
    return await db.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteClasses(List<int> ids) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.delete('classes', where: 'id = ?', whereArgs: [id]);
      }
    });
  }

  Future<int> upsertClassByNameAndSubject(String name, String subject) async {
    final db = await database;
    final existing = await db.query('classes',
        where: 'name = ? AND subject = ?',
        whereArgs: [name, subject],
        limit: 1);
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return await db.insert('classes', {
      'name': name,
      'subject': subject,
      'created_at': DateTime.now().toIso8601String()
    });
  }

  // ===================== TIMETABLE CRUD =====================
  Future<int> insertTimetableEntry(TimetableModel entry) async {
    final db = await database;
    return await db.insert('timetable', entry.toMap());
  }

  Future<void> insertTimetableEntries(List<TimetableModel> entries) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final entry in entries) await txn.insert('timetable', entry.toMap());
    });
  }

  Future<List<TimetableModel>> getTimetable() async {
    final db = await database;
    return (await db.query('timetable'))
        .map((m) => TimetableModel.fromMap(m))
        .toList();
  }

  Future<int> clearTimetable() async {
    final db = await database;
    return await db.delete('timetable');
  }

  Future<int> deleteTimetableEntry(int id) async {
    final db = await database;
    return await db.delete('timetable', where: 'id = ?', whereArgs: [id]);
  }

  // ===================== ATTENDANCE CRUD =====================
  Future<void> upsertAttendance(AttendanceModel attendance) async {
    final db = await database;
    await db.insert('attendance', attendance.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertAttendanceBatch(
      List<AttendanceModel> attendanceRecords) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final rec in attendanceRecords) {
        await txn.insert('attendance', rec.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<AttendanceModel>> getAttendanceBySession(String sessionId) async {
    final db = await database;
    return (await db.query('attendance',
            where: 'session_id = ?', whereArgs: [sessionId]))
        .map((m) => AttendanceModel.fromMap(m))
        .toList();
  }

  Future<List<AttendanceModel>> getAttendanceByDate(
      int classId, String date) async {
    final sessionId = "${classId}_$date";
    return getAttendanceBySession(sessionId);
  }

  Future<List<AttendanceModel>> getAttendanceByClass(int classId) async {
    final db = await database;
    final res = await db.query('attendance',
        where: "session_id LIKE ?", whereArgs: ["${classId}_%"]);
    return res.map((m) => AttendanceModel.fromMap(m)).toList();
  }

  Future<int> getPresentCount(String studentId, String sessionId) async {
    final db = await database;
    final res = await db.rawQuery(
        "SELECT COUNT(*) as total FROM attendance WHERE student_id = ? AND session_id = ? AND status = 'present'",
        [studentId, sessionId]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> getPresentCountForClass(String studentId, dynamic classId) async {
    final db = await database;
    final res = await db.rawQuery(
        "SELECT COUNT(*) as total FROM attendance WHERE student_id = ? AND session_id LIKE ? AND status = 'present'",
        [studentId, "${classId}_%"]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> getOnLeaveCountForClass(String studentId, dynamic classId) async {
    final db = await database;
    final res = await db.rawQuery(
        "SELECT COUNT(*) as total FROM attendance WHERE student_id = ? AND session_id LIKE ? AND status = 'on leave'",
        [studentId, "${classId}_%"]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> getTotalDaysForStudent(String studentId, dynamic id) async {
    final db = await database;
    final res = await db.rawQuery(
        "SELECT COUNT(*) as total FROM attendance WHERE student_id = ? AND session_id LIKE ?",
        [studentId, "${id}_%"]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> getTotalClassDays(dynamic id) async {
    final db = await database;
    final res = await db.rawQuery(
        'SELECT COUNT(DISTINCT session_id) as total FROM attendance WHERE session_id LIKE ?',
        ["${id}_%"]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAttendanceByStudentId(
      String studentId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT a.status, s.date, s.subject_name, s.professor_name, s.subject_id
      FROM attendance a
      JOIN attendance_sessions s ON a.session_id = s.session_id
      WHERE a.student_id = ?
      ORDER BY s.date DESC
    ''', [studentId]);
  }

  Future<void> insertSession(AttendanceSessionModel session) async {
    final db = await database;
    final map = session.toMap();
    map.remove(
        'student_details'); // Sqflite does not support List columns natively here
    await db.insert('attendance_sessions', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<AttendanceSessionModel?> getSession(String sessionId) async {
    final db = await database;
    final res = await db.query('attendance_sessions',
        where: 'session_id = ?', whereArgs: [sessionId]);
    if (res.isNotEmpty) return AttendanceSessionModel.fromMap(res.first);
    return null;
  }

  // ===================== SUBJECT MAPPING =====================
  Future<List<SubjectModel>> getSubjectsByStudent(String enrollmentNo) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT s.* FROM subjects s
      INNER JOIN student_subject_mapping m ON s.subject_id = m.subject_id
      WHERE m.student_id = ?
    ''', [enrollmentNo]);
    return res.map((m) => SubjectModel.fromLocalMap(m)).toList();
  }

  Future<int> insertSubject(SubjectModel subject) async {
    final db = await database;
    return await db.insert('subjects', subject.toLocalMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> insertSubjects(List<SubjectModel> subjects) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final subject in subjects) {
        await txn.insert('subjects', subject.toLocalMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<SubjectModel>> getSubjectsBySemester(
      int semester, String courseId) async {
    final db = await database;
    final res = await db.query('subjects',
        where: 'semester = ? AND course_id = ?',
        whereArgs: [semester, courseId]);
    return res.map((m) => SubjectModel.fromLocalMap(m)).toList();
  }

  Future<void> updateElectiveSelection(
      String studentId, List<String> subjectIds, String academicYear) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.rawDelete('''
        DELETE FROM student_subject_mapping 
        WHERE student_id = ? AND subject_id IN (SELECT subject_id FROM subjects WHERE is_elective = 1)
      ''', [studentId]);

      for (var sid in subjectIds) {
        await txn.insert('student_subject_mapping', {
          'mapping_id': '${studentId}_$sid',
          'student_id': studentId,
          'subject_id': sid,
          'academic_year': academicYear,
        });
      }
      await txn.update('students', {'elective_confirmed': 1},
          where: 'enrollment_no = ?', whereArgs: [studentId]);
    });
  }

  // ===================== SEEDING & SYNC =====================
  Future<void> clearSubjects() async {
    final db = await database;
    await db.delete('subjects');
  }

  Future<void> clearStudents() async {
    final db = await database;
    await db.delete('students');
  }

  Future<void> clearSubjectMappings() async {
    final db = await database;
    await db.delete('student_subject_mapping');
  }

  Future<void> seedSampleData() async {
    // Legacy seeding disabled in favor of professional DemoDataSeeder.
    return;
  }

  // ===================== LEAVE REQUESTS CRUD =====================
  Future<int> insertLeaveRequest(LeaveRequestModel request) async {
    final db = await database;
    return await db.insert('leave_requests', request.toMap());
  }

  Future<List<LeaveRequestModel>> getLeaveRequests() async {
    final db = await database;
    final res = await db.query('leave_requests', orderBy: 'applied_at DESC');
    return res.map((m) => LeaveRequestModel.fromMap(m)).toList();
  }

  Future<List<LeaveRequestModel>> getLeaveRequestsByStudent(
      String studentId) async {
    final db = await database;
    final res = await db.query('leave_requests',
        where: 'student_id = ?',
        whereArgs: [studentId],
        orderBy: 'applied_at DESC');
    return res.map((m) => LeaveRequestModel.fromMap(m)).toList();
  }

  Future<int> updateLeaveRequestStatus(int requestId, String status) async {
    final db = await database;
    return await db.update('leave_requests', {'status': status},
        where: 'id = ?', whereArgs: [requestId]);
  }

  Future<List<LeaveRequestModel>> getApprovedLeavesForDate(String date) async {
    final db = await database;
    // Date is in YYYY-MM-DD or similar. Leaves has from_date and to_date.
    // We need records where date >= from_date AND date <= to_date AND status = 'approved'
    final res = await db.query('leave_requests',
        where: 'status = ? AND from_date <= ? AND to_date >= ?',
        whereArgs: ['approved', date, date]);
    return res.map((m) => LeaveRequestModel.fromMap(m)).toList();
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
