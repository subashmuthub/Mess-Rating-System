/// Firebase configuration
class FirebaseConfig {
  // Firebase Project Settings
  static const String projectId = 'campus-navigation-system-s7s';
  static const String apiKey = 'AIzaSyBgVtS9AV445fPlAppeH1RUWJDDgKgWuNc';
  static const String appId = '1:884067584071:android:b20f2441702dbcb1bac962';

  // Realtime Database
  static const bool enableOfflinePersistence = true;
  static const bool enableCaseSensitiveQueries = false;

  // Collections
  static const String usersCollection = 'users';
  static const String locationsCollection = 'locations';
  static const String favoritesCollection = 'favorites';
  static const String eventsCollection = 'events';
  static const String routesCollection = 'routes';
  static const String attendanceCollection = 'event_attendance';

  // Storage Paths
  static const String userProfilesPath = 'user_profiles';
  static const String locationImagesPath = 'location_images';
  static const String eventImagesPath = 'event_images';
}
