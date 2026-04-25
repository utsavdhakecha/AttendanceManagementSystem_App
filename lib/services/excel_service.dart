import 'dart:convert';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../models/student_model.dart';
import '../models/timetable_model.dart';

/// Service to handle Excel file pick and parsing.
class ExcelService {
  /// Picks an Excel file and parses its contents into a list of StudentModel.
  /// Expected format: Sheet 1, Header row 1, 
  /// Row 2+ columns: Enrollment Number, Name.
  static Future<List<StudentModel>> pickAndParseStudents({
    required int semester,
    required String courseId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return [];

    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) return [];

    try {
      final decoder = SpreadsheetDecoder.decodeBytes(fileBytes);
      final List<StudentModel> students = [];

      for (var table in decoder.tables.keys) {
        final sheet = decoder.tables[table]!;
        
        for (int i = 1; i < sheet.rows.length; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty || row.length < 2) continue;

          final enrollmentNo = row[0]?.toString().trim() ?? '';
          final name = row[1]?.toString().trim() ?? '';

          if (name.isNotEmpty && enrollmentNo.isNotEmpty) {
            students.add(StudentModel(
              name: name,
              enrollmentNo: enrollmentNo.toUpperCase(),
              password: 'pass_${enrollmentNo.toLowerCase()}',
              semester: semester,
              courseId: courseId,
              courseName: 'Computer Science Engineering',
              createdAt: DateTime.now(),
            ));
          }
        }
        if (students.isNotEmpty) break;
      }
      return students;
    } catch (e) {
      print('Error decoding Student Excel: $e');
      return [];
    }
  }

  /// Picks an Excel file and parses its contents into a list of TimetableModel.
  static Future<List<TimetableModel>> pickAndParseTimetable() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return [];

    final file = result.files.first;
    final fileBytes = file.bytes;
    if (fileBytes == null) return [];

    final extension = file.extension?.toLowerCase();
    final List<TimetableModel> entries = [];

    if (extension == 'csv') {
      try {
        final csvString = utf8.decode(fileBytes);
        final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);
        
        for (int i = 1; i < csvTable.length; i++) {
          final row = csvTable[i];
          if (row.length < 5) continue;

          final day = row[0]?.toString().trim() ?? '';
          final startTime = row[1]?.toString().trim() ?? '';
          final endTime = row[2]?.toString().trim() ?? '';
          final className = row[3]?.toString().trim() ?? '';
          final subject = row[4]?.toString().trim() ?? '';

          if (day.isNotEmpty && startTime.isNotEmpty && endTime.isNotEmpty) {
            entries.add(TimetableModel(
              day: day,
              startTime: startTime,
              endTime: endTime,
              className: className,
              subject: subject,
            ));
          }
        }
      } catch (e) {
        print('Error parsing CSV: $e');
      }
    } else {
      try {
        final decoder = SpreadsheetDecoder.decodeBytes(fileBytes);
        for (var table in decoder.tables.keys) {
          final sheet = decoder.tables[table]!;
          for (int i = 1; i < sheet.rows.length; i++) {
            final row = sheet.rows[i];
            if (row.isEmpty || row.length < 5) continue;

            final day = row[0]?.toString().trim() ?? '';
            final startTime = row[1]?.toString().trim() ?? '';
            final endTime = row[2]?.toString().trim() ?? '';
            final className = row[3]?.toString().trim() ?? '';
            final subject = row[4]?.toString().trim() ?? '';

            if (day.isNotEmpty && startTime.isNotEmpty && endTime.isNotEmpty) {
              entries.add(TimetableModel(
                day: day,
                startTime: startTime,
                endTime: endTime,
                className: className,
                subject: subject,
              ));
            }
          }
          if (entries.isNotEmpty) break;
        }
      } catch (e) {
        print('Error decoding Timetable Excel: $e');
      }
    }
    return entries;
  }
}
