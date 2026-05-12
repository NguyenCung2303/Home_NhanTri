import 'package:flutter/material.dart';
import '../../../data/models/study_shift_model.dart';
import '../../../data/repositories/study_shift_repository.dart';

class StudyShiftProvider extends ChangeNotifier {
  final StudyShiftRepository _repository = StudyShiftRepository();

  List<StudyShiftModel> shifts = [];
  bool isLoading = false;

  Future<void> loadStudyShifts() async {
    isLoading = true;
    notifyListeners();

    shifts = await _repository.getAllStudyShifts();

    isLoading = false;
    notifyListeners();
  }

  Future<void> addStudyShift(StudyShiftModel shift) async {
    await _repository.addStudyShift(shift);
    await loadStudyShifts();
  }

  Future<void> deleteStudyShift(String id) async {
    await _repository.deleteStudyShift(id);
    await loadStudyShifts();
  }
}