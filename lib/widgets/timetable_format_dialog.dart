import 'package:flutter/material.dart';

/// Dialog showing the expected Excel format for timetable import.
class TimetableFormatDialog extends StatelessWidget {
  const TimetableFormatDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.info_outline, color: Color(0xFF6C63FF), size: 36),
      title: const Text('Excel Format Guide', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Excel file should have the following columns in order:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildSampleTable(),
            const SizedBox(height: 20),
            const Text(
              'Important Notes:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildNotePoint(
                'Time must be in 24-hour format (e.g., 14:00 for 2 PM).'),
            _buildNotePoint(
                'Use full day names like "Monday", "Tuesday", etc.'),
            _buildNotePoint(
                'Detailed Class Names are supported (e.g., "BCA Sem 1 - 101").'),
            _buildNotePoint(
                'The first row (Header) will be skipped automatically.'),
            _buildNotePoint('Ensure all 5 columns are present for each row.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 20, color: Colors.amber),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Importing a new file will replace your existing timetable.',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), // explicitly return false
          child: const Text('CANCEL', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), // explicitly return true on proceed
          child: const Text('PROCEED TO UPLOAD'),
        ),
      ],
    );
  }

  Widget _buildSampleTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder.all(color: Colors.white10, width: 1),
        children: [
          _buildTableRow(['Day', 'Start Time', 'End Time', 'Class', 'Subject'],
              isHeader: true),
          _buildTableRow(
              ['Monday', '10:00', '11:00', 'BCA Sem 1 - 101', 'Mobile']),
          _buildTableRow(
              ['Monday', '11:00', '12:00', 'BCA Sem 3 - 204', 'DBMS']),
        ],
      ),
    );
  }

  TableRow _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      children: cells
          .map((cell) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  cell,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                    color: isHeader ? const Color(0xFF6C63FF) : Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildNotePoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: Colors.white70))),
        ],
      ),
    );
  }
}
