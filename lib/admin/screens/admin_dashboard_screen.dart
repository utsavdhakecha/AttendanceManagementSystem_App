import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
// import 'manage_hod_screen.dart'; // Removed as per request
import 'manage_professor_screen.dart';
import 'manage_subjects_screen.dart';
import 'manage_divisions_screen.dart';

/// Admin dashboard with summary cards and navigation to management screens.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  // int _hodCount = 0; // Removed
  int _professorCount = 0;
  int _subjectCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
    // Seed predefined courses and dummy students on first launch
    _firestoreService.seedCourses();
    _firestoreService.seedStudents();
  }

  Future<void> _loadCounts() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        // _firestoreService.getHodCount(), // Removed
        _firestoreService.getProfessorCount(),
        _firestoreService.getSubjectCount(),
      ]);
      if (mounted) {
        setState(() {
          // _hodCount = results[0]; // Removed
          _professorCount = results[0]; // Adjusted index
          _subjectCount = results[1]; // Adjusted index
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateTo(Widget screen) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
    // Reload counts after returning
    _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Logout',
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Attendance Management System',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Summary stats row
              Text(
                'Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 14),
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Row(
                      children: [
                        // HOD stat card removed
                        _buildStatCard(
                          icon: Icons.person_rounded,
                          label: 'Professors',
                          count: _professorCount,
                          color: const Color(0xFF2196F3),
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          icon: Icons.menu_book_rounded,
                          label: 'Subjects',
                          count: _subjectCount,
                          color: const Color(0xFFFF9800),
                        ),
                      ],
                    ),
              const SizedBox(height: 32),

              // Management tiles
              Text(
                'Management',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 14),
              // Manage HODs tile removed
              _buildManagementTile(
                icon: Icons.person_rounded,
                title: 'Manage Professors',
                subtitle: 'Add, edit or remove Professor accounts',
                color: const Color(0xFF2196F3),
                onTap: () => _navigateTo(const ManageProfessorScreen()),
              ),
              const SizedBox(height: 12),
              _buildManagementTile(
                icon: Icons.menu_book_rounded,
                title: 'Manage Subjects',
                subtitle: 'Add subjects for courses & semesters',
                color: const Color(0xFFFF9800),
                onTap: () => _navigateTo(const ManageSubjectsScreen()),
              ),
              const SizedBox(height: 12),
              _buildManagementTile(
                icon: Icons.grid_view_rounded,
                title: 'Manage Divisions',
                subtitle: 'Add divisions for courses & semesters',
                color: const Color(0xFF4CAF50),
                onTap: () => _navigateTo(const ManageDivisionsScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1E1E2A),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.3),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
