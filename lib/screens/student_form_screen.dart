import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student_model.dart';
import '../providers/student_provider.dart';

/// Form screen for adding or editing a student.
class StudentFormScreen extends StatefulWidget {
  final String courseId;
  final int semester;
  final StudentModel? student;

  const StudentFormScreen({
    super.key,
    required this.courseId,
    required this.semester,
    this.student,
  });

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _rollController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isSaving = false;

  bool get isEditing => widget.student != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.student?.name ?? '');
    _rollController =
        TextEditingController(text: widget.student?.enrollmentNo ?? '');
    _passwordController =
        TextEditingController(text: widget.student?.password ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rollController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<StudentProvider>();

    if (isEditing) {
      final updated = widget.student!.copyWith(
        name: _nameController.text.trim(),
        enrollmentNo: _rollController.text.trim().toUpperCase(),
        password: _passwordController.text.trim(),
      );
      await provider.updateStudent(updated);
    } else {
      final newStudent = StudentModel(
        name: _nameController.text.trim(),
        enrollmentNo: _rollController.text.trim().toUpperCase(),
        password: _passwordController.text.trim(),
        semester: widget.semester,
        courseId: widget.courseId,
        courseName: 'Computer Science Engineering',
        createdAt: DateTime.now(),
      );
      await provider.addStudent(newStudent);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Student' : 'Add Student'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    isEditing ? Icons.person_outline : Icons.person_add_alt_1,
                    size: 40,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Student Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _rollController,
                decoration: InputDecoration(
                  labelText: 'Enrollment Number',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter enrollment number' : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Login Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => (value == null || value.length < 4) ? 'Enter at least 4 characters' : null,
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(isEditing ? Icons.save : Icons.person_add),
                  label: Text(isEditing ? 'Update Student' : 'Add Student'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
