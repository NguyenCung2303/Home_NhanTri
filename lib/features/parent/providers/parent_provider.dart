import 'package:flutter/material.dart';
import '../../../data/models/parent_model.dart';
import '../../../data/repositories/parent_repository.dart';

class ParentProvider extends ChangeNotifier {
  final ParentRepository _repository = ParentRepository();

  List<ParentModel> parents = [];
  bool isLoading = false;

  Future<void> loadParents() async {
    isLoading = true;
    notifyListeners();

    parents = await _repository.getAllParents();

    isLoading = false;
    notifyListeners();
  }

  Future<void> addParent(ParentModel parent) async {
    await _repository.addParent(parent);
    await loadParents();
  }

  Future<void> deleteParent(String id) async {
    await _repository.deleteParent(id);
    await loadParents();
  }
}