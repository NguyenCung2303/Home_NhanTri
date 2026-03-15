import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

// services
import 'data/services/database_service.dart';
import 'data/services/seed_service.dart';

// providers
import 'features/auth/providers/auth_provider.dart';
import 'features/student/screens/student_list_screen.dart';
import 'features/student/providers/student_provider.dart';
import 'features/parent/providers/parent_provider.dart';
import 'features/class_room/providers/class_room_provider.dart';
import 'features/schedule/providers/study_shift_provider.dart';
import 'features/schedule/providers/schedule_provider.dart';
import 'features/tuition/providers/tuition_provider.dart';

// screens
import 'screens/login_screen.dart';
import 'features/parent/screens/parent_list_screen.dart';
import 'features/class_room/screens/class_room_list_screen.dart';
import 'package:app_nhan_tri/features/schedule/screens/study_shift_list_screen.dart';
import 'package:app_nhan_tri/features/schedule/screens/schedule_list_screen.dart';
import 'features/tuition/screens/tuition_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // khởi tạo firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // khởi tạo database local
  await DatabaseService.instance.database;

  // tạo dữ liệu mẫu
  await SeedService.seedInitialData();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => ParentProvider()),
        ChangeNotifierProvider(create: (_) => ClassRoomProvider()),
        ChangeNotifierProvider(create: (_) => StudyShiftProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => TuitionProvider()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Home Nhân Trí',
        home: TuitionListScreen(),
      ),
    );
  }
}