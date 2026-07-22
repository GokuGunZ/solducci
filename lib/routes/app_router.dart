import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solducci/views/expense_list.dart';
import 'package:solducci/views/splash_screen.dart';
import 'package:solducci/views/login_page.dart';
import 'package:solducci/views/signup_page.dart';
import 'package:solducci/views/forgot_password_page.dart';
import 'package:solducci/views/new_homepage.dart';
import 'package:solducci/views/profile_page.dart';
import 'package:solducci/views/shell_with_nav.dart';
import 'package:solducci/views/monthly_view.dart';
import 'package:solducci/views/category_view.dart';
import 'package:solducci/views/timeline_view.dart';
import 'package:solducci/views/bento_dashboard_page.dart';
import 'package:solducci/views/placeholders/recurring_expenses_page.dart';
import 'package:solducci/views/placeholders/personal_expenses_page.dart';
import 'package:solducci/features/space/views/space_home_view.dart';
import 'package:solducci/features/space/views/space_document_list_view.dart';
import 'package:solducci/features/space/views/note_detail_view.dart';
import 'package:solducci/features/space/views/asterisk_detail_view.dart';
import 'package:solducci/features/space/views/resource_detail_view.dart';
import 'package:solducci/features/space/views/pantry_detail_view.dart';
import 'package:solducci/features/space/views/shopping_list_detail_view.dart';
import 'package:solducci/views/documents/documents_home_view.dart';
import 'package:solducci/features/time_management/views/time_management_hub.dart';
import 'package:solducci/features/time_management/views/routine_hub.dart';
import 'package:solducci/features/time_management/views/create_scenario_view.dart';
import 'package:solducci/features/time_management/views/create_trip_view.dart';
import 'package:solducci/features/time_management/views/create_event_view.dart';
import 'package:solducci/features/time_management/views/create_outing_view.dart';
import 'package:solducci/features/time_management/views/create_availability_view.dart';
import 'package:solducci/features/time_management/views/create_routine_view.dart';
import 'package:solducci/features/time_management/views/trip_detail_view.dart';
import 'package:solducci/features/time_management/views/event_detail_view.dart';
import 'package:solducci/features/time_management/views/outing_detail_view.dart';
import 'package:solducci/views/groups/create_group_page.dart';
import 'package:solducci/views/groups/group_detail_page.dart';
import 'package:solducci/views/groups/invite_member_page.dart';
import 'package:solducci/views/groups/pending_invites_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:solducci/views/hubs/important_hub_view.dart';
import 'package:solducci/views/hubs/economy_charts_hub_view.dart';
import 'package:solducci/features/time_management/views/focus_hub_view.dart';
import 'package:solducci/features/time_management/views/habit_hub_view.dart';
import 'package:solducci/views/groups/group_management_hub_view.dart';
import 'package:solducci/views/mosaico_view.dart';
import 'package:solducci/features/space/views/infinite_canvas_view.dart';

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
      final isGoingToForgotPassword = state.matchedLocation == '/forgot_password';
      final isGoingToSplash = state.matchedLocation == '/';

      // If not authenticated and not going to auth pages, redirect to splash/login
      if (!isAuthenticated &&
          !isGoingToLogin &&
          !isGoingToSignup &&
          !isGoingToForgotPassword &&
          !isGoingToSplash) {
        return '/login';
      }

      // If authenticated and going to auth pages, redirect to home
      if (isAuthenticated &&
          (isGoingToLogin || isGoingToSignup || isGoingToForgotPassword || isGoingToSplash)) {
        return '/home';
      }

      return null; // No redirect needed
    },
    routes: [
      // Splash Screen (initial route)
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

      // Auth Routes (no shell)
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
      GoRoute(path: '/forgot_password', builder: (context, state) => const ForgotPasswordPage()),

      // Main App Shell with Bottom Navigation (single route with IndexedStack)
      GoRoute(path: '/home', builder: (context, state) => const ShellWithNav()),

      GoRoute(
        path: '/expenses_dashboard',
        builder: (context, state) => const NewHomepage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/bento_dashboard',
        builder: (context, state) => const BentoDashboardPage(),
      ),
      GoRoute(
        path: '/expense_list',
        builder: (context, state) => const ExpenseList(),
      ),
      GoRoute(
        path: '/mosaico',
        builder: (context, state) => const MosaicoView(),
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
      


      // Space Feature Routes
      GoRoute(path: '/space', builder: (context, state) => const SpaceHomeView()),
      
      GoRoute(
        path: '/space/infinite_canvas',
        builder: (context, state) => const InfiniteCanvasView(),
      ),
      
      // Tasks
      GoRoute(
        path: '/space/tasks', 
        builder: (context, state) => const SpaceDocumentListView(type: 'todo', sectionLabel: 'Task'),
      ),
      GoRoute(
        path: '/space/tasks/:id',
        builder: (context, state) => const DocumentsHomeView(),
      ),

      // Notes
      GoRoute(
        path: '/space/notes', 
        builder: (context, state) => const SpaceDocumentListView(type: 'note', sectionLabel: 'Note'),
      ),
      GoRoute(
        path: '/space/notes/:id',
        builder: (context, state) => NoteDetailView(documentId: state.pathParameters['id']!),
      ),

      // Asterisks
      GoRoute(
        path: '/space/asterisks', 
        builder: (context, state) => const SpaceDocumentListView(type: 'asterisk', sectionLabel: 'Asterischi'),
      ),
      GoRoute(
        path: '/space/asterisks/:id',
        builder: (context, state) => AsteriskDetailView(documentId: state.pathParameters['id']!),
      ),

      // Resources
      GoRoute(
        path: '/space/resources', 
        builder: (context, state) => const SpaceDocumentListView(type: 'resource_list', sectionLabel: 'Risorse'),
      ),
      GoRoute(
        path: '/space/resources/:id',
        builder: (context, state) => ResourceDetailView(documentId: state.pathParameters['id']!),
      ),

      // Shopping (Must be before Pantry to avoid pattern conflict if any)
      GoRoute(
        path: '/space/shopping', 
        builder: (context, state) => const SpaceDocumentListView(type: 'shopping_list', sectionLabel: 'Liste Spesa'),
      ),
      GoRoute(
        path: '/space/shopping/:id',
        builder: (context, state) => ShoppingListDetailView(documentId: state.pathParameters['id']!),
      ),

      // Pantry
      GoRoute(
        path: '/space/pantry', 
        builder: (context, state) => const SpaceDocumentListView(type: 'dispensa', sectionLabel: 'Dispensa'),
      ),
      GoRoute(
        path: '/space/pantry/:id',
        builder: (context, state) => PantryDetailView(documentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/space/pantry/:pantryId/shopping/:id',
        builder: (context, state) => ShoppingListDetailView(documentId: state.pathParameters['id']!),
      ),

      // Time Management
      GoRoute(
        path: '/space/time_management',
        builder: (context, state) => const TimeManagementHub(),
      ),
      GoRoute(
        path: '/space/time_management/routines',
        builder: (context, state) => const RoutineHub(),
      ),
      GoRoute(
        path: '/space/time_management/create',
        builder: (context, state) => const CreateScenarioView(),
      ),
      GoRoute(
        path: '/space/time_management/create/trip',
        builder: (context, state) => const CreateTripView(),
      ),
      GoRoute(
        path: '/space/time_management/create/event',
        builder: (context, state) => const CreateEventView(),
      ),
      GoRoute(
        path: '/space/time_management/create/outing',
        builder: (context, state) => const CreateOutingView(),
      ),
      GoRoute(
        path: '/space/time_management/create/availability',
        builder: (context, state) => const CreateAvailabilityView(),
      ),
      GoRoute(
        path: '/space/time_management/scenario/trip/:id',
        builder: (context, state) => TripDetailView(scenarioId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/space/time_management/scenario/event/:id',
        builder: (context, state) => EventDetailView(scenarioId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/space/time_management/scenario/outing/:id',
        builder: (context, state) => OutingDetailView(scenarioId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/space/time_management/create_routine',
        builder: (context, state) => const CreateRoutineView(),
      ),

      // Group Management Routes
      GoRoute(
        path: '/groups/management',
        builder: (context, state) => const GroupManagementHubView(),
      ),
      GoRoute(
        path: '/groups/create',
        builder: (context, state) => const CreateGroupPage(),
      ),
      GoRoute(
        path: '/important',
        builder: (context, state) => const ImportantHubView(),
      ),
      GoRoute(
        path: '/economy/charts',
        builder: (context, state) => const EconomyChartsHubView(),
      ),
      GoRoute(
        path: '/focus',
        builder: (context, state) => const FocusHubView(),
      ),
      GoRoute(
        path: '/habits',
        builder: (context, state) => const HabitHubView(),
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
          return InviteMemberPage(groupId: groupId, groupName: groupName);
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
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
