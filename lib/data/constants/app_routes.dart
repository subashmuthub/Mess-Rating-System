/// Application route definitions
class AppRoutes {
  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  static const String splash = '/splash';

  // Main App Routes
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String map = '/map';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String favorites = '/favorites';
  static const String events = '/events';
  static const String admin = '/admin';

  // Detail Routes
  static const String locationDetails = '/location-details';
  static const String eventDetails = '/event-details';
  static const String navigation = '/navigation';
  static const String virtualTour = '/virtual-tour';

  // Initial route
  static const String initialRoute = login;

  /// Get route name from path
  static String getRouteName(String route) {
    return route.replaceAll('/', '').replaceAll('-', ' ').toUpperCase();
  }
}
