import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'presence_service.dart';
import 'auth_ui.dart';

/// Main entry point - Initialize Supabase and run app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your project credentials
 await Supabase.initialize(
    url: 'https://pltyvoxjdqqobrpfwndo.supabase.co', // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsdHl2b3hqZHFxb2JycGZ3bmRvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk5MTcwMDEsImV4cCI6MjA3NTQ5MzAwMX0.1L3eyWZJoyw-IOI57ao0nlD6MZTDozXTbR7A4SYjMzo', // Replace with your anon key
  );


  runApp(const MyApp());
}

/// Root application widget with provider setup
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PresenceService()),
      ],
      child: MaterialApp(
        title: 'Online Users Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
