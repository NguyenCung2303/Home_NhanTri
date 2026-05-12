import 'package:flutter/material.dart';
import '../../../data/models/schedule_model.dart';
import '../../../data/repositories/schedule_repository.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleRepository _repository = ScheduleRepository();

  List<ScheduleModel> schedules = [];
  bool isLoading = false;

  Future<void> loadSchedules() async {
    isLoading = true;
    notifyListeners();

    schedules = await _repository.getAllSchedules();

    isLoading = false;
    notifyListeners();
  }

  Future<void> addSchedule(ScheduleModel schedule) async {
    await _repository.addSchedule(schedule);
    await loadSchedules();
  }

  Future<void> deleteSchedule(String id) async {
    await _repository.deleteSchedule(id);
    await loadSchedules();
  }
}