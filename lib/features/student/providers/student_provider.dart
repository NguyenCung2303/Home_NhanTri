import 'package:flutter/material.dart';
import '../../../data/models/student_model.dart';
import '../../../data/repositories/student_repository.dart';

class StudentProvider extends ChangeNotifier {
  final StudentRepository _repository = StudentRepository();

  List<StudentModel> students = [];
  bool isLoading = false;

  Future<void> loadStudents() async {
    isLoading = true;
    notifyListeners();

    students = await _repository.getAllStudents();

    isLoading = false;
    notifyListeners();
  }

  Future<void> addStudent(StudentModel student) async {
    await _repository.addStudent(student);
    await loadStudents();
  }

  Future<void> deleteStudent(String id) async {
    await _repository.deleteStudent(id);
    await loadStudents();
  }
}