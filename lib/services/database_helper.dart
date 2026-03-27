// Web-specific database helper using SharedPreferences

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../models/favorite_model.dart';
import '../models/event_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  // User CRUD operations
  Future<int> createUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      final usersList = (json.decode(usersJson) as List)
          .cast<Map<String, dynamic>>();

      // Remove existing user with same email
      usersList.removeWhere((u) => u['email'] == user.email);
      usersList.add(user.toJson());

      await prefs.setString('users', json.encode(usersList));
      debugPrint('User created successfully on web: ${user.email}');
      return 1;
    } catch (e, stackTrace) {
      debugPrint('Error creating user: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<UserModel?> getUserById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '[]';
    final usersList = (json.decode(usersJson) as List)
        .cast<Map<String, dynamic>>();

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
    final usersList = (json.decode(usersJson) as List)
        .cast<Map<String, dynamic>>();

    for (var userData in usersList) {
      if (userData['email'] == email) {
        return UserModel.fromJson(userData);
      }
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users') ?? '[]';
    final usersList = (json.decode(usersJson) as List)
        .cast<Map<String, dynamic>>();
    return usersList.map((map) => UserModel.fromJson(map)).toList();
  }

  Future<Map<UserRole, int>> getUserRoleCounts() async {
    final users = await getAllUsers();
    final counts = {
      UserRole.student: 0,
      UserRole.faculty: 0,
      UserRole.visitor: 0,
      UserRole.admin: 0,
    };

    for (final user in users) {
      counts[user.role] = (counts[user.role] ?? 0) + 1;
    }

    return counts;
  }

  // Location CRUD operations
  Future<int> createLocation(LocationModel location) async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString('locations') ?? '[]';
    final locationsList = (json.decode(locationsJson) as List)
        .cast<Map<String, dynamic>>();

    locationsList.add(location.toJson());
    await prefs.setString('locations', json.encode(locationsList));
    return 1;
  }

  Future<List<LocationModel>> getAllLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString('locations') ?? '[]';
    final locationsList = (json.decode(locationsJson) as List)
        .cast<Map<String, dynamic>>();
    return locationsList.map((map) => LocationModel.fromJson(map)).toList();
  }

  Future<LocationModel?> getLocationById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString('locations') ?? '[]';
    final locationsList = (json.decode(locationsJson) as List)
        .cast<Map<String, dynamic>>();

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
    final locationsList = (json.decode(locationsJson) as List)
        .cast<Map<String, dynamic>>();

    locationsList.removeWhere((l) => l['id'] == location.id);
    locationsList.add(location.toJson());
    await prefs.setString('locations', json.encode(locationsList));
    return 1;
  }

  Future<int> deleteLocation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getString('locations') ?? '[]';
    final locationsList = (json.decode(locationsJson) as List)
        .cast<Map<String, dynamic>>();

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
    final favoritesList = (json.decode(favoritesJson) as List)
        .cast<Map<String, dynamic>>();

    favoritesList.add(favorite.toJson());
    await prefs.setString('favorites', json.encode(favoritesList));
    return 1;
  }

  Future<List<FavoriteModel>> getUserFavorites(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorites') ?? '[]';
    final favoritesList = (json.decode(favoritesJson) as List)
        .cast<Map<String, dynamic>>();

    return favoritesList
        .where((f) => f['userId'] == userId)
        .map((map) => FavoriteModel.fromJson(map))
        .toList();
  }

  Future<int> getFavoritesCount() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorites') ?? '[]';
    final favoritesList = (json.decode(favoritesJson) as List);
    return favoritesList.length;
  }

  Future<int> deleteFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorites') ?? '[]';
    final favoritesList = (json.decode(favoritesJson) as List)
        .cast<Map<String, dynamic>>();

    favoritesList.removeWhere((f) => f['id'] == id);
    await prefs.setString('favorites', json.encode(favoritesList));
    return 1;
  }

  Future<int> deleteFavoriteByLocation(String userId, String locationId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorites') ?? '[]';
    final favoritesList = (json.decode(favoritesJson) as List)
        .cast<Map<String, dynamic>>();

    favoritesList.removeWhere(
      (f) => f['userId'] == userId && f['locationId'] == locationId,
    );
    await prefs.setString('favorites', json.encode(favoritesList));
    return 1;
  }

  Future<bool> isFavorite(String userId, String locationId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorites') ?? '[]';
    final favoritesList = (json.decode(favoritesJson) as List)
        .cast<Map<String, dynamic>>();

    return favoritesList.any(
      (f) => f['userId'] == userId && f['locationId'] == locationId,
    );
  }


  // Aliases for compatibility
  Future<int> addFavorite(FavoriteModel favorite) => createFavorite(favorite);
  Future<int> removeFavorite(String id) => deleteFavorite(id);

  // Event CRUD operations
  Future<int> createEvent(EventModel event) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events') ?? '[]';
    final eventsList =
        (json.decode(eventsJson) as List).cast<Map<String, dynamic>>();

    eventsList.add(event.toJson());
    await prefs.setString('events', json.encode(eventsList));
    return 1;
  }

  Future<List<EventModel>> getAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events') ?? '[]';
    final eventsList =
        (json.decode(eventsJson) as List).cast<Map<String, dynamic>>();

    final events =
        eventsList.map((map) => EventModel.fromJson(map)).toList();
    // Sort by start time
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    return events;
  }

  Future<EventModel?> getEventById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events') ?? '[]';
    final eventsList =
        (json.decode(eventsJson) as List).cast<Map<String, dynamic>>();

    for (var eventData in eventsList) {
      if (eventData['id'] == id) {
        return EventModel.fromJson(eventData);
      }
    }
    return null;
  }

  Future<int> updateEvent(EventModel event) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events') ?? '[]';
    final eventsList =
        (json.decode(eventsJson) as List).cast<Map<String, dynamic>>();

    eventsList.removeWhere((e) => e['id'] == event.id);
    eventsList.add(event.toJson());
    await prefs.setString('events', json.encode(eventsList));
    return 1;
  }

  Future<int> deleteEvent(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events') ?? '[]';
    final eventsList =
        (json.decode(eventsJson) as List).cast<Map<String, dynamic>>();

    eventsList.removeWhere((e) => e['id'] == id);
    await prefs.setString('events', json.encode(eventsList));
    return 1;
  }

  Future<List<EventModel>> getUpcomingEvents({int days = 30}) async {
    final allEvents = await getAllEvents();
    final now = DateTime.now();
    final cutoffDate = now.add(Duration(days: days));

    return allEvents
        .where((event) =>
            event.startTime.isAfter(now) &&
            event.startTime.isBefore(cutoffDate))
        .toList();
  }

  Future<List<EventModel>> getEventsByCategory(EventCategory category) async {
    final allEvents = await getAllEvents();
    return allEvents.where((event) => event.category == category).toList();
  }

  Future<List<EventModel>> getImportantEvents() async {
    final allEvents = await getAllEvents();
    return allEvents.where((event) => event.isImportant).toList();
  }

  Future<int> getEventsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString('events') ?? '[]';
    final eventsList = (json.decode(eventsJson) as List);
    return eventsList.length;
  }


  // Database cleanup
  Future<void> close() async {
    // No cleanup needed for SharedPreferences
  }
}
