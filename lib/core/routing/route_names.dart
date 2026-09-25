class RouteNames {
  RouteNames._();

  // Authentication Routes
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyOtp = '/verify-otp';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  
  // Officer Routes
  static const String officerDashboard = '/officer';
  static const String officerIncidents = '/officer/incidents';
  static const String officerIncidentDetails = '/officer/incidents/:id';
  static const String officerHistory = '/officer/history';

  // Worker Routes
  static const String workerDashboard = '/worker';
  static const String workerTasks = '/worker/tasks';
  static const String workerTaskDetails = '/worker/tasks/:id';
  static const String workerHistory = '/worker/history';

  // Shared Routes
  static const String notifications = '/notifications';
  static const String profile = '/profile';
}
