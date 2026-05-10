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


// TODO: Sau khi migrate toàn bộ sang Firebase thì bỏ 2 dòng này
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
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Home Nhân Trí',
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF4F6FA),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF4F6FA),
            foregroundColor: Color(0xFF111827),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFEAF1FF),
            labelStyle: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}