import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/hod_model.dart';
import '../../models/attendance_session_model.dart';
import '../../admin/services/firestore_service.dart';
import 'leave_requests_screen.dart';

class HodDashboardScreen extends StatefulWidget {
  final HodModel hod;

  const HodDashboardScreen({super.key, required this.hod});

  @override
  State<HodDashboardScreen> createState() => _HodDashboardScreenState();
}

class _HodDashboardScreenState extends State<HodDashboardScreen> {
  final FirestoreService _service = FirestoreService();

  // Filter state
  String? _selProfessor;
  String? _selCourse;
  int? _selSem;
  String? _selSubject;

  List<AttendanceSessionModel> _allSessions = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _service.getAttendanceSessions().listen((sessions) {
      if (mounted) {
        setState(() {
          _allSessions = sessions;
          _isLoading = false;
        });
      }
    });
  }

  List<AttendanceSessionModel> get _filteredSessions {
    return _allSessions.where((s) {
      if (_selProfessor != null && s.professorName != _selProfessor)
        return false;
      if (_selCourse != null && s.courseName != _selCourse) return false;
      if (_selSem != null && s.semester != _selSem) return false;
      if (_selSubject != null && s.subjectName != _selSubject) return false;
      return true;
    }).toList();
  }

  Map<String, int> _calculateStats(List<AttendanceSessionModel> sessions) {
    int totalPresent = 0;
    int totalAbsent = 0;
    for (var s in sessions) {
      totalPresent += s.presentCount;
      totalAbsent += s.absentCount;
    }
    return {'present': totalPresent, 'absent': totalAbsent};
  }

  Future<void> _exportFilteredSessions() async {
    setState(() => _isExporting = true);

    final filtered = _filteredSessions;
    final List<List<String>> csvData = [
      [
        'Date',
        'Subject',
        'Professor',
        'Course',
        'Sem',
        'Present',
        'Absent',
        'On Leave',
        'Total',
        'Percentage'
      ]
    ];

    for (var s in filtered) {
      final effectiveTotal = s.presentCount + s.absentCount;
      final perc = effectiveTotal == 0
          ? "0.0"
          : (s.presentCount / effectiveTotal * 100).toStringAsFixed(1);
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(s.timestamp);

      csvData.add([
        dateStr,
        s.subjectName,
        s.professorName,
        s.courseName,
        s.semester.toString(),
        s.presentCount.toString(),
        s.absentCount.toString(),
        s.leaveCount.toString(),
        s.totalStudents.toString(),
        '$perc%',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final dir = await getTemporaryDirectory();
    final fileName =
        'Attendance_Summary_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString);

    setState(() => _isExporting = false);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'HOD Attendance Summary Report',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredSessions;
    final stats = _calculateStats(filtered);
    final total = stats['present']! + stats['absent']!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HOD Dashboard'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.share_rounded),
            onPressed: _isExporting ? null : _exportFilteredSessions,
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.assignment_ind_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LeaveRequestsScreen()),
            ),
            tooltip: 'Leave Requests',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Header
                _buildFilterBar(),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Visualization Card
                      if (total > 0)
                        _buildVisualizationCard(stats, total)
                      else
                        _buildEmptyStatsCard(),

                      const SizedBox(height: 24),

                      // Session List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Attendance Sessions (${filtered.length})',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (_hasActiveFilters)
                            TextButton(
                              onPressed: _clearFilters,
                              child: const Text('Clear Filters',
                                  style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Session List
                      if (filtered.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Text('No sessions match your filters',
                                style: TextStyle(color: Colors.white54)),
                          ),
                        )
                      else
                        ...filtered.map((s) => _buildSessionCard(s)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  bool get _hasActiveFilters =>
      _selProfessor != null ||
      _selCourse != null ||
      _selSem != null ||
      _selSubject != null;

  void _clearFilters() {
    setState(() {
      _selProfessor = null;
      _selCourse = null;
      _selSem = null;
      _selSubject = null;
    });
  }

  Widget _buildFilterBar() {
    // Extract unique values for filters
    final profs = _allSessions.map((s) => s.professorName).toSet().toList()
      ..sort();
    final courses = _allSessions.map((s) => s.courseName).toSet().toList()
      ..sort();
    final sems = _allSessions.map((s) => s.semester).toSet().toList()..sort();
    final subs = _allSessions.map((s) => s.subjectName).toSet().toList()
      ..sort();

    return Container(
      height: 60,
      width: double.infinity,
      color: const Color(0xFF1E1E2A),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _buildFilterChip('Professor', profs, _selProfessor,
              (val) => setState(() => _selProfessor = val)),
          const SizedBox(width: 8),
          _buildFilterChip('Course', courses, _selCourse,
              (val) => setState(() => _selCourse = val)),
          const SizedBox(width: 8),
          _buildFilterChip('Semester', sems.map((e) => 'Sem $e').toList(),
              _selSem != null ? 'Sem $_selSem' : null, (val) {
            setState(() =>
                _selSem = val != null ? int.parse(val.split(' ').last) : null);
          }),
          const SizedBox(width: 8),
          _buildFilterChip('Subject', subs, _selSubject,
              (val) => setState(() => _selSubject = val)),
        ],
      ),
    );
  }

  Widget _buildFilterChip<T>(String label, List<String> options,
      String? selectedValue, Function(String?) onSelected) {
    return PopupMenuButton<String>(
      onSelected: (val) => onSelected(val == 'All' ? null : val),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'All', child: Text('All')),
        ...options.map((o) => PopupMenuItem(value: o, child: Text(o))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedValue != null
              ? Colors.blue.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selectedValue != null ? Colors.blue : Colors.white12),
        ),
        child: Row(
          children: [
            Text(
              selectedValue ?? label,
              style: TextStyle(
                fontSize: 12,
                color: selectedValue != null ? Colors.blue : Colors.white70,
                fontWeight:
                    selectedValue != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down,
                size: 16,
                color: selectedValue != null ? Colors.blue : Colors.white30),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizationCard(Map<String, int> stats, int total) {
    final presentPerc = (stats['present']! / total * 100).toStringAsFixed(1);
    final absentPerc = (stats['absent']! / total * 100).toStringAsFixed(1);

    return Card(
      color: const Color(0xFF1E1E2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Overall Attendance Ratio',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.greenAccent,
                      value: stats['present']!.toDouble(),
                      title: '$presentPerc%',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    PieChartSectionData(
                      color: Colors.redAccent,
                      value: stats['absent']!.toDouble(),
                      title: '$absentPerc%',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                    'Present', Colors.greenAccent, stats['present']!),
                const SizedBox(width: 24),
                _buildLegendItem('Absent', Colors.redAccent, stats['absent']!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStatsCard() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text('No data for visualization',
            style: TextStyle(color: Colors.white24)),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label: $count',
            style: const TextStyle(fontSize: 13, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSessionCard(AttendanceSessionModel session) {
    final dateStr = DateFormat('MMM dd, yyyy HH:mm').format(session.timestamp);
    final effectiveTotal = session.presentCount + session.absentCount;
    final perc = effectiveTotal == 0
        ? "0.0"
        : (session.presentCount / effectiveTotal * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1E1E2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        title: Text(session.subjectName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('${session.professorName} | $dateStr',
            style: const TextStyle(fontSize: 12, color: Colors.white54)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$perc%',
              style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                _buildInfoRow('Course', session.courseName),
                _buildInfoRow('Semester', 'Sem ${session.semester}'),
                _buildInfoRow('Present', session.presentCount.toString()),
                _buildInfoRow('Absent', session.absentCount.toString()),
                _buildInfoRow('On Leave', session.leaveCount.toString()),
                _buildInfoRow('Total', session.totalStudents.toString()),
                const SizedBox(height: 12),
                const Text('Student Status:',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: session.studentDetails.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.white12),
                    itemBuilder: (ctx, index) {
                      final detail = session.studentDetails[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(detail['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.white70)),
                                  Text('Roll: ${detail['enrollmentNo'] ?? '-'}',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.white38)),
                                ],
                              ),
                            ),
                            if (detail['status'] == 'on leave')
                              const Text('ON LEAVE',
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold))
                            else
                              Icon(
                                detail['status'] == 'present'
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 16,
                                color: detail['status'] == 'present'
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.white38)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
