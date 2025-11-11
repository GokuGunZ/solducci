import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Splash screen that checks authentication status on app start
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Small delay for splash screen visibility
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Check if user is authenticated
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      // User is authenticated, go to home
      context.go('/home');
    } else {
      // User is not authenticated, go to login
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Icon(
              Icons.account_balance_wallet,
              size: 100,
              color: Colors.purple[700],
            ),
            const SizedBox(height: 24),
            // App name
            Text(
              'Solducci',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.purple[900],
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            CircularProgressIndicator(
              color: Colors.purple[700],
            ),
          ],
        ),
      ),
    );
  }
}
