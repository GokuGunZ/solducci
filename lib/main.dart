import 'package:flutter/material.dart';
import 'package:solducci/views/home.dart';
import 'package:solducci/utils/api/sheet_api.dart';
import 'package:solducci/views/login_page.dart';
import 'package:solducci/views/signup_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Supabase.initialize(
    url: "https://fpvzviseqayuxbxjvxea.supabase.co", 
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwdnp2aXNlcWF5dXhieGp2eGVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0MjUxMjYsImV4cCI6MjA3MzAwMTEyNn0.P7QaMitclyscuTB9KH6MxVPBPyh93pW0yniwBzuVJfk");
  await SheetApi.init();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
      routes: {
        '/loginpage' : (context) => const LoginPage(),
        '/signupage' : (context) => const SignupPage(),
      },
    ));
}
