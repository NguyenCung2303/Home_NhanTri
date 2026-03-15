import 'package:flutter/material.dart';
import '../../../data/models/class_room_model.dart';
import '../../../data/repositories/class_room_repository.dart';

class ClassRoomProvider extends ChangeNotifier {
  final ClassRoomRepository _repository = ClassRoomRepository();

  List<ClassRoomModel> classRooms = [];
  bool isLoading = false;

  Future<void> loadClassRooms() async {
    isLoading = true;
    notifyListeners();

    classRooms = await _repository.getAllClassRooms();

    isLoading = false;
    notifyListeners();
  }

  Future<void> addClassRoom(ClassRoomModel classRoom) async {
    await _repository.addClassRoom(classRoom);
    await loadClassRooms();
  }

  Future<void> deleteClassRoom(String id) async {
    await _repository.deleteClassRoom(id);
    await loadClassRooms();
  }
}