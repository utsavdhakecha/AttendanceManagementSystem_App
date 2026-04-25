import 'package:flutter/material.dart';
import '../models/student_model.dart';

/// A row tile for marking attendance — shows student info with a toggle switch.
class AttendanceTile extends StatelessWidget {
  final StudentModel student;
  final String status; // 'present' or 'absent'
  final bool isLocked;
  final ValueChanged<String> onToggle;

  const AttendanceTile({
    super.key,
    required this.student,
    required this.status,
    this.isLocked = false,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPresent = status == 'present';
    final isNotTaken = status == 'not_taken';
    final isOnLeave = status == 'on leave';

    final Color bgColor = isNotTaken 
        ? Colors.grey.withOpacity(0.08)
        : isOnLeave
            ? Colors.orange.withOpacity(0.08)
            : isPresent
                ? Colors.green.withOpacity(0.08)
                : Colors.red.withOpacity(0.08);

    final Color borderColor = isNotTaken 
        ? Colors.grey.withOpacity(0.3)
        : isOnLeave
            ? Colors.orange.withOpacity(0.3)
            : isPresent
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3);

    final Color avatarBgColor = isNotTaken 
        ? Colors.grey.shade100
        : isOnLeave
            ? Colors.orange.shade100
            : isPresent ? Colors.green.shade100 : Colors.red.shade100;

    final Color iconColor = isNotTaken 
        ? Colors.grey.shade700
        : isOnLeave
            ? Colors.orange.shade700
            : isPresent ? Colors.green.shade700 : Colors.red.shade700;

    final IconData? iconData = isNotTaken 
        ? null 
        : isOnLeave
            ? Icons.timer_outlined
            : isPresent ? Icons.check : Icons.close;

    final String statusText = isNotTaken ? 'N' : (isOnLeave ? 'L' : (isPresent ? 'P' : 'A'));
    final Color statusColor = isNotTaken ? Colors.grey : (isOnLeave ? Colors.orange : (isPresent ? Colors.green : Colors.red));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: avatarBgColor,
          child: isNotTaken 
              ? Text('N', style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 18))
              : Icon(iconData, color: iconColor),
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Enrollment: ${student.enrollmentNo}',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Toggle switch
            Switch(
              value: isPresent && !isNotTaken && !isOnLeave,
              activeColor: Colors.green,
              inactiveThumbColor: isNotTaken ? Colors.grey : (isOnLeave ? Colors.orange : Colors.red),
              onChanged: isLocked || isNotTaken || isOnLeave
                  ? null
                  : (_) => onToggle(isPresent ? 'absent' : 'present'),
            ),
          ],
        ),
      ),
    );
  }
}
