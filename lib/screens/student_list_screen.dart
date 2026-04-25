import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/class_model.dart';
import '../providers/student_provider.dart';
import '../widgets/student_card.dart';
import 'attendance_screen.dart';
import 'reports_screen.dart';

/// Screen displaying all students in a given allocated class.
/// Provides navigation to attendance marking and reports.
/// This view is strictly read-only for the professor.
class StudentListScreen extends StatefulWidget {
  final ClassModel classModel;

  const StudentListScreen({super.key, required this.classModel});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final studentProvider = context.read<StudentProvider>();
        try {
          // Sync strictly by the assigned class's identifiers
          await studentProvider.syncFirestoreStudents(
            classId: widget.classModel.id!,
            courseId: widget.classModel.courseId ?? 'CSE',
            semester: widget.classModel.semester ?? 1,
            divisionName: widget.classModel.divisionName ?? 'A',
            subjectId: widget.classModel.subjectId ?? '',
          );
        } catch (e) {
          debugPrint('Sync failed: $e');
          // No local fallback; data strictly requires Firestore.
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classModel.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.fact_check_outlined), 
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AttendanceScreen(classModel: widget.classModel))
            )
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart), 
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ReportsScreen(classModel: widget.classModel))
            )
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, studentProvider, _) {
          if (studentProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (studentProvider.students.isEmpty) {
            return const Center(child: Text('No students currently enrolled in this subject.'));
          }

          return ListView.builder(
            itemCount: studentProvider.students.length,
            itemBuilder: (context, index) {
              final student = studentProvider.students[index];
              return StudentCard(
                student: student,
                isSelected: false,
                isSelectionMode: false,
                onTap: null, 
                onLongPress: null,
              );
            },
          );
        },
      ),
    );
  }
}
