import 'package:flutter/material.dart';
import '../../../data/models/tuition_model.dart';
import '../../../data/repositories/tuition_repository.dart';

class TuitionProvider extends ChangeNotifier {
  final TuitionRepository _repository = TuitionRepository();

  List<TuitionModel> tuitions = [];
  bool isLoading = false;

  Future<void> loadTuitions({String? parentUserId}) async {
    isLoading = true;
    notifyListeners();

    await _repository.refreshOverdueStatuses();
    tuitions = parentUserId == null
        ? await _repository.getAllTuitions()
        : await _repository.getTuitionsByParentUserId(parentUserId);

    isLoading = false;
    notifyListeners();
  }

  Future<void> addTuition(TuitionModel tuition) async {
    await _repository.addTuition(tuition);
    await loadTuitions();
  }

  Future<int> generateMonthlyTuitionsForClass({
    required String classId,
    required String tuitionPeriod,
    required String dueDate,
    String? note,
  }) async {
    final count = await _repository.generateMonthlyTuitionsForClass(
      classId: classId,
      tuitionPeriod: tuitionPeriod,
      dueDate: dueDate,
      note: note,
    );
    await loadTuitions();
    return count;
  }

  Future<void> deleteTuition(String id) async {
    await _repository.deleteTuition(id);
    await loadTuitions();
  }

  Future<void> markAsPaid(String id) async {
    await _repository.markAsPaid(id);
    await loadTuitions();
  }
}
