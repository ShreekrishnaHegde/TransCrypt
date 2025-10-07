import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService{
  final SupabaseClient _supabaseClient=Supabase.instance.client;

  //Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(String email,String password) async{
    return await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password
    );
  }
  //Sign Up with email and password
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String fullname,
    required String role,
  }) async{
    final response= await _supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {
        "full_name":fullname,
        "role":role,
      },
    );
    final user=response.user;
    if(user!=null){
      await sendUserProfile(id: user.id, email: user.email!, fullname: fullname, role: role);
    }
    return response;
  }
  //SignOut
  Future<void> signOut() async{
    return await _supabaseClient.auth.signOut();
  }
  //Get User email
  String? getCurrentUserEmail(){
    final session=_supabaseClient.auth.currentSession;
    final user=session?.user;
    return user?.email;
  }
  //Sending User profile to the MongoDB via Spring boot
  Future<void> sendUserProfile({
    required String id,
    required String email,
    required String fullname,
    required String role,
  }) async{
    final String baseUrl=dotenv.env['API_BASE_URL']!;
    final accessToken=_supabaseClient.auth.currentSession?.accessToken;
    final uri = Uri.parse(
        role == 'Customer'
            ? '$baseUrl/api/customer'
            : '$baseUrl/api/hotel'
    );
    final response=await http.post(
      uri,
      headers: {
        "Content-type":"application/json",
        "Authorization":"Bearer $accessToken",
      },
      body: jsonEncode({
        "supaId":id,
        "email":email,
        "fullname":fullname,
        "role":role,
      }),
    );

    if(response.statusCode!=200){
      print("Backend error: ${response.body}");
    }
  }

}