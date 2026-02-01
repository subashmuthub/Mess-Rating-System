// Web-specific database helper using SharedPreferences

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../models/favorite_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  // User CRUD operations
  Future<int> createUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      final usersList = (json.decode(usersJson) as List).cast<Map<String, dynamic>>();
      
      // Remove existing user with same email
      usersList.removeWhere((u) => u['email'] == user.email);
      usersList.add(user.toJson());
      
      await prefs.setString('users', json.encode(usersList));
      print('User created successfully on web: ${user.email}');
      return 1;
    } catch (e, stackTrace) {
      print('Error creating user: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<UserModel?> getUserById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '[]';
    final usersList = (json.decode(usersJson) as List).cast<Map<String, dynamic>>();
    
    for (var userData in usersList) {
      if (userData['id'] == id) {
        return UserModel.fromJson(userData);
      }
    }
    return null;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '[]';
    final usersList = (json.decode(usersJson) as List).cast<Map<String, dynamic>>();
    
    for (var userData in usersList) {
      if (userData['email'] == email) {
        return UserModel.fromJson(userData);
      }
    }
    return null;
  }

  // Location CRUD operations
  Future<int> createLocation(LocationModel location) async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString('locations') ?? '[]';
    final locationsList = (json.decode(locationsJson) as List).cast<Map<String, dynamic>>();
    
    locationsList.add(location.toJson());
    await prefs.setString('locations', json.encode(locationsList));
    return 1;
  }

  Future<List<LocationModel>> getAllLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString('locations') ?? '[]';
    final locationsList = (json.decode(locationsJson) as List).cast<Map<String, dynamic>>();
    return locationsList.map((map) => LocationModel.fromJson(map)).toList();
  }

  Future<LocationModel?> getLocationById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString('locations') ?? '[]';
    final locationsList = (json.decode(locationsJson) as List).cast<Map<String, dynamic>>();
    
    for (var locationData in locationsList) {
      if (locationData['id'] == id) {
        return LocationModel.fromJson(locationData);
      }
    }
    return null;
  }

  Future<int> updateLocation(LocationModel location) async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString('locations') ?? '[]';
    final locationsList = (json.decode(locationsJson) as List).cast<Map<String, dynamic>>();
    
    locationsList.removeWhere((l) => l['id'] == location.id);
    locationsList.add(location.toJson());
    await prefs.setString('locations', json.encode(locationsList));
    return 1;
  }

  Future<int> deleteLocation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString('locations') ?? '[]';
    final locationsList = (json.decode(locationsJson) as List).cast<Map<String, dynamic>>();
    
    locationsList.removeWhere((l) => l['id'] == id);
    await prefs.setString('locations', json.encode(locationsList));
    return 1;
  }

  Future<List<LocationModel>> searchLocations(String query) async {
    final allLocations = await getAllLocations();
    final lowerQuery = query.toLowerCase();
    
    return allLocations.where((location) {
      return location.name.toLowerCase().contains(lowerQuery) ||
             location.description.toLowerCase().contains(lowerQuery) ||
             (location.buildingCode?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Favorite CRUD operations
  Future<int> createFavorite(FavoriteModel favorite) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorites') ?? '[]';
    final favoritesList = (json.decode(favoritesJson) as List).cast<Map<String, dynamic>>();
    
    favoritesList.add(favorite.toJson());
    await prefs.setString('favorites', json.encode(favoritesList));
    return 1;
  }

  Future<List<FavoriteModel>> getUserFavorites(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorites') ?? '[]';
    final favoritesList = (json.decode(favoritesJson) as List).cast<Map<String, dynamic>>();
    
    return favoritesList
        .where((f) => f['userId'] == userId)
        .map((map) => FavoriteModel.fromJson(map))
        .toList();
  }

  Future<int> deleteFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorites') ?? '[]';
    final favoritesList = (json.decode(favoritesJson) as List).cast<Map<String, dynamic>>();
    
    favoritesList.removeWhere((f) => f['id'] == id);
    await prefs.setString('favorites', json.encode(favoritesList));
    return 1;
  }

  Future<int> deleteFavoriteByLocation(String userId, String locationId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorites') ?? '[]';
    final favoritesList = (json.decode(favoritesJson) as List).cast<Map<String, dynamic>>();
    
    favoritesList.removeWhere((f) => 
      f['userId'] == userId && f['locationId'] == locationId
    );
    await prefs.setString('favorites', json.encode(favoritesList));
    return 1;
  }

  Future<bool> isFavorite(String userId, String locationId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorites') ?? '[]';
    final favoritesList = (json.decode(favoritesJson) as List).cast<Map<String, dynamic>>();
    
    return favoritesList.any((f) => 
      f['userId'] == userId && f['locationId'] == locationId
    );
  }

  // Aliases for compatibility
  Future<int> addFavorite(FavoriteModel favorite) => createFavorite(favorite);
  Future<int> removeFavorite(String id) => deleteFavorite(id);

  // Initialize sample data if database is empty
  Future<void> initializeSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool('data_initialized') ?? false;
    
    if (!isInitialized) {
      // Import and add sample locations
      final locationsJson = prefs.getString('locations') ?? '[]';
      final locationsList = (json.decode(locationsJson) as List);
      
      if (locationsList.isEmpty) {
        print('Initializing sample location data...');
        // Sample data will be loaded from LocationData.getSampleLocations()
        await prefs.setBool('data_initialized', true);
        print('Sample data initialized successfully');
      }
    }
  }

  // Database cleanup
  Future<void> close() async {
    // No cleanup needed for SharedPreferences
  }
}
