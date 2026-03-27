// Firebase Service - Handle all Firebase operations

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../models/favorite_model.dart';

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
      return querySnapshot.docs
          .map(
            (doc) => LocationModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting locations: $e');
      return [];
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
