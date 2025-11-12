import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solducci/routes/app_router.dart';
import 'package:solducci/service/context_manager.dart';
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

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

    if (kDebugMode) {
      print('✅ Supabase initialized successfully');
      print('🚀 Starting Solducci app...');
    }

    // Initialize ContextManager if user is already logged in
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      if (kDebugMode) {
        print('🔧 User logged in, initializing ContextManager...');
      }
      await ContextManager().initialize();
      if (kDebugMode) {
        print('✅ ContextManager initialized');
      }
    }

    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        // User logged in
        if (kDebugMode) {
          print('🔧 User logged in, initializing ContextManager...');
        }
        await ContextManager().initialize();
      } else {
        // User logged out
        if (kDebugMode) {
          print('🔧 User logged out, clearing ContextManager...');
        }
        ContextManager().clear();
      }
    });
  } catch (e) {
    if (kDebugMode) {
      print('❌ FATAL ERROR during initialization: $e');
    }
    rethrow;
  }

  runApp(const SolducciApp());
}

/// Main app widget with GoRouter configuration
class SolducciApp extends StatelessWidget {
  const SolducciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Solducci',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}

