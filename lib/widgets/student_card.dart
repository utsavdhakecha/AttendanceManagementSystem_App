import 'package:flutter/material.dart';
import '../models/student_model.dart';

/// Card widget displaying student information with optional edit/delete actions.
class StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const StudentCard({
    super.key,
    required this.student,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      color: isSelected
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : theme.cardColor,
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isSelectionMode
              ? Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: theme.colorScheme.primary,
                  key: const ValueKey('checkbox'),
                )
              : CircleAvatar(
                  key: const ValueKey('avatar'),
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Enrollment: ${student.enrollmentNo}',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: isSelectionMode
            ? null
            : (onEdit != null || onDelete != null)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              color: theme.colorScheme.primary, size: 20),
                          onPressed: onEdit,
                          tooltip: 'Edit Student',
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              color: Colors.red.shade400, size: 20),
                          onPressed: onDelete,
                          tooltip: 'Delete Student',
                        ),
                    ],
                  )
                : null,
      ),
    );
  }
}
