import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/leave_request_model.dart';
import '../../providers/leave_provider.dart';
import 'package:intl/intl.dart';

class LeaveRequestsScreen extends StatefulWidget {
  const LeaveRequestsScreen({super.key});

  @override
  State<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends State<LeaveRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveProvider>(context, listen: false).fetchAllRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: Consumer<LeaveProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final pending = provider.allRequests.where((r) => r.status == 'pending').toList();
          final approved = provider.allRequests.where((r) => r.status == 'approved').toList();
          final rejected = provider.allRequests.where((r) => r.status == 'rejected').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRequestList(pending, provider),
              _buildRequestList(approved, provider),
              _buildRequestList(rejected, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestList(List<LeaveRequestModel> requests, LeaveProvider provider) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            const Text('No requests found', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return _buildRequestCard(req, provider);
      },
    );
  }

  Widget _buildRequestCard(LeaveRequestModel req, LeaveProvider provider) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E1E2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        'Roll: ${req.studentId}',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(req.status),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 12),
                  Text(
                    '${req.fromDate} to ${req.toDate}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reason:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              req.reason,
              style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.4),
            ),
            if (req.status == 'pending') ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleAction(req, 'rejected', provider),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleAction(req, 'approved', provider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _handleAction(LeaveRequestModel req, String status, LeaveProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'approved' ? 'Approve Leave?' : 'Reject Leave?'),
        content: Text('Are you sure you want to $status this leave request for ${req.studentName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(status == 'approved' ? 'Approve' : 'Reject', style: TextStyle(color: status == 'approved' ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.updateRequestStatus(req.id!, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request ${status}ed successfully')),
        );
      }
    }
  }
}
