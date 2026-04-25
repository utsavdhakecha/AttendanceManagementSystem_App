import 'package:flutter/material.dart';
import '../../models/professor_model.dart';
import '../../models/course_model.dart';
import '../../models/subject_model.dart';
import '../../models/division_model.dart';
import '../services/firestore_service.dart';

/// Screen to manage Professor accounts — list, add, edit, delete.
class ManageProfessorScreen extends StatefulWidget {
  const ManageProfessorScreen({super.key});

  @override
  State<ManageProfessorScreen> createState() => _ManageProfessorScreenState();
}

class _ManageProfessorScreenState extends State<ManageProfessorScreen> {
  final FirestoreService _service = FirestoreService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Professors'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Professors...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFF1E1E2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // Professor list
          Expanded(
            child: StreamBuilder<List<ProfessorModel>>(
              stream: _service.getProfessors(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.red.shade300)),
                  );
                }

                final professors = (snapshot.data ?? []).where((p) {
                  if (_searchQuery.isEmpty) return true;
                  return p.name.toLowerCase().contains(_searchQuery) ||
                      p.department.toLowerCase().contains(_searchQuery) ||
                      p.loginId.toLowerCase().contains(_searchQuery); // Still searching by loginId field which holds email
                }).toList();

                if (professors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline,
                            size: 72, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No Professors added yet'
                              : 'No matching Professors found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to add your first Professor',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: professors.length,
                  itemBuilder: (context, index) {
                    final professor = professors[index];
                    return _buildProfessorCard(professor);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProfessorDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Professor'),
      ),
    );
  }

  Widget _buildProfessorCard(ProfessorModel professor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFF1E1E2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person_rounded,
              color: Color(0xFF2196F3), size: 24),
        ),
        title: Text(
          professor.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                professor.department,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Email: ${professor.loginId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white.withOpacity(0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'edit') {
              _showProfessorDialog(professor: professor);
            } else if (value == 'allocate') {
              _showAllocateSubjectsDialog(professor);
            } else if (value == 'delete') {
              _confirmDelete(professor);
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
              value: 'allocate',
              child: Row(
                children: [
                  Icon(Icons.assignment_ind_outlined,
                      size: 20, color: Color(0xFFFF9800)),
                  SizedBox(width: 10),
                  Text('Allocate Subjects'),
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

  Future<void> _confirmDelete(ProfessorModel professor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Professor'),
        content: Text('Are you sure you want to delete "${professor.name}"?'),
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
      await _service.deleteProfessor(professor.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${professor.name} deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showProfessorDialog({ProfessorModel? professor}) async {
    final isEditing = professor != null;
    final nameCtrl = TextEditingController(text: professor?.name ?? '');
    final loginCtrl = TextEditingController(text: professor?.loginId ?? '');
    final passCtrl = TextEditingController(text: professor?.password ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Professor' : 'Add New Professor'),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  // Department field removed as the system is now CSE-only.
                  // It is hardcoded to 'Computer Science' during save.
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: loginCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: 'professor@example.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSaving = true);

                      final loginId = loginCtrl.text.trim();
                      final isTaken = await _service.isProfessorLoginIdTaken(
                        loginId,
                        excludeId: professor?.id,
                      );
                      if (isTaken) {
                        setDialogState(() => isSaving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email address is already taken!'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        return;
                      }

                      final model = ProfessorModel(
                        id: professor?.id ?? '',
                        name: nameCtrl.text.trim(),
                        department: 'Computer Science',
                        loginId: loginId,
                        password: passCtrl.text.trim(),
                      );

                      if (isEditing) {
                        await _service.updateProfessor(model);
                      } else {
                        await _service.addProfessor(model);
                      }

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEditing
                                ? 'Professor updated successfully'
                                : 'Professor added successfully'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );

    // nameCtrl.dispose();
    // loginCtrl.dispose();
    // passCtrl.dispose();
  }

  // ─── Subject Allocation Dialog ──────────────────────────────

  Future<void> _showAllocateSubjectsDialog(ProfessorModel professor) async {
    List<CourseModel> courses = [];
    List<AssignedSubject> currentAssignments =
        List.from(professor.assignedSubjects);
    bool isLoadingInitial = true;

    // State for the dialog
    String? selCourseId;
    CourseModel? selCourse;
    int? selSem;
    String? selDivision;
    List<DivisionModel> availableDivisions = [];
    List<SubjectModel> availableSubjects = [];
    bool isLoadingSubjects = false;
    bool isLoadingDivisions = false;

    // Load courses initially
    try {
      courses = await _service.getCoursesOnce();
      isLoadingInitial = false;
    } catch (e) {
      isLoadingInitial = false;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Allocate Subjects'),
                Text(
                  'Professor: ${professor.name}',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: 500,
              ),
              child: isLoadingInitial
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // List of already assigned subjects
                        if (currentAssignments.isNotEmpty) ...[
                          const Text(
                            'Current Assignments:',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF9800)),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: currentAssignments.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: Colors.white12),
                              itemBuilder: (context, index) {
                                final assign = currentAssignments[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(assign.subjectName,
                                      style: const TextStyle(fontSize: 13)),
                                  subtitle: Text(
                                    '${assign.courseName} | Sem ${assign.semester} | Div ${assign.divisionName}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        size: 18,
                                        color: Colors.red),
                                    onPressed: () {
                                      setDialogState(() {
                                        currentAssignments.removeAt(index);
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          const Divider(height: 24, color: Colors.white24),
                        ],

                        const Text(
                          'Add New Assignment:',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3)),
                        ),
                        const SizedBox(height: 12),

                        // Select Course
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selCourseId,
                          decoration: const InputDecoration(
                            labelText: 'Course',
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10),
                          ),
                          items: courses.map((c) {
                            return DropdownMenuItem(
                                value: c.id, child: Text(c.name));
                          }).toList(),
                          onChanged: (val) {
                            if (val == selCourseId) return;
                            setDialogState(() {
                              selCourseId = val;
                              selCourse =
                                  courses.firstWhere((c) => c.id == val);
                              selSem = null;
                              selDivision = null;
                              availableDivisions = [];
                              availableSubjects = [];
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Select Semester
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: selSem,
                          decoration: const InputDecoration(
                            labelText: 'Semester',
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10),
                          ),
                          items: selCourse == null
                              ? []
                              : List.generate(
                                  selCourse!.totalSemesters,
                                  (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('Sem ${i + 1}'))),
                          onChanged: (val) async {
                            if (val == null || val == selSem) return;
                            setDialogState(() {
                              selSem = val;
                              selDivision = null;
                              isLoadingDivisions = true;
                              isLoadingSubjects = true;
                              availableDivisions = [];
                              availableSubjects = [];
                            });
                            // Fetch divisions and subjects
                            try {
                              final divsFut = _service.getDivisionsOnce(
                                  courseId: selCourseId!, semester: val);
                              final subsFut = _service.getSubjectsOnce(
                                  courseId: selCourseId!, semester: val);
                              
                              final results = await Future.wait([divsFut, subsFut]);
                              
                              setDialogState(() {
                                availableDivisions = results[0] as List<DivisionModel>;
                                availableSubjects = results[1] as List<SubjectModel>;
                                isLoadingDivisions = false;
                                isLoadingSubjects = false;
                              });
                            } catch (e) {
                              setDialogState(() {
                                isLoadingDivisions = false;
                                isLoadingSubjects = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        // Select Division
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selDivision,
                          decoration: InputDecoration(
                            labelText: 'Division',
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            hintText: isLoadingDivisions ? 'Loading divisions...' : 'Select Division',
                          ),
                          items: availableDivisions.map((d) {
                            return DropdownMenuItem(
                                value: d.name, child: Text('Division ${d.name}'));
                          }).toList(),
                          onChanged: (val) {
                            setDialogState(() => selDivision = val);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Header for subjects list + Add All button
                        if (selDivision != null && (availableSubjects.isNotEmpty || isLoadingSubjects))
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Available Subjects:',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white38),
                              ),
                              if (availableSubjects.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () {
                                    if (selDivision == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please select a division first')),
                                      );
                                      return;
                                    }
                                    setDialogState(() {
                                      int addedCount = 0;
                                      for (var sub in availableSubjects) {
                                        final isAlreadyAssigned =
                                            currentAssignments.any(
                                                (a) => a.subjectId == sub.id && a.divisionName == selDivision);
                                        if (!isAlreadyAssigned) {
                                          currentAssignments
                                              .add(AssignedSubject(
                                            courseId: selCourse!.id,
                                            courseName: selCourse!.name,
                                            semester: selSem!,
                                            subjectId: sub.id,
                                            subjectName: sub.name,
                                            subjectCode: sub.subjectCode,
                                            divisionName: selDivision!,
                                          ));
                                          addedCount++;
                                        }
                                      }
                                      if (addedCount > 0) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Added $addedCount subjects'),
                                            duration:
                                                const Duration(seconds: 1),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.add_task, size: 16),
                                  label: const Text('Add All',
                                      style: TextStyle(fontSize: 11)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 4),

                        // Select Subject list
                        if (selDivision != null && isLoadingSubjects)
                          const Center(
                              child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ))
                        else if (selDivision != null && selSem != null && availableSubjects.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No subjects found',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.red)),
                          )
                        else if (selDivision != null && availableSubjects.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withOpacity(0.05),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: availableSubjects.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: Colors.white12),
                              itemBuilder: (context, index) {
                                 final sub = availableSubjects[index];
                                 final isAlreadyAssigned = currentAssignments
                                     .any((a) => a.subjectId == sub.id && a.divisionName == selDivision);

                                return ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  title: Text(sub.name,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: isAlreadyAssigned
                                              ? Colors.white54
                                              : Colors.white)),
                                  subtitle: Text(sub.subjectCode,
                                      style: const TextStyle(fontSize: 11)),
                                  trailing: isAlreadyAssigned
                                      ? const Icon(Icons.check_circle,
                                          size: 20, color: Colors.green)
                                      : const Icon(Icons.add_circle_outline,
                                          size: 20, color: Color(0xFF2196F3)),
                                  onTap: isAlreadyAssigned
                                      ? null
                                      : () {
                                          if (selDivision == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Please select a division first')),
                                            );
                                            return;
                                          }
                                          setDialogState(() {
                                            currentAssignments
                                                .add(AssignedSubject(
                                              courseId: selCourse!.id,
                                              courseName: selCourse!.name,
                                              semester: selSem!,
                                              subjectId: sub.id,
                                              subjectName: sub.name,
                                              subjectCode: sub.subjectCode,
                                              divisionName: selDivision!,
                                            ));
                                          });
                                        },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: (selCourseId == null ||
                        selSem == null ||
                        selDivision == null)
                    ? null
                    : () async {
                        await _service.updateProfessorSubjects(
                            professor.id, currentAssignments);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Assignments updated successfully'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}
