import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/student_model.dart';
import '../../models/subject_model.dart';
import '../../database/database_helper.dart';
import '../../admin/services/firestore_service.dart';
import 'student_attendance_report_screen.dart';
import 'leave_application_screen.dart';

/// Student dashboard where they can see their core subjects
/// and select one elective from each available group.
class StudentDashboardScreen extends StatefulWidget {
  final StudentModel student;

  const StudentDashboardScreen({super.key, required this.student});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late StudentModel _student;
  List<SubjectModel> _allAvailableSubjects = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Selected electives by group name: { "Group A": "subject_id" }
  Map<String, String> _tempSelections = {};

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Get all subjects for this semester AND course directly from Firestore
      final allSub = await FirestoreService().getSubjectsOnce(
        courseId: _student.courseId, 
        semester: _student.semester
      );
      
      // 2. Refresh student data from Firestore (to get latest elective status)
      // This helps if they login from multiple devices.
      final studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('enrollmentNo', isEqualTo: _student.enrollmentNo)
          .limit(1)
          .get();
      
      if (studentSnapshot.docs.isNotEmpty) {
        _student = StudentModel.fromMap(studentSnapshot.docs.first.data());
      }

      if (mounted) {
        setState(() {
          _allAvailableSubjects = allSub;
          
          // Populate temp selections from student's saved electives
          _tempSelections.clear();
          for (var subId in _student.selectedElectives) {
            final sub = allSub.where((s) => s.id == subId).firstOrNull;
            if (sub != null && sub.isElective) {
              _tempSelections[sub.electiveGroup ?? 'Other'] = subId;
            }
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data from server. Please refresh.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _goToAttendanceReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentAttendanceReportScreen(student: _student),
      ),
    );
  }

  void _goToLeaveApplication() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LeaveApplicationScreen(student: _student),
      ),
    );
  }

  Future<void> _confirmSelections() async {
    final electiveGroups = _allAvailableSubjects
        .where((s) => s.isElective && s.electiveGroup != null)
        .map((s) => s.electiveGroup!)
        .toSet();

    for (final group in electiveGroups) {
      if (!_tempSelections.containsKey(group)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select one subject from $group'),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Electives'),
        content: const Text('Are you sure about your selections? Once confirmed, you cannot change them.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final List<String> selectedIds = _tempSelections.values.toList();
        
        // Save to Firestore directly
        await FirestoreService().updateStudentElectives(
          enrollmentNo: _student.enrollmentNo, 
          selectedIds: selectedIds
        );

        // Also update local for immediate feedback (though sync will handle it later)
        await DatabaseHelper.instance.updateElectiveSelection(
          _student.enrollmentNo, 
          selectedIds, 
          '2026'
        );

        // Refresh state
        await _loadData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Electives confirmed successfully!'), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save selections. Try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfirmed = _student.electiveConfirmed == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: _goToAttendanceReport,
            tooltip: 'Attendance Report',
          ),
          IconButton(
            icon: const Icon(Icons.time_to_leave_rounded),
            onPressed: _goToLeaveApplication,
            tooltip: 'Apply for Leave',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorPlaceholder()
                : _allAvailableSubjects.isEmpty
                    ? _buildEmptyPlaceholder()
                    : _buildContent(theme),
      ),
      bottomNavigationBar: !isConfirmed && _allAvailableSubjects.any((s) => s.isElective)
          ? _buildBottomConfirmButton(theme)
          : null,
    );
  }

  Widget _buildContent(ThemeData theme) {
    final coreSubjects = _allAvailableSubjects.where((s) => !s.isElective).toList();
    final electiveSubjects = _allAvailableSubjects.where((s) => s.isElective).toList();

    final Map<String, List<SubjectModel>> groups = {};
    for (final s in electiveSubjects) {
      final g = s.electiveGroup ?? 'Other';
      groups.putIfAbsent(g, () => []).add(s);
    }
    final sortedGroupKeys = groups.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        _buildProfileHeader(theme),
        const SizedBox(height: 24),
        
        // Attendance Report Shortcut Card
        _buildAttendanceReportCard(theme),
        const SizedBox(height: 16),
        
        // Leave Application Shortcut Card
        _buildLeaveApplicationCard(theme),
        const SizedBox(height: 32),

        if (coreSubjects.isNotEmpty) ...[
          _buildSectionHeader('Your Core Subjects', Icons.layers_rounded),
          const SizedBox(height: 12),
          ...coreSubjects.map((s) => _buildSubjectCard(s, theme)),
          const SizedBox(height: 32),
        ],

        if (electiveSubjects.isNotEmpty) ...[
          _buildSectionHeader('Select Your Electives', Icons.auto_awesome_rounded),
          const SizedBox(height: 8),
          Text(
            _student.electiveConfirmed == 1
                ? 'Your selections are confirmed and locked.'
                : 'Select exactly one subject from each available group.',
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          for (final groupName in sortedGroupKeys)
            _buildElectiveGroup(groupName, groups[groupName]!, theme),
        ],
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildAttendanceReportCard(ThemeData theme) {
    return InkWell(
      onTap: _goToAttendanceReport,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF6C63FF), const Color(0xFF6C63FF).withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overall Attendance', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('View detailed subject-wise report', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveApplicationCard(ThemeData theme) {
    return InkWell(
      onTap: _goToLeaveApplication,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.event_note_rounded, color: Color(0xFF6C63FF), size: 32),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Leave Management', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Apply for leave or view status', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            child: Icon(Icons.person_outline_rounded, color: theme.colorScheme.primary, size: 32),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_student.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text('${_student.courseName} — Semester ${_student.semester}', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500)),
                Text('Enrollment: ${_student.enrollmentNo}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
              ],
            ),
          ),
          if (_student.electiveConfirmed == 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Text('Confirmed', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildSubjectCard(SubjectModel subject, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF1E1E2A),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.white.withOpacity(0.05))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(subject.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subject.subjectCode, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
      ),
    );
  }

  Widget _buildElectiveGroup(String groupName, List<SubjectModel> groupSubjects, ThemeData theme) {
    final isConfirmed = _student.electiveConfirmed == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 20),
          child: Text(groupName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange)),
        ),
        ...groupSubjects.map((subject) {
          final isSelected = _tempSelections[groupName] == subject.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isSelected ? Colors.orange.withOpacity(0.1) : const Color(0xFF1E1E2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isSelected ? Colors.orange.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
            ),
            child: RadioListTile<String>(
              value: subject.id,
              groupValue: _tempSelections[groupName],
              onChanged: isConfirmed ? null : (val) => setState(() { if (val != null) _tempSelections[groupName] = val; }),
              activeColor: Colors.orange,
              title: Text(subject.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.white70)),
              subtitle: Text(subject.subjectCode, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomConfirmButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF1E1E2A), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity, height: 54,
          child: ElevatedButton(
            onPressed: _confirmSelections,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Confirm Elective Selections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 60, color: Colors.red), const SizedBox(height: 16), Text(_errorMessage!, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 24), ElevatedButton(onPressed: _loadData, child: const Text('Retry'))]));

  Widget _buildEmptyPlaceholder() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.menu_book_rounded, size: 64, color: Colors.white.withOpacity(0.2)), const SizedBox(height: 16), const Text('No subjects found for your semester.', style: TextStyle(color: Colors.white54))]));
}
