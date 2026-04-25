import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/professor_model.dart';
import '../models/subject_model.dart';
import '../models/student_model.dart';
import '../models/course_model.dart';
import '../models/attendance_session_model.dart';
import '../models/attendance_model.dart';
import '../admin/services/firestore_service.dart';
import '../database/database_helper.dart';

/// One-stop utility to populate the CSE Department Attendance System with maximum dummy data.
/// This includes Professors, Subjects, Assignments, and historical Attendance records.
class DemoDataSeeder {
  static final FirestoreService _service = FirestoreService();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedAll() async {
    print('Starting Demo Data Seeding & Migration Check...');

    // 1. Seed Courses (if not already there)
    await _service.seedCourses();

    // 2. Perform Migration Check for subjects and students
    await _cleanLegacyDataIfNeeded();

    // 3. Seed Divisions (Deterministic IDs)
    await _seedDivisions();

    // 4. Seed Subjects (Deterministic IDs)
    await _seedSubjects();

    // 5. Seed Students (Now can pre-select electives)
    await _service.seedStudents();

    // 6. Seed Professors
    await _seedProfessors();

    // 7. Build Professor-Subject Assignments
    await _buildAssignments();

    // 8. Generate Historical Attendance
    await _seedAttendanceHistory();

    // 9. Sync to Local Database (Primary data source for login)
    await _syncToLocal();

    print('Demo Data Seeding & Migration Completed Successfully!');
  }

  static Future<void> _cleanLegacyDataIfNeeded() async {
    // Check subjects for legacy field naming
    final subjectsSnapshot = await _db.collection('subjects').limit(1).get();
    if (subjectsSnapshot.docs.isNotEmpty) {
      final data = subjectsSnapshot.docs.first.data();
      // If the record has 'course_id' instead of 'courseId', it's legacy data from before the fix.
      if (data.containsKey('course_id') && !data.containsKey('courseId')) {
        print('Legacy subject data detected. Cleaning up for re-seed...');
        final batch = _db.batch();
        final allSubs = await _db.collection('subjects').get();
        for (final doc in allSubs.docs) batch.delete(doc.reference);
        await batch.commit();
      }
    }

    // Check students for legacy field naming or old enrollment format
    final studentsSnapshot = await _db.collection('students').limit(1).get();
    if (studentsSnapshot.docs.isNotEmpty) {
      final data = studentsSnapshot.docs.first.data();
      final enro = data['enrollmentNo']?.toString() ?? '';
      // If enrollment doesn't start with 111 or lacks the new 'selectedElectives' field, re-seed.
      if (enro.isNotEmpty &&
          (!enro.startsWith('111') || !data.containsKey('selectedElectives'))) {
        print(
            'Incomplete student data detected. Cleaning up for fresh elective seeding...');
        final batch = _db.batch();
        final allStus = await _db.collection('students').get();
        for (final doc in allStus.docs) batch.delete(doc.reference);
        await batch.commit();
      }
    }
  }

  static Future<void> _syncToLocal() async {
    print('Syncing data to local SQLite...');
    final subjectsSnapshot = await _db.collection('subjects').get();
    final studentsSnapshot = await _db.collection('students').get();

    final List<SubjectModel> subjects = subjectsSnapshot.docs
        .map((doc) => SubjectModel.fromMap(doc.id, doc.data()))
        .toList();

    final List<StudentModel> students = studentsSnapshot.docs
        .map((doc) => StudentModel.fromMap(doc.data()))
        .toList();

    await DatabaseHelper.instance.clearSubjects();
    await DatabaseHelper.instance.clearStudents();
    await DatabaseHelper.instance.clearSubjectMappings();

    await DatabaseHelper.instance.insertSubjects(subjects);
    await DatabaseHelper.instance.insertStudents(students);
    print(
        'Local sync completed! [${subjects.length}] subjects and [${students.length}] students synced.');
  }

  static Future<void> _seedProfessors() async {
    // Only seed if the collection is empty
    final snapshot = await _db.collection('professors').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    print('Seeding dummy professors...');

    final batch = _db.batch();
    final profs = [
      ('Dr. Rajesh Sharma', 'rajesh.sharma@cse.com'),
      ('Prof. Sneha Gupta', 'sneha.gupta@cse.com'),
      ('Dr. Amit Verma', 'amit.verma@cse.com'),
      ('Prof. Priya Das', 'priya.das@cse.com'),
      ('Mr. Vikram Singh', 'vikram.singh@cse.com'),
    ];

    for (final profData in profs) {
      final name = profData.$1;
      final email = profData.$2;
      final prof = ProfessorModel(
        id: '',
        name: name,
        department: 'Computer Science',
        loginId: email,
        password: 'password123',
      );
      batch.set(_db.collection('professors').doc(), prof.toMap());
    }
    await batch.commit();
  }

