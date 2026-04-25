import 'package:flutter/material.dart';
import '../models/professor_model.dart';
import '../models/class_model.dart';
import 'student_list_screen.dart';
import 'timetable_screen.dart';

/// Home screen displaying the list of all classes allocated to the professor.
/// Built directly from the professor's assignedSubjects.
class HomeScreen extends StatefulWidget {
  final ProfessorModel professor;
  const HomeScreen({super.key, required this.professor});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _logout() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = widget.professor.assignedSubjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        centerTitle: true,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: const Icon(Icons.person, size: 32, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.professor.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.professor.department,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.class_outlined),
              title: const Text('My Classes'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Time Table'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          TimetableScreen(professor: widget.professor)),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.class_outlined,
                      size: 80, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No classes allocated',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final assigned = subjects[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: const Color(0xFF1E1E2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      assigned.subjectName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('${assigned.courseName} - Sem ${assigned.semester}'),
                        const SizedBox(height: 4),
                        Text(
                          'Division: ${assigned.divisionName}', 
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w500)
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Create a dummy ClassModel to pass to the StudentListScreen
                      // so we don't have to rewrite the attendance/reports screens.
                      final dummyClass = ClassModel(
                        id: assigned.subjectCode.hashCode,
                        name: '${assigned.courseName} Sem ${assigned.semester} Div ${assigned.divisionName}',
                        subject: assigned.subjectName,
                        createdAt: DateTime.now().toIso8601String(),
                        courseId: assigned.courseId,
                        semester: assigned.semester,
                        subjectId: assigned.subjectId,
                        professorId: widget.professor.id,
                        professorName: widget.professor.name,
                        courseName: assigned.courseName,
                        divisionName: assigned.divisionName,
                      );

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StudentListScreen(classModel: dummyClass),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
