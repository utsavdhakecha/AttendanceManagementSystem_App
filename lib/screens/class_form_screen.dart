import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/class_model.dart';
import '../providers/class_provider.dart';
import '../models/course_model.dart';
import '../models/subject_model.dart';
import '../admin/services/firestore_service.dart';

/// Form screen for adding or editing a class.
/// If [classModel] is provided, the form operates in edit mode.
class ClassFormScreen extends StatefulWidget {
  final ClassModel? classModel;
  final String professorId;
  final String professorName;

  const ClassFormScreen({
    super.key, 
    this.classModel, 
    required this.professorId, 
    required this.professorName,
  });

  @override
  State<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends State<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for fallback/manual (if needed) or display
  late TextEditingController _nameController;
  late TextEditingController _subjectController;
  
  bool _isSaving = false;
  bool _isLoadingMetadata = false;

  List<CourseModel> _allCourses = [];
  List<SubjectModel> _allSubjects = [];
  
  String? _selectedCourseId;
  String? _selectedSubjectId;
  int? _selectedSemester;

  bool get isEditing => widget.classModel != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.classModel?.name ?? '');
    _subjectController =
        TextEditingController(text: widget.classModel?.subject ?? '');
    
    _selectedCourseId = widget.classModel?.courseId;
    _selectedSubjectId = widget.classModel?.subjectId;
    _selectedSemester = widget.classModel?.semester;

    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    setState(() => _isLoadingMetadata = true);
    try {
      final courses = await FirestoreService().getCoursesOnce();
      setState(() {
        _allCourses = courses;
        _isLoadingMetadata = false;
      });
      
      if (_selectedCourseId != null) {
        _loadSubjectsForCourse(_selectedCourseId!);
      }
    } catch (e) {
      setState(() => _isLoadingMetadata = false);
    }
  }

  Future<void> _loadSubjectsForCourse(String courseId) async {
    try {
      final subjects = await FirestoreService().getSubjectsOnce(courseId: courseId);
      setState(() {
        _allSubjects = subjects;
      });
    } catch (e) {
      debugPrint('Error loading subjects: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<ClassProvider>();
    final name = _nameController.text.trim();
    final subject = _subjectController.text.trim();
    final now = DateTime.now().toIso8601String().split('T')[0];

    // Check for duplicate (excluding self if editing)
    final isDuplicate = provider.classes.any((c) =>
        c.name.toLowerCase() == name.toLowerCase() &&
        c.subject.toLowerCase() == subject.toLowerCase() &&
        (!isEditing || c.id != widget.classModel!.id));

    if (isDuplicate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A class with this name and subject already exists!'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _isSaving = false);
      return;
    }

    if (isEditing) {
      final updated = widget.classModel!.copyWith(
        name: name,
        subject: subject,
        courseId: _selectedCourseId,
        subjectId: _selectedSubjectId,
        semester: _selectedSemester,
        professorId: widget.professorId,
        professorName: widget.professorName,
      );
      await provider.updateClass(updated);
    } else {
      final newClass = ClassModel(
        name: name,
        subject: subject,
        createdAt: now,
        courseId: _selectedCourseId,
        subjectId: _selectedSubjectId,
        semester: _selectedSemester,
        professorId: widget.professorId,
        professorName: widget.professorName,
      );
      await provider.addClass(newClass);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Class' : 'Add Class'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_note : Icons.add_circle_outline,
                    size: 36,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Course Selection
              _isLoadingMetadata
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedCourseId,
                      decoration: InputDecoration(
                        labelText: 'Select Course',
                        prefixIcon: const Icon(Icons.school_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      isExpanded: true,
                      items: _allCourses
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCourseId = val;
                          _selectedSubjectId = null;
                          _selectedSemester = null;
                          _allSubjects = [];
                          if (val != null) {
                            final course = _allCourses.firstWhere((c) => c.id == val);
                            _nameController.text = course.name;
                            _loadSubjectsForCourse(val);
                          }
                        });
                      },
                      validator: (v) => v == null ? 'Please select a course' : null,
                    ),
              const SizedBox(height: 20),

              // Subject Selection
              DropdownButtonFormField<String>(
                value: _selectedSubjectId,
                disabledHint: const Text('Select a course first'),
                decoration: InputDecoration(
                  labelText: 'Select Subject',
                  prefixIcon: const Icon(Icons.book_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                isExpanded: true,
                items: _allSubjects
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSubjectId = val;
                    if (val != null) {
                      final sub = _allSubjects.firstWhere((s) => s.id == val);
                      _subjectController.text = sub.name;
                      _selectedSemester = sub.semester;
                    }
                  });
                },
                validator: (v) => v == null ? 'Please select a subject' : null,
              ),
              const SizedBox(height: 20),

              // Semester Display (Automatic)
              if (_selectedSemester != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Semester: $_selectedSemester',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              // Save button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(
                    isEditing ? 'Update Class' : 'Add Class',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
