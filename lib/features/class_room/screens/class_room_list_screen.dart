import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/class_room_model.dart';
import '../providers/class_room_provider.dart';

class ClassRoomListScreen extends StatefulWidget {
  const ClassRoomListScreen({super.key});

  @override
  State<ClassRoomListScreen> createState() => _ClassRoomListScreenState();
}

class _ClassRoomListScreenState extends State<ClassRoomListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ClassRoomProvider>().loadClassRooms());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClassRoomProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách lớp học'),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.classRooms.length,
              itemBuilder: (context, index) {
                final classRoom = provider.classRooms[index];
                return ListTile(
                  title: Text(classRoom.className),
                  subtitle: Text(
                    '${classRoom.classCode} • ${classRoom.level ?? 'Chưa có trình độ'} • ${classRoom.tuitionFee.toStringAsFixed(0)}đ',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => provider.deleteClassRoom(classRoom.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final now = DateTime.now().millisecondsSinceEpoch.toString();

          final classRoom = ClassRoomModel(
            id: now,
            classCode: 'CLS$now',
            className: 'Lớp mới $now',
            description: 'Lớp học mới tạo',
            level: 'Cơ bản',
            tuitionFee: 500000,
            maxStudents: 20,
            currentStudents: 0,
            roomName: 'Phòng A',
            status: 'OPENING',
            createdAt: DateTime.now().toIso8601String(),
          );

          await provider.addClassRoom(classRoom);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}