import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/views/splash_screen.dart';
import 'package:solducci/views/login_page.dart';
import 'package:solducci/views/signup_page.dart';
import 'package:solducci/views/shell_with_nav.dart';
import 'package:solducci/views/monthly_view.dart';
import 'package:solducci/views/category_view.dart';
import 'package:solducci/views/balance_view.dart';
import 'package:solducci/views/timeline_view.dart';
import 'package:solducci/views/placeholders/recurring_expenses_page.dart';
import 'package:solducci/views/placeholders/personal_expenses_page.dart';
import 'package:solducci/views/placeholders/notes_page.dart';
import 'package:solducci/views/documents/documents_home_view.dart';
import 'package:solducci/views/groups/create_group_page.dart';
import 'package:solducci/views/groups/group_detail_page.dart';
import 'package:solducci/views/groups/invite_member_page.dart';
import 'package:solducci/views/groups/pending_invites_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global router configuration for the app
/// Handles authentication state and navigation
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final isAuthenticated =
          Supabase.instance.client.auth.currentSession != null;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSignup = state.matchedLocation == '/signup';
      final isGoingToSplash = state.matchedLocation == '/';

      // If not authenticated and not going to auth pages, redirect to splash/login
      if (!isAuthenticated && !isGoingToLogin && !isGoingToSignup && !isGoingToSplash) {
        return '/login';
      }

      // If authenticated and going to auth pages, redirect to home
      if (isAuthenticated && (isGoingToLogin || isGoingToSignup || isGoingToSplash)) {
        return '/home';
      }

      return null; // No redirect needed
    },
    routes: [
      // Splash Screen (initial route)
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Routes (no shell)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),

      // Main App Shell with Bottom Navigation (single route with IndexedStack)
      GoRoute(
        path: '/home',
        builder: (context, state) => const ShellWithNav(),
      ),

      // Dashboard Detail Routes (full screen with back button)
      GoRoute(
        path: '/dashboard/monthly',
        builder: (context, state) => const MonthlyView(),
      ),
      GoRoute(
        path: '/dashboard/category',
        builder: (context, state) => const CategoryView(),
      ),
      GoRoute(
        path: '/dashboard/balance',
        builder: (context, state) => const BalanceView(),
      ),
      GoRoute(
        path: '/dashboard/timeline',
        builder: (context, state) => const TimelineView(),
      ),

      // Placeholder Routes (future features)
      GoRoute(
        path: '/recurring-expenses',
        builder: (context, state) => const RecurringExpensesPage(),
      ),
      GoRoute(
        path: '/personal-expenses',
        builder: (context, state) => const PersonalExpensesPage(),
      ),
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesPage(),
      ),

      // Documents/ToDo Routes
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentsHomeView(),
      ),

      // Group Management Routes
      GoRoute(
        path: '/groups/create',
        builder: (context, state) => const CreateGroupPage(),
      ),

      // Group detail
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) {
          final groupId = state.pathParameters['id']!;
          return GroupDetailPage(groupId: groupId);
        },
      ),

      // Invite member to group
      GoRoute(
        path: '/groups/:id/invite',
        builder: (context, state) {
          final groupId = state.pathParameters['id']!;
          final groupName = state.uri.queryParameters['name'] ?? 'Gruppo';
          return InviteMemberPage(
            groupId: groupId,
            groupName: groupName,
          );
        },
      ),

      // Pending invites
      GoRoute(
        path: '/invites/pending',
        builder: (context, state) => const PendingInvitesPage(),
      ),
    ],
  );
}

/// Refresh notifier that listens to Supabase auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (_) {
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
