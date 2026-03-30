// Firebase Service - Handle all Firebase operations

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../models/favorite_model.dart';
import '../models/event_model.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  FirebaseService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _locationsCollection =>
      _firestore.collection('locations');
  CollectionReference get _favoritesCollection =>
      _firestore.collection('favorites');
  CollectionReference get _feedbackCollection =>
      _firestore.collection('feedback');
  CollectionReference get _analyticsCollection =>
      _firestore.collection('analytics');
  CollectionReference get _eventsCollection => _firestore.collection('events');

  Future<bool> _waitForAuthIfNeeded() async {
    if (_auth.currentUser != null) {
      return true;
    }

    try {
      final restoredUser = await _auth
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(const Duration(seconds: 4));
      return restoredUser != null;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  // ============= AUTH OPERATIONS =============

  // Register with Email & Password
  Future<UserCredential?> registerWithEmail(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Firebase Auth Registration Error: $e');
      rethrow;
    }
  }

  // Login with Email & Password
  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Firebase Auth Login Error: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentFirebaseUser => _auth.currentUser;

  // ============= USER OPERATIONS =============

  // Create user document in Firestore
  Future<void> createUserDocument(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      debugPrint('Error creating user document: $e');
      rethrow;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return UserModel.fromJson(
          querySnapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      return null;
    }
  }

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _usersCollection.get();
      final users = <UserModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          users.add(UserModel.fromJson(doc.data() as Map<String, dynamic>));
        } catch (e) {
          debugPrint('Skipping invalid user document ${doc.id}: $e');
        }
      }
      return users;
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  // Get users count without requiring full document parsing.
  Future<int?> getUsersCount() async {
    try {
      final aggregateSnapshot = await _usersCollection.count().get();
      return aggregateSnapshot.count;
    } catch (e) {
      debugPrint('Error getting users count: $e');

      if (e is FirebaseException && e.code == 'permission-denied') {
        final authReady = await _waitForAuthIfNeeded();
        if (authReady) {
          try {
            final retrySnapshot = await _usersCollection.count().get();
            return retrySnapshot.count;
          } catch (retryError) {
            debugPrint('Retry users count failed: $retryError');
          }
        }
      }

      return null;
    }
  }

  // Get users document count by reading snapshot size directly.
  Future<int?> getUsersDocumentsCount() async {
    try {
      final snapshot = await _usersCollection.get();
      return snapshot.size;
    } catch (e) {
      debugPrint('Error getting users documents count: $e');

      if (e is FirebaseException && e.code == 'permission-denied') {
        final authReady = await _waitForAuthIfNeeded();
        if (authReady) {
          try {
            final retrySnapshot = await _usersCollection.get();
            return retrySnapshot.size;
          } catch (retryError) {
            debugPrint('Retry users documents count failed: $retryError');
          }
        }
      }

      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _usersCollection.doc(userId).update(updates);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // ============= LOCATION OPERATIONS =============

  // Get all locations
  Future<List<LocationModel>> getAllLocations() async {
    try {
      final querySnapshot = await _locationsCollection.get();
      final locations = <LocationModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          if (!data.containsKey('latitude') || !data.containsKey('longitude')) {
            continue;
          }
          locations.add(LocationModel.fromJson(data));
        } catch (e) {
          debugPrint('Skipping invalid location document ${doc.id}: $e');
        }
      }
      return locations;
    } catch (e) {
      debugPrint('Error getting locations: $e');
      return [];
    }
  }

  // Get location by ID
  Future<LocationModel?> getLocationById(String locationId) async {
    try {
      final doc = await _locationsCollection.doc(locationId).get();
      if (!doc.exists) {
        return null;
      }
      return LocationModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting location by id: $e');
      return null;
    }
  }

  // Add/Update location (Admin only)
  Future<void> saveLocation(LocationModel location) async {
    try {
      await _locationsCollection.doc(location.id).set(location.toJson());
    } catch (e) {
      debugPrint('Error saving location: $e');
      rethrow;
    }
  }

  // Delete location (Admin only)
  Future<void> deleteLocation(String locationId) async {
    try {
      await _locationsCollection.doc(locationId).delete();
    } catch (e) {
      debugPrint('Error deleting location: $e');
      rethrow;
    }
  }

  // Search locations
  Future<List<LocationModel>> searchLocations(String query) async {
    try {
      final querySnapshot = await _locationsCollection.get();
      final allLocations = querySnapshot.docs
          .map(
            (doc) => LocationModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();

      // Filter locations by name or description
      return allLocations.where((location) {
        return location.name.toLowerCase().contains(query.toLowerCase()) ||
            location.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      debugPrint('Error searching locations: $e');
      return [];
    }
  }

  // ============= FAVORITES OPERATIONS =============

  // Add favorite
  Future<void> addFavorite(String userId, String locationId) async {
    try {
      final favorite = FavoriteModel(
        id: '${userId}_$locationId',
        userId: userId,
        locationId: locationId,
        createdAt: DateTime.now(),
      );
      await _favoritesCollection.doc(favorite.id).set(favorite.toJson());
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      rethrow;
    }
  }

  // Remove favorite
  Future<void> removeFavorite(String userId, String locationId) async {
    try {
      await _favoritesCollection.doc('${userId}_$locationId').delete();
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      rethrow;
    }
  }

  // Remove favorite by document ID
  Future<void> removeFavoriteById(String favoriteId) async {
    try {
      await _favoritesCollection.doc(favoriteId).delete();
    } catch (e) {
      debugPrint('Error removing favorite by id: $e');
      rethrow;
    }
  }

  // Get user favorites
  Future<List<FavoriteModel>> getUserFavorites(String userId) async {
    try {
      final querySnapshot = await _favoritesCollection
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => FavoriteModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting favorites: $e');
      return [];
    }
  }

  // Check if location is favorited
  Future<bool> isFavorite(String userId, String locationId) async {
    try {
      final doc = await _favoritesCollection.doc('${userId}_$locationId').get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking favorite: $e');
      return false;
    }
  }

  // Get total favorites count
  Future<int> getFavoritesCount() async {
    try {
      final querySnapshot = await _favoritesCollection.get();
      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting favorites count: $e');
      return 0;
    }
  }

  // ============= EVENT OPERATIONS =============

  // Save event
  Future<void> saveEvent(EventModel event) async {
    try {
      await _eventsCollection.doc(event.id).set(event.toJson());
    } catch (e) {
      debugPrint('Error saving event: $e');
      rethrow;
    }
  }

  // Get all events
  Future<List<EventModel>> getAllEvents() async {
    try {
      final querySnapshot = await _eventsCollection.get();
      final events = querySnapshot.docs
          .map((doc) => EventModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      events.sort((a, b) => a.startTime.compareTo(b.startTime));
      return events;
    } catch (e) {
      debugPrint('Error getting all events: $e');
      return [];
    }
  }

  // Get event by id
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _eventsCollection.doc(eventId).get();
      if (!doc.exists) {
        return null;
      }
      return EventModel.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting event by id: $e');
      return null;
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();
    } catch (e) {
      debugPrint('Error deleting event: $e');
      rethrow;
    }
  }

  // ============= ANALYTICS OPERATIONS =============

  // Track navigation event
  Future<void> trackNavigation({
    required String userId,
    required String startLocationId,
    required String endLocationId,
    required double distance,
    required int estimatedTime,
  }) async {
    try {
      await _analyticsCollection.add({
        'userId': userId,
        'startLocationId': startLocationId,
        'endLocationId': endLocationId,
        'distance': distance,
        'estimatedTime': estimatedTime,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'navigation',
      });
    } catch (e) {
      debugPrint('Error tracking navigation: $e');
    }
  }

  // Track search event
  Future<void> trackSearch(String userId, String query) async {
    try {
      await _analyticsCollection.add({
        'userId': userId,
        'query': query,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'search',
      });
    } catch (e) {
      debugPrint('Error tracking search: $e');
    }
  }

  // Submit feedback
  Future<void> submitFeedback({
    required String userId,
    required String feedback,
    int? rating,
  }) async {
    try {
      await _feedbackCollection.add({
        'userId': userId,
        'feedback': feedback,
        'rating': rating,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error submitting feedback: $e');
      rethrow;
    }
  }

  // Get all feedback (Admin only)
  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    try {
      final querySnapshot = await _feedbackCollection
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      debugPrint('Error getting feedback: $e');
      return [];
    }
  }

  // Get navigation statistics (Admin only)
  Future<Map<String, dynamic>> getNavigationStats() async {
    try {
      final querySnapshot = await _analyticsCollection
          .where('type', isEqualTo: 'navigation')
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'totalNavigations': 0,
          'totalDistance': 0.0,
          'averageDistance': 0.0,
          'popularRoutes': [],
        };
      }

      int totalNavigations = querySnapshot.docs.length;
      double totalDistance = 0;

      Map<String, int> routeCounts = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalDistance += (data['distance'] as num?)?.toDouble() ?? 0;

        final route = '${data['startLocationId']}_${data['endLocationId']}';
        routeCounts[route] = (routeCounts[route] ?? 0) + 1;
      }

      // Sort routes by count
      final sortedRoutes = routeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'totalNavigations': totalNavigations,
        'totalDistance': totalDistance,
        'averageDistance': totalDistance / totalNavigations,
        'popularRoutes': sortedRoutes
            .take(10)
            .map((e) => {'route': e.key, 'count': e.value})
            .toList(),
      };
    } catch (e) {
      debugPrint('Error getting navigation stats: $e');
      return {
        'totalNavigations': 0,
        'totalDistance': 0.0,
        'averageDistance': 0.0,
        'popularRoutes': [],
      };
    }
  }

  // ============= REAL-TIME UPDATES =============

  // Listen to location updates
  Stream<List<LocationModel>> locationStream() {
    return _locationsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => LocationModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  // Listen to user favorites
  Stream<List<FavoriteModel>> favoritesStream(String userId) {
    return _favoritesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    FavoriteModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }
}
