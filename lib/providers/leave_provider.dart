import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/leave_request_model.dart';

class LeaveProvider with ChangeNotifier {
  List<LeaveRequestModel> _allRequests = [];
  List<LeaveRequestModel> _studentRequests = [];
  bool _isLoading = false;

  List<LeaveRequestModel> get allRequests => _allRequests;
  List<LeaveRequestModel> get studentRequests => _studentRequests;
  bool get isLoading => _isLoading;

  Future<void> fetchAllRequests() async {
    _isLoading = true;
    notifyListeners();
    _allRequests = await DatabaseHelper.instance.getLeaveRequests();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchStudentRequests(String studentId) async {
    _isLoading = true;
    notifyListeners();
    _studentRequests = await DatabaseHelper.instance.getLeaveRequestsByStudent(studentId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> applyForLeave(LeaveRequestModel request) async {
    await DatabaseHelper.instance.insertLeaveRequest(request);
    await fetchStudentRequests(request.studentId);
  }

  Future<void> updateRequestStatus(int requestId, String status) async {
    await DatabaseHelper.instance.updateLeaveRequestStatus(requestId, status);
    await fetchAllRequests();
  }

  Future<List<LeaveRequestModel>> getApprovedLeavesForDate(String date) async {
    return await DatabaseHelper.instance.getApprovedLeavesForDate(date);
  }
}
