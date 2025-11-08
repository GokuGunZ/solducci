import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solducci/views/expense_list.dart';
import 'package:solducci/views/login_page.dart';
import 'package:solducci/views/signup_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    if (kDebugMode) {
      print('🔧 Loading environment variables...');
    }
    await dotenv.load(fileName: "assets/dev/.env");
    if (kDebugMode) {
      print('✅ Environment variables loaded successfully');
    }

    // Initialize Supabase with credentials from .env
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseKey == null) {
      throw Exception('Missing Supabase credentials in .env file');
    }

    if (kDebugMode) {
      print('🔧 Initializing Supabase...');
      print('   URL: $supabaseUrl');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    if (kDebugMode) {
      print('✅ Supabase initialized successfully');
      print('🚀 Starting Solducci app...');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ FATAL ERROR during initialization: $e');
    }
    rethrow;
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
        home: ExpenseList(),  
//      home: Homepage(),
      routes: {
        '/loginpage' : (context) => const LoginPage(),
        '/signupage' : (context) => const SignupPage(),
      },
    ));
}
