import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/hod_model.dart';
import '../../models/professor_model.dart';
import '../../models/subject_model.dart';
import '../../models/student_model.dart';
import '../../models/course_model.dart';
import '../../models/attendance_session_model.dart';
import '../../models/division_model.dart';

/// Service class for all Firebase Firestore CRUD operations.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Singleton ───────────────────────────────────────────
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // ─── Collection references ───────────────────────────────
  CollectionReference get _hodsRef => _db.collection('hods');
  CollectionReference get _professorsRef => _db.collection('professors');
  CollectionReference get _subjectsRef => _db.collection('subjects');
  CollectionReference get _coursesRef => _db.collection('courses');
  CollectionReference get _studentsRef => _db.collection('students');
  CollectionReference get _attendanceRef => _db.collection('attendance_sessions');
  CollectionReference get _divisionsRef => _db.collection('divisions');

  CollectionReference get _timetablesRef => _db.collection('timetables');

  // ═══════════════════════════════════════════════════════════
  //  TIMETABLE
  // ═══════════════════════════════════════════════════════════

  Future<void> replaceProfessorTimetable(String professorId, List<Map<String, dynamic>> entries) async {
    final batch = _db.batch();
    
    // 1. Delete existing for this professor
    final snapshot = await _timetablesRef.where('professor_id', isEqualTo: professorId).get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    // 2. Insert new entries
    for (final entry in entries) {
      entry['professor_id'] = professorId; // Ensure safety
      batch.set(_timetablesRef.doc(), entry);
    }
    
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getProfessorTimetable(String professorId) async {
    final snapshot = await _timetablesRef.where('professor_id', isEqualTo: professorId).get();
    return snapshot.docs.map((doc) => {...doc.data() as Map<String, dynamic>, 'doc_id': doc.id}).toList();
  }

  Future<void> deleteTimetableEntry(String docId) async {
    await _timetablesRef.doc(docId).delete();
  }

  Future<void> clearProfessorTimetable(String professorId) async {
    final batch = _db.batch();
    final snapshot = await _timetablesRef.where('professor_id', isEqualTo: professorId).get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ═══════════════════════════════════════════════════════════
  //  COURSES
  // ═══════════════════════════════════════════════════════════

  Future<void> seedCourses() async {
    final snapshot = await _coursesRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final course in CourseModel.predefined) {
      batch.set(_coursesRef.doc(course.id), course.toMap());
    }
    await batch.commit();
  }

  Stream<List<CourseModel>> getCourses() {
    return _coursesRef.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              CourseModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<CourseModel>> getCoursesOnce() async {
    final snapshot = await _coursesRef.orderBy('name').get();
    return snapshot.docs
        .map((doc) =>
            CourseModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> seedStudents() async {
    final snapshot = await _studentsRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _db.batch();
    final courses = CourseModel.predefined;
    final fullNames = [
      'Aarav Sharma', 'Aditi Verma', 'Akash Patel', 'Amrita Kaur', 'Ananya Gupta',
      'Arjun Reddy', 'Bhavna Mishra', 'Deepak Singh', 'Divya Nair', 'Ishaan Iyer',
      'Karan Joshi', 'Kavita Rao', 'Manish Yadav', 'Megha Choudhary', 'Nitin Malhotra',
      'Pooja Dubey', 'Rahul Saxena', 'Rani Mukerji', 'Rohan Bhatia', 'Sanya Singhal',
      'Shaurya Chauhan', 'Shreya Deshmukh', 'Siddharth Bose', 'Sneha Kulkarni', 'Varun Kapoor',
      'Vihaan Saxena', 'Zoya Khan', 'Aman Jaiswal', 'Ishita Bhardwaj', 'Lakshya Mehra',
      'Myra Oberoi', 'Pranav Hegde', 'Riya Sen', 'Tushar Aggarwal', 'Vanya Dixit'
    ];

    // Generate 105 students to ensure 100+
    for (int i = 0; i < 105; i++) {
      final enrollmentNum = (11111 + i).toString();
      final course = courses[i % courses.length];
      final semester = (i % course.totalSemesters) + 1;
      final name = fullNames[i % fullNames.length];
      
      List<String> selectedElectives = [];
      int electiveConfirmed = 0;

      // For students 11111 to 11160 (first 50), pre-select their electives
      if (i < 50) {
        electiveConfirmed = 1;
        final prefix = course.id.substring(0, 3);
        
        // Pick first subject (i=0) from Group A (g=0)
        selectedElectives.add('SUB_${course.id}_S${semester}_CSE-$prefix-E${semester}01');
        
        // If semester 5, also pick first from Group B (g=1)
        if (semester == 5) {
          selectedElectives.add('SUB_${course.id}_S${semester}_CSE-$prefix-E${semester}11');
        }
      }

      final student = StudentModel(
        enrollmentNo: enrollmentNum,
        name: name,
        password: 'pass$enrollmentNum',
        courseId: course.id,
        courseName: course.name,
        semester: semester,
        division: (i % 2 == 0) ? 'A' : 'B',
        electiveConfirmed: electiveConfirmed,
        selectedElectives: selectedElectives,
        createdAt: DateTime.now(),
      );
      
      batch.set(_studentsRef.doc(), student.toMap());
    }
    await batch.commit();
    print('Students seeded with pre-selected electives for 11111-11160!');
  }

  // ═══════════════════════════════════════════════════════════
  //  HODs
  // ═══════════════════════════════════════════════════════════

  Future<void> addHod(HodModel hod) async {
    await _hodsRef.add(hod.toMap());
  }

  Future<void> updateHod(HodModel hod) async {
    await _hodsRef.doc(hod.id).update(hod.toMap());
  }

  Future<void> deleteHod(String id) async {
    await _hodsRef.doc(id).delete();
  }

  Stream<List<HodModel>> getHods() {
    return _hodsRef.orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                HodModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<bool> isHodLoginIdTaken(String loginId, {String? excludeId}) async {
    final snapshot = await _hodsRef.where('loginId', isEqualTo: loginId).get();
    if (excludeId != null) {
      return snapshot.docs.any((doc) => doc.id != excludeId);
    }
    return snapshot.docs.isNotEmpty;
  }

  Future<HodModel?> authenticateHod(String loginId, String password) async {
    final snapshot = await _hodsRef
        .where('loginId', isEqualTo: loginId)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return HodModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<int> getHodCount() async {
    final snapshot = await _hodsRef.count().get();
    return snapshot.count ?? 0;
  }

  // ═══════════════════════════════════════════════════════════
  //  PROFESSORS
  // ═══════════════════════════════════════════════════════════

  Future<void> addProfessor(ProfessorModel professor) async {
    await _professorsRef.add(professor.toMap());
  }

  Future<void> updateProfessor(ProfessorModel professor) async {
    await _professorsRef.doc(professor.id).update(professor.toMap());
  }

  Future<void> deleteProfessor(String id) async {
    await _professorsRef.doc(id).delete();
  }

  Stream<List<ProfessorModel>> getProfessors() {
    return _professorsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProfessorModel.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<ProfessorModel?> authenticateProfessor(String loginId, String password) async {
    final snapshot = await _professorsRef
        .where('loginId', isEqualTo: loginId)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return ProfessorModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<bool> isProfessorLoginIdTaken(String loginId, {String? excludeId}) async {
    final snapshot = await _professorsRef.where('loginId', isEqualTo: loginId).get();
    if (excludeId != null) {
      return snapshot.docs.any((doc) => doc.id != excludeId);
    }
    return snapshot.docs.isNotEmpty;
  }

  Future<void> updateProfessorSubjects(String profId, List<AssignedSubject> subjects) async {
    await _professorsRef.doc(profId).update({
      'assignedSubjects': subjects.map((s) => s.toMap()).toList(),
    });
  }

  Future<int> getProfessorCount() async {
    final snapshot = await _professorsRef.count().get();
    return snapshot.count ?? 0;
  }

  // ═══════════════════════════════════════════════════════════
  //  SUBJECTS
  // ═══════════════════════════════════════════════════════════

  Future<void> addSubject(SubjectModel subject) async {
    await _subjectsRef.add(subject.toMap());
  }

  Future<void> updateSubject(SubjectModel subject) async {
    await _subjectsRef.doc(subject.id).update(subject.toMap());
  }

  Future<void> deleteSubject(String id) async {
    await _subjectsRef.doc(id).delete();
  }

  Stream<List<SubjectModel>> getSubjects({required String courseId, required int semester}) {
    return _subjectsRef
        .where('courseId', isEqualTo: courseId)
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) =>
              SubjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
      list.sort((a, b) {
        if (a.isElective != b.isElective) return a.isElective ? 1 : -1;
        return a.name.compareTo(b.name);
      });
      return list;
    });
  }

  Future<List<SubjectModel>> getSubjectsOnce({required String courseId, int? semester}) async {
    Query query = _subjectsRef.where('courseId', isEqualTo: courseId);
    if (semester != null) {
      query = query.where('semester', isEqualTo: semester);
    }
    final snapshot = await query.get();
    final list = snapshot.docs
        .map((doc) =>
            SubjectModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    list.sort((a, b) {
      if (a.isElective != b.isElective) return a.isElective ? 1 : -1;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  Future<int> getSubjectCount() async {
    final snapshot = await _subjectsRef.count().get();
    return snapshot.count ?? 0;
  }

  Future<bool> isSubjectInUse(String subjectId) async {
    // Basic check: is it assigned to any professor or selected by any student in student_subject_mapping (SQLite)
    // For Firestore, we might check professor assignments.
    final profDocs = await _professorsRef.get();
    for (final doc in profDocs.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final assigned = List<Map<String, dynamic>>.from(data['assignedSubjects'] ?? []);
      if (assigned.any((s) => s['id'] == subjectId)) return true;
    }
    return false;
  }

  Future<SubjectModel?> getSubjectByDetails({required String courseId, required int semester, required String name}) async {
    final snapshot = await _subjectsRef
        .where('courseId', isEqualTo: courseId)
        .where('semester', isEqualTo: semester)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return SubjectModel.fromMap(snapshot.docs.first.id, snapshot.docs.first.data() as Map<String, dynamic>);
  }

  Future<List<StudentModel>> getStudentsForAssignment({
    required String courseId, 
    required int semester, 
    required String divisionName,
    required String subjectId,
  }) async {
    // Determine if subject is an elective
    final subjectDoc = await _subjectsRef.doc(subjectId).get();
    final isElective = subjectDoc.exists && (subjectDoc.data() as Map<String, dynamic>)['isElective'] == true;

    // Fetch all students for that class batch
    final snapshot = await _studentsRef
        .where('courseId', isEqualTo: courseId)
        .where('semester', isEqualTo: semester)
        .where('division', isEqualTo: divisionName)
        .get();
    
    var students = snapshot.docs
        .map((doc) => StudentModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    
    // Filter if it's an elective
    if (isElective) {
      students = students.where((s) => s.selectedElectives.contains(subjectId)).toList();
    }
    
    return students;
  }

  // ═══════════════════════════════════════════════════════════
  //  ATTENDANCE SESSIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> saveAttendanceSession(AttendanceSessionModel session) async {
    await _attendanceRef.doc(session.sessionId).set(session.toMap());
  }

  Stream<List<AttendanceSessionModel>> getAttendanceSessions() {
    return _attendanceRef
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceSessionModel.fromMap(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id}))
            .toList());
  }

  // ═══════════════════════════════════════════════════════════
  //  DIVISIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> addDivision(DivisionModel division) async {
    await _divisionsRef.add(division.toMap());
  }

  Future<void> deleteDivision(String id) async {
    await _divisionsRef.doc(id).delete();
  }

  Stream<List<DivisionModel>> getDivisions({required String courseId, required int semester}) {
    return _divisionsRef
        .where('courseId', isEqualTo: courseId)
        .where('semester', isEqualTo: semester)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                DivisionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<List<DivisionModel>> getDivisionsOnce({required String courseId, required int semester}) async {
    final snapshot = await _divisionsRef
        .where('courseId', isEqualTo: courseId)
        .where('semester', isEqualTo: semester)
        .get();
    return snapshot.docs
        .map((doc) =>
            DivisionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStudentElectives({required String enrollmentNo, required List<String> selectedIds}) async {
    final snapshot = await _studentsRef.where('enrollmentNo', isEqualTo: enrollmentNo).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'selectedElectives': selectedIds,
        'electiveConfirmed': true,
      });
    }
  }

  Future<List<Map<String, dynamic>>> getStudentAttendance(String enrollmentNo) async {
    // In our simplified firestore model, student details are embedded in the session
    final snapshot = await _attendanceRef.get();
    final List<Map<String, dynamic>> records = [];
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final details = List<Map<String, dynamic>>.from(data['student_details'] ?? []);
      final myRecord = details.where((d) => d['enrollmentNo'] == enrollmentNo).firstOrNull;
      
      if (myRecord != null) {
        records.add({
          'status': myRecord['status']?.toString().toLowerCase() ?? 'absent',
          'date': data['date'],
          'subject_name': data['subject_name'],
          'professor_name': data['professor_name'],
          'subject_id': data['subject_id'],
        });
      }
    }
    records.sort((a, b) => b['date'].toString().compareTo(a['date'].toString()));
    return records;
  }
}
