import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/timetable_provider.dart';
import '../providers/class_provider.dart';
import '../widgets/timetable_format_dialog.dart';
import '../models/professor_model.dart';
import '../models/timetable_model.dart';

/// Screen displaying the weekly timetable for the professor.
/// Allows importing from Excel and manual entry based on assigned subjects.
class TimetableScreen extends StatefulWidget {
  final ProfessorModel professor;
  const TimetableScreen({super.key, required this.professor});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);

    // Load data on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TimetableProvider>().loadTimetable(widget.professor.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleImport() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => const TimetableFormatDialog(),
    );

    if (proceed != true) return;

    if (!mounted) return;
    final success = await context.read<TimetableProvider>().importFromExcel(widget.professor.id);

    if (!mounted) return;
    if (success) {
      _refreshClassesWithTodayPriority();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timetable & Classes sync successful!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _refreshClassesWithTodayPriority() {
    final now = DateTime.now();
    String today = DateFormat('EEEE').format(now);
    if (now.weekday == DateTime.sunday) today = 'Monday';

    final timetableProvider = context.read<TimetableProvider>();
    final todayLectures = timetableProvider.getEntriesForDay(today);
    final todayClassKeys =
        todayLectures.map((e) => '${e.className}|${e.subject}').toList();

    context.read<ClassProvider>().loadClasses(todayClassKeys: todayClassKeys);
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Table'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days.map((day) => Tab(text: day)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import Excel',
            onPressed: _handleImport,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All',
            onPressed: () => _confirmClearAll(),
          ),
        ],
      ),
      body: Consumer<TimetableProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: _days.map((day) {
              final entries = provider.getEntriesForDay(day);

              if (entries.isEmpty) {
                return _buildEmptyState(day);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: const Color(0xFF1E1E2A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.access_time,
                            color: theme.colorScheme.primary),
                      ),
                      title: Text(
                        entry.subject,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${entry.startTime} - ${entry.endTime}',
                              style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text('Class: ${entry.className}',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6))),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 20),
                        onPressed: () => _confirmDeleteEntry(entry),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String day) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text(
            'No lectures scheduled for $day.',
            style: const TextStyle(color: Colors.white30),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _handleImport,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import'),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _confirmDeleteEntry(TimetableModel entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lecture?'),
        content: Text('Remove "${entry.subject}" from ${entry.day}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              context.read<TimetableProvider>().deleteTimetableEntry(entry);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Time Table?'),
        content: const Text(
            'All existing schedule entries will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              context.read<TimetableProvider>().clearTimetable(widget.professor.id);
              Navigator.pop(context);
            },
            child: const Text('CLEAR ALL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
