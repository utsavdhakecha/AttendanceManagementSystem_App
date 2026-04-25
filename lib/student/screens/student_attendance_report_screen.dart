import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/student_model.dart';
import '../../admin/services/firestore_service.dart';

class StudentAttendanceReportScreen extends StatefulWidget {
  final StudentModel student;

  const StudentAttendanceReportScreen({super.key, required this.student});

  @override
  State<StudentAttendanceReportScreen> createState() =>
      _StudentAttendanceReportScreenState();
}

class _StudentAttendanceReportScreenState
    extends State<StudentAttendanceReportScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];
  Map<String, List<Map<String, dynamic>>> _subjectWise = {};
  double _overallPercentage = 0;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);

    // Fetch directly from Firestore for real-time accuracy
    final data = await FirestoreService()
        .getStudentAttendance(widget.student.enrollmentNo);

    final Map<String, List<Map<String, dynamic>>> subjectWise = {};
    int totalPresent = 0;
    int totalEffective = 0;

    for (var rec in data) {
      final subName = rec['subject_name'] ?? 'Unknown';
      final status = rec['status'] as String;
      subjectWise.putIfAbsent(subName, () => []).add(rec);

      if (status != 'on leave') {
        totalEffective++;
        if (status == 'present') totalPresent++;
      }
    }

    if (mounted) {
      setState(() {
        _records = data;
        _subjectWise = subjectWise;
        _overallPercentage =
            totalEffective == 0 ? 0 : (totalPresent / totalEffective) * 100;
        _isLoading = false;
      });
    }
  }

  Future<void> _exportReport() async {
    setState(() => _isExporting = true);

    final List<List<String>> csvData = [
      ['Date', 'Subject', 'Status']
    ];

    for (var r in _records) {
      csvData.add([
        r['date']?.toString() ?? '',
        r['subject_name']?.toString() ?? 'Unknown',
        r['status']?.toString().toUpperCase() ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final dir = await getTemporaryDirectory();
    final fileName = 'Attendance_Report_${widget.student.enrollmentNo}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString);

    setState(() => _isExporting = false);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Attendance Report - ${widget.student.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share_rounded),
            onPressed: _isExporting ? null : _exportReport,
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverallCard(),
                      const SizedBox(height: 32),
                      const Text('Subject-wise Statistics',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ..._subjectWise.entries
                          .map((e) => _buildSubjectStatRow(e.key, e.value)),
                      const SizedBox(height: 32),
                      const Text('Recent Sessions',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      ..._records
                          .take(10)
                          .map((r) => _buildRecentRecordCard(r)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOverallCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overall Attendance',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text('${_overallPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: _overallPercentage / 100,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color:
                      _overallPercentage >= 75 ? Colors.green : Colors.orange,
                  strokeWidth: 8,
                ),
              ),
              Icon(
                _overallPercentage >= 75
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: _overallPercentage >= 75 ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectStatRow(
      String name, List<Map<String, dynamic>> sessions) {
    final effectiveSessions =
        sessions.where((s) => s['status'] != 'on leave').toList();
    int present =
        effectiveSessions.where((s) => s['status'] == 'present').length;
    double pct = effectiveSessions.isEmpty
        ? 0
        : (present / effectiveSessions.length) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              Text('$present/${sessions.length}',
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.05),
              color: pct >= 75
                  ? Colors.green
                  : (pct >= 50 ? Colors.orange : Colors.red),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withOpacity(0.5))),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRecordCard(Map<String, dynamic> record) {
    final status = record['status'] as String;
    final date = record['date'] as String;
    final isPresent = status == 'present';
    final isOnLeave = status == 'on leave';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF1E1E2A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        title: Text(record['subject_name'] ?? 'Subject'),
        subtitle: Text(date),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPresent
                ? Colors.green.withOpacity(0.1)
                : (isOnLeave
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: isPresent
                  ? Colors.green
                  : (isOnLeave ? Colors.orange : Colors.red),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded,
              size: 64, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('No attendance records found yet.',
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
