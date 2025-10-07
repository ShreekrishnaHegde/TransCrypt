import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transcrypt/screens/login_screen.dart';
import 'package:transcrypt/service/AuthService/AuthGate.dart';


// ✅ Initialize Supabase + dotenv for backend data fetching (History page etc.)
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase connection (for all backend interactions)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase Auth',
      // 🔹 If user is authenticated, route via AuthGate → MainScreen
      // 🔹 Otherwise show Login screen (your existing behavior)
      home: Login(),
    );
  }
}
