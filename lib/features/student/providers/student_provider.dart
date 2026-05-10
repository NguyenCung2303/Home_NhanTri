import 'package:flutter/material.dart';

import '../../../data/models/student_model.dart';
import '../../../data/repositories/student_repository.dart';

class StudentProvider extends ChangeNotifier {
  final StudentRepository _repository = StudentRepository();

  List<StudentModel> students = [];
  List<StudentModel> availableStudents = [];
  bool isLoading = false;

  Future<void> loadStudents() async {
    isLoading = true;
    notifyListeners();
    students = await _repository.getAllStudents();
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadStudentsByClass(String classId) async {
    isLoading = true;
    notifyListeners();
    students = await _repository.getStudentsByClass(classId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadAvailableStudentsForClass(String classId) async {
    isLoading = true;
    notifyListeners();
    availableStudents = await _repository.getAvailableStudentsForClass(classId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadStudentsByParentUserId(String userId) async {
    isLoading = true;
    notifyListeners();
    students = await _repository.getStudentsByParentUserId(userId);
    isLoading = false;
    notifyListeners();
  }

  /// [classId] nếu truyền vào sẽ tự động ghi vào bảng class_student
  Future<void> addStudent(StudentModel student, {String? classId}) async {
    await _repository.addStudent(student, classId: classId);
    await loadStudents();
  }

  Future<void> assignStudentsToClass(String classId, List<String> studentIds) async {
    await _repository.assignStudentsToClass(classId, studentIds);
    students = await _repository.getStudentsByClass(classId);
    availableStudents = await _repository.getAvailableStudentsForClass(classId);
    notifyListeners();
  }

  Future<void> removeStudentFromClass(String classId, String studentId) async {
    await _repository.removeStudentFromClass(classId, studentId);
    students = await _repository.getStudentsByClass(classId);
    availableStudents = await _repository.getAvailableStudentsForClass(classId);
    notifyListeners();
  }

  Future<void> updateStudent(StudentModel student) async {
    await _repository.updateStudent(student);
    await loadStudents();
  }

  Future<void> deleteStudent(String id) async {
    await _repository.deleteStudent(id);
    await loadStudents();
  }
}
