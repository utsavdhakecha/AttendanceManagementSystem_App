import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/class_model.dart';
import '../models/student_model.dart';
import '../providers/student_provider.dart';
import '../database/database_helper.dart';

/// Reports screen displaying attendance statistics for all students in a class.
class ReportsScreen extends StatefulWidget {
  final ClassModel classModel;

  const ReportsScreen({super.key, required this.classModel});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  bool _isExporting = false;
  List<_StudentReport> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    final studentProvider = context.read<StudentProvider>();
    final List<_StudentReport> reports = [];
    for (final student in studentProvider.students) {
      final present = await DatabaseHelper.instance
          .getPresentCountForClass(student.enrollmentNo, widget.classModel.id!);
      final onLeave = await DatabaseHelper.instance
          .getOnLeaveCountForClass(student.enrollmentNo, widget.classModel.id!);
      final total = await DatabaseHelper.instance
          .getTotalDaysForStudent(student.enrollmentNo, widget.classModel.id!);
      final effectiveTotal = total - onLeave;
      final absent = effectiveTotal - present;
      final percentage =
          effectiveTotal > 0 ? (present / effectiveTotal) * 100 : 0.0;
      reports.add(_StudentReport(
        student: student,
        present: present,
        absent: absent,
        total:
            total, // Still show total sessions but calculation uses effectiveTotal
        percentage: percentage,
      ));
    }

    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);

    // This would need a refactor for generateCsvData if kept,
    // but for now we'll mock the export for build stability.
    final List<List<String>> csvData = [
      ['Enrollment No', 'Name', 'Present', 'Absent', 'Total', 'Percentage']
    ];
    for (var r in _reports) {
      csvData.add([
        r.student.enrollmentNo,
        r.student.name,
        r.present.toString(),
        r.absent.toString(),
        r.total.toString(),
        '${r.percentage.toStringAsFixed(1)}%'
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final dir = await getTemporaryDirectory();
    final fileName =
        'attendance_${widget.classModel.name.replaceAll(' ', '_')}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString);

    setState(() => _isExporting = false);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Attendance Report - ${widget.classModel.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reports - ${widget.classModel.name}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share),
            tooltip: 'Export CSV',
            onPressed: _isExporting ? null : _exportCsv,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? _buildEmptyState(theme)
              : _buildReportList(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined,
              size: 80, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('No attendance data',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }

  Widget _buildReportList(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Enrollment No')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Present'), numeric: true),
                  DataColumn(label: Text('Absent'), numeric: true),
                  DataColumn(label: Text('Total'), numeric: true),
                  DataColumn(label: Text('Percentage'), numeric: true),
                ],
                rows: _reports.map((report) {
                  final color = report.percentage >= 75
                      ? Colors.green
                      : (report.percentage >= 50 ? Colors.orange : Colors.red);
                  return DataRow(cells: [
                    DataCell(Text(report.student.enrollmentNo)),
                    DataCell(Text(report.student.name)),
                    DataCell(Text(report.present.toString(),
                        style: const TextStyle(color: Colors.green))),
                    DataCell(Text(report.absent.toString(),
                        style: const TextStyle(color: Colors.red))),
                    DataCell(Text(report.total.toString())),
                    DataCell(Text('${report.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentReport {
  final StudentModel student;
  final int present;
  final int absent;
  final int total;
  final double percentage;

  _StudentReport({
    required this.student,
    required this.present,
    required this.absent,
    required this.total,
    required this.percentage,
  });
}