  static Future<void> _seedSubjects() async {
    // 1. Clear ALL subjects first to remove any random-ID leftovers from previous bugs
    final snapshot = await _db.collection('subjects').get();
    if (snapshot.docs.isNotEmpty) {
      print(
          'Clearing [${snapshot.docs.length}] existing subjects for ultra-clean re-seed...');
      final delBatch = _db.batch();
      for (final doc in snapshot.docs) delBatch.delete(doc.reference);
      await delBatch.commit();
    }

    print('Seeding subjects with elective groups (Deterministic IDs)...');
    final courses = CourseModel.predefined;

    final coreNames = [
      'Data Structures',
      'Algorithms',
      'Operating Systems',
      'Database Management',
      'Computer Networks',
      'Software Engineering',
      'Discrete Math',
      'Digital Logic',
      'Microprocessors',
      'Web Tech',
      'Mobile App Dev',
      'Cyber Security',
      'Big Data',
      'Compiler Design',
      'Graph Theory',
      'Numerical Methods'
    ];
    final electiveNames = [
      'Distributed Systems',
      'Natural Language Processing',
      'Computer Graphics',
      'Internet of Things',
      'Soft Computing',
      'Block Chain',
      'Parallel Computing',
      'Quantum Computing',
      'Embedded Systems',
      'VLSI Design'
    ];

    for (final course in courses) {
      final batch = _db.batch();
      for (int sem = 1; sem <= course.totalSemesters; sem++) {
        // 1. Add 3 Core Subjects
        for (int i = 0; i < 3; i++) {
          final name = coreNames[(sem * 3 + i) % coreNames.length];
          final subjectCode = 'CSE-${course.id.substring(0, 3)}-C$sem${i + 1}';
          final subjectId = 'SUB_${course.id}_S${sem}_$subjectCode';

          final subject = SubjectModel(
            id: subjectId,
            name: '$name ($sem)',
            subjectCode: subjectCode,
            courseId: course.id,
            courseName: course.name,
            semester: sem,
            isElective: false,
            academicYear: '2026',
          );
          batch.set(_db.collection('subjects').doc(subjectId), subject.toMap());
        }

        // 2. Add Elective Groups
        int groupCount = (sem == 5) ? 2 : 1;
        for (int g = 0; g < groupCount; g++) {
          final groupName = 'Group ${String.fromCharCode(65 + g)}';
          for (int i = 0; i < 2; i++) {
            final name =
                electiveNames[(sem * 2 + g * 2 + i) % electiveNames.length];
            final subjectCode =
                'CSE-${course.id.substring(0, 3)}-E$sem${g}${i + 1}';
            final subjectId = 'SUB_${course.id}_S${sem}_$subjectCode';

            final subject = SubjectModel(
              id: subjectId,
              name: '$name (Elective)',
              subjectCode: subjectCode,
              courseId: course.id,
              courseName: course.name,
              semester: sem,
              isElective: true,
              electiveGroup: groupName,
              academicYear: '2026',
            );
            batch.set(
                _db.collection('subjects').doc(subjectId), subject.toMap());
          }
        }
      }
      await batch.commit();
    }
    print('Subjects seeded significantly!');
  }

  static Future<void> _seedDivisions() async {
    final snapshot = await _db.collection('divisions').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _db.batch();
    final courses = CourseModel.predefined;

    for (final course in courses) {
      for (int sem = 1; sem <= course.totalSemesters; sem++) {
        final names = ['A', 'B'];
        for (final name in names) {
          final divId = 'DIV_${course.id}_S${sem}_$name';
          final divData = {
            'id': divId,
            'name': name,
            'courseId': course.id,
            'semester': sem,
          };
          batch.set(_db.collection('divisions').doc(divId), divData);
        }
      }
    }
    await batch.commit();
    print('Divisions seeded significantly!');
  }

