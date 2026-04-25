import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/class_model.dart';
import '../providers/student_provider.dart';
import '../providers/attendance_provider.dart';
import '../widgets/attendance_tile.dart';

/// Screen for marking daily attendance for all students in a class.
class AttendanceScreen extends StatefulWidget {
  final ClassModel classModel;

  const AttendanceScreen({super.key, required this.classModel});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final provider = context.read<AttendanceProvider>();
      if (provider.attendanceMap.isNotEmpty && !provider.isLocked) {
        setState(() {});
      } else if (provider.isLocked) {
        timer.cancel();
        setState(() {});
      }
    });
  }

  Future<void> _loadData() async {
    final studentProvider = context.read<StudentProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    if (mounted) {
      await attendanceProvider.loadAttendance(
        widget.classModel.id!,
        dateStr,
        studentProvider.students,
        classModel: widget.classModel,
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _loadData();
      _countdownTimer?.cancel();
      _startTimer();
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final studentProvider = context.read<StudentProvider>();
      await context
          .read<AttendanceProvider>()
          .saveAttendance(widget.classModel, dateStr, studentProvider.students);

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance saved successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance - ${widget.classModel.name}'),
        centerTitle: true,
        actions: [
          Consumer<AttendanceProvider>(
            builder: (context, attendanceProvider, _) {
              final isLocked = attendanceProvider.isLocked;
              return PopupMenuButton<String>(
                enabled: !isLocked,
                onSelected: (value) {
                  final students = context.read<StudentProvider>().students;
                  if (value == 'all_present') {
                    attendanceProvider.markAllPresent(students);
                  } else if (value == 'all_absent') {
                    attendanceProvider.markAllAbsent(students);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'all_present',
                    child: Text('Mark All Present'),
                  ),
                  const PopupMenuItem(
                    value: 'all_absent',
                    child: Text('Mark All Absent'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          InkWell(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(dateStr,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Spacer(),
                  _buildLockStatus(),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer2<StudentProvider, AttendanceProvider>(
              builder: (context, studentProvider, attendanceProvider, _) {
                if (studentProvider.isLoading || attendanceProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: studentProvider.students.length,
                  itemBuilder: (context, index) {
                    final student = studentProvider.students[index];
                    final isNotTaken = !attendanceProvider.isSessionSaved &&
                        attendanceProvider.isLocked;
                    final status = isNotTaken
                        ? 'not_taken'
                        : (attendanceProvider
                                .attendanceMap[student.enrollmentNo] ??
                            'present');
                    return AttendanceTile(
                      student: student,
                      status: status,
                      isLocked: attendanceProvider.isLocked,
                      onToggle: (_) =>
                          attendanceProvider.toggleStatus(student.enrollmentNo),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildLockStatus() {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLocked) {
          if (!provider.isSessionSaved) {
            return const Text('NOT TAKEN (LOCKED)',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 13));
          }
          return const Text('LOCKED',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
        }
        final remaining = provider.timeRemaining;
        if (remaining.inSeconds > 0) {
          final h = remaining.inHours;
          final m = (remaining.inMinutes % 60);
          final s = (remaining.inSeconds % 60);
          final timeStr = '${h}h ${m}m ${s}s';
          return Text('Locked in : $timeStr',
              style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 13));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSaveButton() {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed:
                  _isSaving || provider.isLocked ? null : _saveAttendance,
              child: Text(_isSaving ? 'Saving...' : 'Save Attendance'),
            ),
          ),
        );
      },
    );
  }
}
