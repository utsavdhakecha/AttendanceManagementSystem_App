import 'package:flutter/material.dart';
import '../models/class_model.dart';

/// A visually rich card displaying class information.
class ClassCard extends StatelessWidget {
  final ClassModel classModel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isSelectionMode;

  const ClassCard({
    super.key,
    required this.classModel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onLongPress,
    this.isSelected = false,
    this.isSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      color: isSelected
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : theme.cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon badge or Selection checkbox
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelectionMode
                    ? Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: theme.colorScheme.primary,
                        key: const ValueKey('checkbox'),
                      )
                    : Container(
                        key: const ValueKey('icon'),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.class_outlined,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Class info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classModel.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      classModel.subject,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons (hide in selection mode)
              if (!isSelectionMode) ...[
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: theme.colorScheme.primary, size: 22),
                  onPressed: onEdit,
                  tooltip: 'Edit Class',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade400, size: 22),
                  onPressed: onDelete,
                  tooltip: 'Delete Class',
                ),
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
