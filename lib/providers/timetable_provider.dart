import 'package:flutter/foundation.dart';
import '../models/timetable_model.dart';
import '../services/excel_service.dart';
import '../admin/services/firestore_service.dart';
import '../database/database_helper.dart';

/// Provider for managing the weekly timetable.
class TimetableProvider with ChangeNotifier {
  List<TimetableModel> _timetable = [];
  bool _isLoading = false;

  List<TimetableModel> get timetable => _timetable;
  bool get isLoading => _isLoading;

  /// Load the entire timetable from Firestore for a specific professor.
  Future<void> loadTimetable(String professorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await FirestoreService().getProfessorTimetable(professorId);
      _timetable = data.map((e) => TimetableModel.fromMap(e, firestoreDocId: e['doc_id'])).toList();
    } catch (e) {
      print('Error loading timetable: $e');
      _timetable = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Import timetable from an Excel file for a specific professor.
  /// Clears existing timetable in Firestore before importing new data.
  Future<bool> importFromExcel(String professorId) async {
    final entries = await ExcelService.pickAndParseTimetable();
    if (entries.isEmpty) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Add professorId to all models for mapping
      final mappedEntries = entries.map((e) {
        final map = e.toMap();
        map['professor_id'] = professorId;
        return map;
      }).toList();

      // Replace existing in Firestore
      await FirestoreService().replaceProfessorTimetable(professorId, mappedEntries);
      
      // Auto-sync classes locally to "My Classes" (keeps quick local UI intact)
      await syncUniqueClasses(entries);

      // Reload state
      final data = await FirestoreService().getProfessorTimetable(professorId);
      _timetable = data.map((e) => TimetableModel.fromMap(e, firestoreDocId: e['doc_id'])).toList();
    } catch (e) {
      print('Error importing: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Delete a single timetable entry.
  Future<void> deleteTimetableEntry(TimetableModel entry) async {
    if (entry.docId != null) {
      await FirestoreService().deleteTimetableEntry(entry.docId!);
      _timetable.removeWhere((e) => e.docId == entry.docId);
      notifyListeners();
    } else if (entry.id != null) {
      // Fallback for any legacy entries currently active
      await DatabaseHelper.instance.deleteTimetableEntry(entry.id!);
      _timetable.removeWhere((e) => e.id == entry.id);
      notifyListeners();
    }
  }

  /// Clear all entries from the timetable.
  Future<void> clearTimetable(String professorId) async {
    await FirestoreService().clearProfessorTimetable(professorId);
    _timetable = [];
    notifyListeners();
  }

  /// Get entries for a specific day.
  List<TimetableModel> getEntriesForDay(String day) {
    return _timetable.where((e) => e.day.toLowerCase() == day.toLowerCase()).toList();
  }

  /// Extracts unique (Class, Subject) pairs from the timetable and 
  /// ensures they exist in the local classes table.
  Future<void> syncUniqueClasses([List<TimetableModel>? entries]) async {
    final targetEntries = entries ?? _timetable;
    final Set<String> uniquePairs = {};
    for (final entry in targetEntries) {
      uniquePairs.add('${entry.className}|${entry.subject}');
    }

    for (final pair in uniquePairs) {
      final parts = pair.split('|');
      final name = parts[0];
      final subject = parts[1];
      await DatabaseHelper.instance.upsertClassByNameAndSubject(name, subject);
    }
  }
}
