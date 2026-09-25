import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/officer/officer_shell.dart';
import '../../features/officer/officer_dashboard_screen.dart';
import '../../features/officer/officer_incidents_screen.dart';
import '../../features/officer/officer_incident_details_screen.dart';
import '../../features/officer/officer_history_screen.dart';
import '../../features/worker/worker_shell.dart';
import '../../features/worker/worker_dashboard_screen.dart';
import '../../features/worker/worker_tasks_screen.dart';
import '../../features/worker/worker_task_details_screen.dart';
import '../../features/worker/worker_history_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _officerNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'officer');
final GlobalKey<NavigatorState> _workerNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'worker');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: authState.isAuthenticated
        ? (authState.isOfficer ? RouteNames.officerDashboard : RouteNames.workerDashboard)
        : RouteNames.login,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.uri.path == RouteNames.login;

      // 1. Unauthenticated users must stay on login
      if (!isLoggedIn) {
        return isLoggingIn ? null : RouteNames.login;
      }

      // 2. Authenticated users going to login get redirected to their dashboard
      if (isLoggingIn) {
        return authState.isOfficer ? RouteNames.officerDashboard : RouteNames.workerDashboard;
      }

      // 3. Role-based guard: Workers cannot access officer routes
      if (authState.isWorker && state.uri.path.startsWith('/officer')) {
        return RouteNames.workerDashboard;
      }

      // 4. Role-based guard: Officers cannot access worker routes
      if (authState.isOfficer && state.uri.path.startsWith('/worker')) {
        return RouteNames.officerDashboard;
      }

      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Officer Shell & Nested Routes
      ShellRoute(
        navigatorKey: _officerNavigatorKey,
        builder: (context, state, child) => OfficerShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.officerDashboard,
            builder: (context, state) => const OfficerDashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.officerIncidents,
            builder: (context, state) => const OfficerIncidentsScreen(),
          ),
          GoRoute(
            path: RouteNames.officerHistory,
            builder: (context, state) => const OfficerHistoryScreen(),
          ),
        ],
      ),

      // Officer Incident Details (Outside shell for clean full screen)
      GoRoute(
        path: '/officer/incidents/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OfficerIncidentDetailsScreen(incidentId: id);
        },
      ),

      // Worker Shell & Nested Routes
      ShellRoute(
        navigatorKey: _workerNavigatorKey,
        builder: (context, state, child) => WorkerShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.workerDashboard,
            builder: (context, state) => const WorkerDashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.workerTasks,
            builder: (context, state) => const WorkerTasksScreen(),
          ),
          GoRoute(
            path: RouteNames.workerHistory,
            builder: (context, state) => const WorkerHistoryScreen(),
          ),
        ],
      ),

      // Worker Task Details (Outside shell for clean full screen)
      GoRoute(
        path: '/worker/tasks/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return WorkerTaskDetailsScreen(incidentId: id);
        },
      ),

      // Shared Global Routes (Notifications & Profile)
      GoRoute(
        path: RouteNames.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
