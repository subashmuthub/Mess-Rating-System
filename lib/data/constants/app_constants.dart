/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Mess Management System';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'An intelligent navigation system to help you find your way around campus';

  // Campus Location
  static const double campusCenterLat = 9.1726;
  static const double campusCenterLng = 77.8718;

  // Navigation
  static const double locationSearchRadiusKm = 5.0;
  static const double navigationUpdateDistanceM = 10;
  static const double navigationAccuracyThresholdM = 20;

  // Timeouts
  static const Duration locationTimeoutDuration = Duration(seconds: 10);
  static const Duration navigationUpdateInterval = Duration(seconds: 5);
  static const Duration apiTimeoutDuration = Duration(seconds: 30);

  // Cache
  static const Duration locationCacheDuration = Duration(hours: 24);
  static const int maxCachedLocations = 1000;

  // Empty States
  static const String noLocationsMessage =
      'No locations available. Add locations from Admin Panel.';
  static const String noFavoritesMessage = 'No Favorites Yet';
  static const String noSearchResultsMessage = 'No results found';

  // Error Messages
  static const String locationDisabledError = 'Location services disabled';
  static const String locationPermissionError =
      'Location permission denied. Using fallback location.';
  static const String navigationError = 'Unable to get your current location';
  static const String firebaseInitError =
      'Failed to initialize Firebase. Some features may be unavailable.';

  // Labels
  static const String loginTitle = 'Login';
  static const String registerTitle = 'Register';
  static const String dashboardTitle = 'Dashboard';
  static const String mapTitle = 'Campus Map';
  static const String navigationTitle = 'Navigation';
  static const String profileTitle = 'Profile';
  static const String favoritesTitle = 'My Favorites';
  static const String adminTitle = 'Admin Panel';
  static const String searchTitle = 'Search';
  static const String eventsTitle = 'Events';
  static const String virtualTourTitle = '360° Virtual Tour';
}