  static Future<void> _buildAssignments() async {
    final professors = await _service.getProfessors().first;
    final subjects = await _db.collection('subjects').get();

    if (professors.isEmpty || subjects.docs.isEmpty) return;

    final List<SubjectModel> allSubjects = subjects.docs
        .map((doc) => SubjectModel.fromMap(doc.id, doc.data()))
        .toList();

    int subIdx = 0;
    for (final prof in professors) {
      // Check if already has assignments
      if (prof.assignedSubjects.isNotEmpty) continue;

      // Assign 3 random subjects to each professor
      final List<AssignedSubject> assignments = [];
      for (int i = 0; i < 3; i++) {
        final sub = allSubjects[subIdx % allSubjects.length];

        // Pick one division for this assignment (A or B alternating)
        final divName = (subIdx % 2 == 0) ? 'A' : 'B';

        assignments.add(AssignedSubject(
          courseId: sub.courseId,
          courseName: sub.courseName,
          semester: sub.semester,
          subjectId: sub.id,
          subjectName: sub.name,
          subjectCode: sub.subjectCode,
          divisionName: divName,
        ));
        subIdx++;
      }

      await _service.updateProfessorSubjects(prof.id, assignments);
    }
  }

  static Future<void> _seedAttendanceHistory() async {
    final snapshot = await _db.collection('attendance_sessions').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final professors = await _service.getProfessors().first;
    final allStudents = await _db.collection('students').get();

    if (professors.isEmpty || allStudents.docs.isEmpty) return;

    final students = allStudents.docs
        .map((doc) => StudentModel.fromMap(doc.data()))
        .toList();
    final random = Random();

    // ── Build date list: Feb 1 2026 → Mar 31 2026, skip Sundays ──
    final List<DateTime> allDates = [];
    for (var d = DateTime(2026, 2, 1);
        d.isBefore(DateTime(2026, 4, 1));
        d = d.add(const Duration(days: 1))) {
      if (d.weekday == DateTime.sunday) continue;
      allDates.add(d);
    }

    // Pick 4 random weekdays in March to skip (simulate holidays/off days)
    final marchDates = allDates.where((d) => d.month == 3).toList();
    marchDates.shuffle(random);
    final skipDays = marchDates.take(4).toSet();
    final activeDates = allDates.where((d) => !skipDays.contains(d)).toList();

    print(
        'Seeding attendance for ${activeDates.length} days (Feb + Mar, no Sundays, 4 random March days skipped)...');

    // ── Seed attendance for each professor's each assignment per active day ──
    int firestoreBatchCount = 0;
    WriteBatch batch = _db.batch();

    for (final date in activeDates) {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      for (final prof in professors) {
        if (prof.assignedSubjects.isEmpty) continue;

        for (final assignment in prof.assignedSubjects) {
          // Filter students for this class
          final classStudents = students
              .where((s) =>
                  s.courseId == assignment.courseId &&
                  s.semester == assignment.semester &&
                  s.division == assignment.divisionName)
              .toList();
          if (classStudents.isEmpty) continue;

          // Use the same ID convention as HomeScreen: subjectCode.hashCode
          final classId = assignment.subjectCode.hashCode;
          final sessionId = '${classId}_$dateStr';

          int presentCount = 0;
          int absentCount = 0;
          final List<Map<String, dynamic>> details = [];
          final List<AttendanceModel> localRecords = [];

          for (final stu in classStudents) {
            final isPresent = random.nextDouble() > 0.15; // 85% attendance rate
            final status = isPresent ? 'present' : 'absent';
            if (isPresent)
              presentCount++;
            else
              absentCount++;

            details.add({
              'enrollmentNo': stu.enrollmentNo,
              'name': stu.name,
              'status': status,
            });

            localRecords.add(AttendanceModel(
              sessionId: sessionId,
              studentId: stu.enrollmentNo,
              status: status,
            ));
          }

          final session = AttendanceSessionModel(
            sessionId: sessionId,
            professorId: prof.id,
            professorName: prof.name,
            courseId: assignment.courseId,
            courseName: assignment.courseName,
            semester: assignment.semester,
            subjectId: assignment.subjectId,
            subjectName: assignment.subjectName,
            academicYear: '2025-26',
            date: dateStr,
            timestamp: date.add(const Duration(hours: 10)),
            presentCount: presentCount,
            absentCount: absentCount,
            leaveCount: 0,
            totalStudents: classStudents.length,
            lockedAfter4Hours: true,
            division: assignment.divisionName,
            studentDetails: details,
          );

          // Firestore
          batch.set(
              _db.collection('attendance_sessions').doc(), session.toMap());
          firestoreBatchCount++;

          // Firestore batches are capped at 500 operations
          if (firestoreBatchCount >= 490) {
            await batch.commit();
            batch = _db.batch();
            firestoreBatchCount = 0;
          }

          // Local SQLite
          await DatabaseHelper.instance.insertSession(session);
          await DatabaseHelper.instance.upsertAttendanceBatch(localRecords);
        }
      }
    }

    if (firestoreBatchCount > 0) {
      await batch.commit();
    }
    print(
        'Attendance history seeded for ${activeDates.length} days across all professor assignments!');
  }
}
