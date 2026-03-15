import 'package:flutter/material.dart';
import '../../../data/models/tuition_model.dart';
import '../../../data/repositories/tuition_repository.dart';

class TuitionProvider extends ChangeNotifier {
  final TuitionRepository _repository = TuitionRepository();

  List<TuitionModel> tuitions = [];
  bool isLoading = false;

  Future<void> loadTuitions() async {
    isLoading = true;
    notifyListeners();

    tuitions = await _repository.getAllTuitions();

    isLoading = false;
    notifyListeners();
  }

  Future<void> addTuition(TuitionModel tuition) async {
    await _repository.addTuition(tuition);
    await loadTuitions();
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