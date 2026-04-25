import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/subject_model.dart';
import '../services/firestore_service.dart';

/// Screen to manage subjects per course and semester.
/// Fixed: no TextEditingController disposed errors, no Firestore index needed.
class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  final FirestoreService _service = FirestoreService();

  String? _selectedCourseId;
  CourseModel? _selectedCourse;
  int? _selectedSemester;
  List<CourseModel> _courses = [];
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await _service.getCoursesOnce();
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Filters ──────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Subjects',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                _isLoadingCourses
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        children: [
                          // Course dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedCourseId,
                            decoration: InputDecoration(
                              labelText: 'Select Course',
                              prefixIcon: const Icon(Icons.school_outlined),
                              filled: true,
                              fillColor: const Color(0xFF252535),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            dropdownColor: const Color(0xFF252535),
                            isExpanded: true,
                            items: _courses.map((course) {
                              return DropdownMenuItem(
                                value: course.id,
                                child: Text(
                                  course.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (courseId) {
                              setState(() {
                                _selectedCourseId = courseId;
                                _selectedCourse = _courses
                                    .firstWhere((c) => c.id == courseId);
                                _selectedSemester = null;
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          // Semester dropdown
                          DropdownButtonFormField<int>(
                            value: _selectedSemester,
                            decoration: InputDecoration(
                              labelText: 'Select Semester',
                              prefixIcon:
                                  const Icon(Icons.calendar_month_outlined),
                              filled: true,
                              fillColor: const Color(0xFF252535),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.1)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            dropdownColor: const Color(0xFF252535),
                            items: _selectedCourse == null
                                ? []
                                : List.generate(
                                    _selectedCourse!.totalSemesters,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('Semester ${i + 1}'),
                                    ),
                                  ),
                            onChanged: _selectedCourse == null
                                ? null
                                : (sem) {
                                    setState(() => _selectedSemester = sem);
                                  },
                          ),
                        ],
                      ),
              ],
            ),
          ),

          // ── Subject List ─────────────────────────────────────
          Expanded(
            child: _selectedCourse == null || _selectedSemester == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list_rounded,
                            size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'Select a course and semester\nto view subjects',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<List<SubjectModel>>(
                    stream: _service.getSubjects(
                      courseId: _selectedCourse!.id,
                      semester: _selectedSemester!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Error loading subjects.\nPlease try again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade300),
                            ),
                          ),
                        );
                      }

                      final subjects = snapshot.data ?? [];

                      if (subjects.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.menu_book_outlined,
                                  size: 64, color: theme.colorScheme.outline),
                              const SizedBox(height: 16),
                              Text(
                                'No subjects found',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_selectedCourse!.name} — Semester $_selectedSemester',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => _showAddSubjectDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Subject'),
                              ),
                            ],
                          ),
                        );
                      }

                      // Separate core & elective (grouped)
                      final coreSubjects =
                          subjects.where((s) => !s.isElective).toList();
                      final electiveSubjects =
                          subjects.where((s) => s.isElective).toList();

                      // Group electives by group name
                      final electiveGroups = <String, List<SubjectModel>>{};
                      for (final s in electiveSubjects) {
                        final group = s.electiveGroup ?? 'Ungrouped';
                        electiveGroups.putIfAbsent(group, () => []).add(s);
                      }
                      final sortedGroupKeys = electiveGroups.keys.toList()
                        ..sort();

                      return ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        children: [
                          // Core subjects
                          if (coreSubjects.isNotEmpty) ...[
                            _buildSectionHeader(
                                'Core Subjects', coreSubjects.length,
                                color: const Color(0xFF6C63FF)),
                            ...coreSubjects.map(_buildSubjectCard),
                          ],
                          // Elective groups
                          for (final groupName in sortedGroupKeys) ...[
                            const SizedBox(height: 12),
                            _buildSectionHeader(
                              'Elective — $groupName',
                              electiveGroups[groupName]!.length,
                              color: const Color(0xFFFF9800),
                            ),
                            ...electiveGroups[groupName]!
                                .map(_buildSubjectCard),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton:
          (_selectedCourse != null && _selectedSemester != null)
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddSubjectDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Subject'),
                )
              : null,
    );
  }

  // ─── UI Helpers ────────────────────────────────────────────

  Widget _buildSectionHeader(String title, int count, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                  fontSize: 12,
                  color: color ?? Colors.white60,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(SubjectModel subject) {
    final cardColor =
        subject.isElective ? const Color(0xFFFF9800) : const Color(0xFF6C63FF);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF1E1E2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            subject.isElective
                ? Icons.star_outline_rounded
                : Icons.menu_book_rounded,
            color: cardColor,
            size: 22,
          ),
        ),
        title: Text(
          subject.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            children: [
              _buildChip(subject.subjectCode, Colors.white),
              if (subject.isElective)
                _buildChip(subject.electiveGroup ?? 'No Group',
                    const Color(0xFFFF9800)),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditSubjectDialog(subject);
            } else if (value == 'delete') {
              _confirmDelete(subject);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20),
                  SizedBox(width: 10),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── Delete with protection ────────────────────────────────

  Future<void> _confirmDelete(SubjectModel subject) async {
    // Check if subject is in use
    final inUse = await _service.isSubjectInUse(subject.id);
    if (inUse && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Cannot delete: Subject is assigned to a professor or selected by a student.'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteSubject(subject.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${subject.name} deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─── Add Subject Dialog ────────────────────────────────────

  Future<void> _showAddSubjectDialog() async {
    bool isElective = false;
    String electiveGroup = 'Group A';
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Add New Subject'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Course + Sem info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_selectedCourse!.name} — Semester $_selectedSemester',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Elective toggle FIRST
                    SwitchListTile(
                      title: const Text('Is this an Elective?'),
                      subtitle: Text(
                        isElective
                            ? 'Elective subject'
                            : 'Core (compulsory) subject',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      value: isElective,
                      onChanged: (val) {
                        setDialogState(() => isElective = val);
                      },
                      activeColor: const Color(0xFFFF9800),
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Elective group dropdown
                    if (isElective) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: electiveGroup,
                        decoration: const InputDecoration(
                          labelText: 'Elective Group',
                          prefixIcon: Icon(Icons.group_work_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Group A', child: Text('Group A')),
                          DropdownMenuItem(
                              value: 'Group B', child: Text('Group B')),
                          DropdownMenuItem(
                              value: 'Group C', child: Text('Group C')),
                          DropdownMenuItem(
                              value: 'Group D', child: Text('Group D')),
                        ],
                        onChanged: (val) {
                          setDialogState(
                              () => electiveGroup = val ?? 'Group A');
                        },
                      ),
                    ],

                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject Code',
                        hintText: 'e.g., CS301',
                        prefixIcon: Icon(Icons.code_rounded),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);

                        final model = SubjectModel(
                          id: '',
                          name: nameCtrl.text.trim(),
                          subjectCode: codeCtrl.text.trim().toUpperCase(),
                          courseId: _selectedCourse!.id,
                          courseName: _selectedCourse!.name,
                          semester: _selectedSemester!,
                          academicYear: '2026',
                          isElective: isElective,
                          electiveGroup: isElective ? electiveGroup : null,
                        );

                        await _service.addSubject(model);
                        if (ctx.mounted) {
                          Navigator.pop(ctx, true);
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
        ),
      );

      // Show success message - StreamBuilder will auto-update the list
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject added successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Dispose controllers in finally block to ensure they're always disposed
      // nameCtrl.dispose();
      // codeCtrl.dispose();
    }
  }

  // ─── Edit Subject Dialog ───────────────────────────────────

  Future<void> _showEditSubjectDialog(SubjectModel subject) async {
    bool isElective = subject.isElective;
    String electiveGroup = subject.electiveGroup ?? 'Group A';
    final nameCtrl = TextEditingController(text: subject.name);
    final codeCtrl = TextEditingController(text: subject.subjectCode);
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Edit Subject'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${subject.courseName} — Semester ${subject.semester}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Is this an Elective?'),
                      subtitle: Text(
                        isElective
                            ? 'Elective subject'
                            : 'Core (compulsory) subject',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      value: isElective,
                      onChanged: (val) {
                        setDialogState(() => isElective = val);
                      },
                      activeColor: const Color(0xFFFF9800),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (isElective) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: electiveGroup,
                        decoration: const InputDecoration(
                          labelText: 'Elective Group',
                          prefixIcon: Icon(Icons.group_work_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Group A', child: Text('Group A')),
                          DropdownMenuItem(
                              value: 'Group B', child: Text('Group B')),
                          DropdownMenuItem(
                              value: 'Group C', child: Text('Group C')),
                          DropdownMenuItem(
                              value: 'Group D', child: Text('Group D')),
                        ],
                        onChanged: (val) {
                          setDialogState(
                              () => electiveGroup = val ?? 'Group A');
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject Code',
                        hintText: 'e.g., CS301',
                        prefixIcon: Icon(Icons.code_rounded),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSaving = true);

                        final updated = SubjectModel(
                          id: subject.id,
                          name: nameCtrl.text.trim(),
                          subjectCode: codeCtrl.text.trim().toUpperCase(),
                          courseId: subject.courseId,
                          courseName: subject.courseName,
                          semester: subject.semester,
                          academicYear: subject.academicYear,
                          isElective: isElective,
                          electiveGroup: isElective ? electiveGroup : null,
                          createdAt: subject.createdAt,
                        );

                        await _service.updateSubject(updated);
                        if (ctx.mounted) {
                          Navigator.pop(ctx, true);
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Update'),
              ),
            ],
          ),
        ),
      );

// Show success message - StreamBuilder will auto-update the list
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // Dispose controllers in finally block to ensure they're always disposed
      // nameCtrl.dispose();
      // codeCtrl.dispose();
    }
  }
}
