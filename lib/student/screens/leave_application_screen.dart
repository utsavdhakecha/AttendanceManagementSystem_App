import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/student_model.dart';
import '../../models/leave_request_model.dart';
import '../../providers/leave_provider.dart';
import 'package:intl/intl.dart';

class LeaveApplicationScreen extends StatefulWidget {
  final StudentModel student;

  const LeaveApplicationScreen({super.key, required this.student});

  @override
  State<LeaveApplicationScreen> createState() => _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState extends State<LeaveApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<LeaveProvider>(context, listen: false)
            .fetchStudentRequests(widget.student.enrollmentNo);
      }
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: const Color(0xFF1E1E2A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date range')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final leaveProvider = Provider.of<LeaveProvider>(context, listen: false);
      final request = LeaveRequestModel(
        studentId: widget.student.enrollmentNo,
        studentName: widget.student.name,
        fromDate: DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start),
        toDate: DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end),
        reason: _reasonController.text.trim(),
        appliedAt: DateTime.now().toIso8601String(),
      );

      await leaveProvider.applyForLeave(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave application submitted successfully!')),
        );
        _reasonController.clear();
        setState(() {
          _selectedDateRange = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit application: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
      ),
      body: Consumer<LeaveProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(theme),
                const SizedBox(height: 32),
                _buildApplicationForm(theme, dateFormat),
                const SizedBox(height: 48),
                const Divider(color: Colors.white12),
                const SizedBox(height: 32),
                Text(
                  'Your Leave History',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.studentRequests.isEmpty
                        ? _buildEmptyHistory()
                        : _buildHistoryList(provider.studentRequests, theme, dateFormat),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationForm(ThemeData theme, DateFormat dateFormat) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Leave Application',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Leave Duration',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Color(0xFF6C63FF), size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _selectedDateRange == null
                          ? 'Select Date Range'
                          : '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}',
                      style: TextStyle(
                        color: _selectedDateRange == null ? Colors.white54 : Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Reason for Leave',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Describe the reason for your leave...',
              hintStyle: const TextStyle(color: Colors.white24),
              fillColor: const Color(0xFF1E1E2A),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a reason';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Submit Request',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<LeaveRequestModel> requests, ThemeData theme, DateFormat dateFormat) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final statusColor = req.status == 'approved'
            ? Colors.green
            : req.status == 'rejected'
                ? Colors.red
                : Colors.orange;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF1E1E2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${req.fromDate} to ${req.toDate}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        req.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  req.reason,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  'Applied on: ${DateFormat('MMM dd, hh:mm a').format(DateTime.parse(req.appliedAt))}',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 48, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              'No previous leave requests found.',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Your request will be sent to the HOD for approval. Once approved, you will be marked "On Leave" in attendance.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
