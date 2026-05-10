import 'package:flutter/material.dart';

import '../../../data/models/class_room_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/class_room_repository.dart';

class ClassRoomProvider extends ChangeNotifier {
  final ClassRoomRepository _repository = ClassRoomRepository();

  List<ClassRoomModel> classRooms = [];
  List<UserModel> teachers = [];
  bool isLoading = false;

  Future<void> loadClassRooms() async {
    isLoading = true;
    notifyListeners();
    classRooms = await _repository.getAllClassRooms();
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadClassRoomsForTeacher(String teacherId) async {
    isLoading = true;
    notifyListeners();
    classRooms = await _repository.getClassRoomsForTeacher(teacherId);
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadTeachers() async {
    teachers = await _repository.getTeachers();
    notifyListeners();
  }

  Future<String?> getAssignedTeacherId(String classId) {
    return _repository.getAssignedTeacherId(classId);
  }

  Future<void> addClassRoom(ClassRoomModel classRoom, {String? teacherId}) async {
    await _repository.addClassRoom(classRoom, teacherId: teacherId);
    await loadClassRooms();
  }

  Future<void> updateClassRoom(ClassRoomModel classRoom, {String? teacherId}) async {
    await _repository.updateClassRoom(classRoom, teacherId: teacherId);
    await loadClassRooms();
  }

  Future<void> deleteClassRoom(String id) async {
    await _repository.deleteClassRoom(id);
    await loadClassRooms();
  }
}
