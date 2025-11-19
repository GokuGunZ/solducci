import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solducci/routes/app_router.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: "assets/dev/.env");

    // Initialize Supabase with credentials from .env
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseKey == null) {
      throw Exception('Missing Supabase credentials in .env file');
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

    // Initialize ContextManager if user is already logged in
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await ContextManager().initialize();
    }

    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        // User logged in
        await ContextManager().initialize();
      } else {
        // User logged out
        ContextManager().clear();
      }
    });
  } catch (e) {
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

