import 'package:flutter/material.dart';
import 'package:transcrypt/screens/home_screen.dart';
import 'package:transcrypt/screens/login_screen.dart';
import 'package:transcrypt/service/AuthService/AuthService.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AuthGate extends StatelessWidget {
  AuthGate({super.key});
  final AuthService authService = AuthService();
  @override
  Widget build(BuildContext context) {

    return StreamBuilder<AuthState>(
      //Listen to the auth state change
      stream: Supabase.instance.client.auth.onAuthStateChange,
      //Build appropriate page based on auth change
      builder: (context,snapshot){
        final session = Supabase.instance.client.auth.currentSession;
        //Loading
        if(snapshot.connectionState==ConnectionState.waiting){
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        //check if there is a valid session currently

        if(session!=null){
          return HOME();
        }
        else{
          return const Login();
        }
      },
    );
  }
}