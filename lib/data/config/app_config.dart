/// Application configuration
class AppConfig {
  // Environment
  static const String environment = 'development'; // development, staging, production
  static const bool debugMode = true;
  static const bool verboseLogging = true;

  // Feature Flags
  static const bool enableOfflineMaps = true;
  static const bool enableVoiceNavigation = true;
  static const bool enableEventSharing = true;
  static const bool enableAdminPanel = true;
  static const bool enableGuestAccess = true;
  static const bool enableMaintenanceMode = false;

  // Permissions
  static const List<String> requiredPermissions = [
    'location',
    'camera',
    'microphone',
  ];

  // Display Settings
  static const Duration splashScreenDuration = Duration(seconds: 2);
  static const Duration loadingAnimationDuration = Duration(milliseconds: 500);
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 2.0;

  // API Settings
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
