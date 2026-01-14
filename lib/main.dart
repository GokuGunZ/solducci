import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:solducci/routes/app_router.dart';
import 'package:solducci/service/context_manager.dart';
import 'package:solducci/service/task_service.dart';
import 'package:solducci/core/di/service_locator.dart';
import 'package:solducci/core/cache/cache_manager.dart';
import 'package:solducci/service/expense_service_cached.dart';
import 'package:solducci/service/group_service_cached.dart';
import 'package:solducci/service/profile_service_cached.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialize caching framework
/// - Registers cached services in CacheManager
/// - Sets up cross-service invalidation rules
/// - Preloads critical data for faster app startup
Future<void> _initializeCaching() async {
  // Services auto-register on first access (singletons)
  final expenseService = ExpenseServiceCached();
  final groupService = GroupServiceCached();
  final profileService = ProfileServiceCached();

  // Setup cross-service invalidation rules
  // When expenses change, invalidate groups cache (might affect group balances)
  CacheManager.instance.registerInvalidationRule(
    'expenses',
    ['groups'],
  );

  // Preload critical data in parallel
  await Future.wait([
    expenseService.ensureInitialized(),
    groupService.ensureInitialized(),
    profileService.ensureInitialized(),
  ]);

  // Debug diagnostics (only in debug mode)
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    debugPrint('✅ Caching framework initialized');
    CacheManager.instance.printGlobalDiagnostics();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Italian locale
  await initializeDateFormatting('it_IT', null);

  try {
    // Try loading from dart-define first (production builds)
    const supabaseUrlFromDefine = String.fromEnvironment('SUPABASE_URL');
    const supabaseKeyFromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

    String? supabaseUrl = supabaseUrlFromDefine.isNotEmpty
        ? supabaseUrlFromDefine
        : null;
    String? supabaseKey = supabaseKeyFromDefine.isNotEmpty
        ? supabaseKeyFromDefine
        : null;

    // Fallback to .env file for local development (flutter run)
    if (supabaseUrl == null || supabaseKey == null) {
      try {
        await dotenv.load(fileName: "assets/dev/.env");
        supabaseUrl = dotenv.env['SUPABASE_URL'];
        supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];
      } catch (e) {
        // .env file not found or can't be loaded - will check credentials below
      }
    }

    // Validate that we have the required credentials
    if (supabaseUrl == null ||
        supabaseKey == null ||
        supabaseUrl.isEmpty ||
        supabaseKey.isEmpty) {
      throw Exception(
        'Missing Supabase credentials.\n\n'
        'For local development: Create assets/dev/.env with SUPABASE_URL and SUPABASE_ANON_KEY\n'
        'For production builds: Use --dart-define to pass credentials',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

    // Initialize caching framework
    await _initializeCaching();

    // Setup dependency injection
    await setupServiceLocator();

    // Initialize TaskService with repository
    TaskService().initialize();

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
  } catch (e, stackTrace) {
    // Log error for debugging
    debugPrint('❌ INITIALIZATION ERROR: $e');
    debugPrint('Stack trace: $stackTrace');

    // Show user-friendly error screen instead of crashing
    runApp(ErrorApp(error: e.toString()));
    return;
  }

  runApp(const SolducciApp());
}

/// Error screen shown when app initialization fails
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solducci - Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red[700]),
                  const SizedBox(height: 24),
                  Text(
                    'Errore di Inizializzazione',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text(
                      error,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Controlla la configurazione e riavvia l\'app',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        scaffoldBackgroundColor: Colors
            .white, // CRITICAL: Allow background gradients to show through
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('it', 'IT'), Locale('en', 'US')],
      locale: const Locale('it', 'IT'),
      routerConfig: AppRouter.router,
    );
  }
}
