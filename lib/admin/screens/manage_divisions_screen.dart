import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../models/division_model.dart';
import '../services/firestore_service.dart';

class ManageDivisionsScreen extends StatefulWidget {
  const ManageDivisionsScreen({super.key});

  @override
  State<ManageDivisionsScreen> createState() => _ManageDivisionsScreenState();
}

class _ManageDivisionsScreenState extends State<ManageDivisionsScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Divisions'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: _isLoadingCourses
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedCourseId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Course',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        dropdownColor: const Color(0xFF252535),
                        items: _courses
                            .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                )))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCourseId = val;
                            _selectedCourse =
                                _courses.firstWhere((c) => c.id == val);
                            _selectedSemester = null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedSemester,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Select Semester',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        dropdownColor: const Color(0xFF252535),
                        items: _selectedCourse == null
                            ? []
                            : List.generate(
                                _selectedCourse!.totalSemesters,
                                (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text('Semester ${i + 1}')),
                              ),
                        onChanged: _selectedCourse == null
                            ? null
                            : (val) => setState(() => _selectedSemester = val),
                      ),
                    ],
                  ),
          ),

          // Division List
          Expanded(
            child: _selectedCourseId == null || _selectedSemester == null
                ? const Center(child: Text('Select Course and Semester'))
                : StreamBuilder<List<DivisionModel>>(
                    stream: _service.getDivisions(
                      courseId: _selectedCourseId!,
                      semester: _selectedSemester!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('Error loading divisions'));
                      }
                      final divisions = snapshot.data ?? [];
                      if (divisions.isEmpty) {
                        return const Center(child: Text('No divisions added.'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: divisions.length,
                        itemBuilder: (context, index) {
                          final division = divisions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: const Color(0xFF1E1E2A),
                            child: ListTile(
                              title: Text('Division ${division.name}',
                                  style: const TextStyle(color: Colors.white)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                                onPressed: () =>
                                    _service.deleteDivision(division.id),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton:
          _selectedCourseId != null && _selectedSemester != null
              ? FloatingActionButton.extended(
                  onPressed: _showAddDivisionDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Division'),
                )
              : null,
    );
  }

  void _showAddDivisionDialog() {
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Division'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Course: ${_selectedCourse?.name}\nSemester: $_selectedSemester',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Division Name',
                  hintText: 'e.g. A, B, C',
                  prefixIcon: Icon(Icons.grid_view_rounded),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length > 2) return 'Too long (max 2)';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final divName = nameCtrl.text.trim().toUpperCase();
                await _service.addDivision(DivisionModel(
                  id: '',
                  name: divName,
                  courseId: _selectedCourseId!,
                  semester: _selectedSemester!,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
