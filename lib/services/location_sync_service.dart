// Location Sync Service - Sync locations between local DB and Firebase

import 'package:flutter/foundation.dart';
import '../models/location_model.dart';
import 'firebase_service.dart';
import 'database_helper.dart';

class LocationSyncService {
  static final LocationSyncService instance = LocationSyncService._init();
  LocationSyncService._init();

  final FirebaseService _firebaseService = FirebaseService.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  // Initialize and sync locations
  Future<void> initializeLocations() async {
    if (_isSyncing) return;

    _isSyncing = true;
    try {
      // Check if we need to sync
      final localLocations = await _dbHelper.getAllLocations();

      if (localLocations.isEmpty) {
        // No local data, load from Firebase or use default data
        await _loadLocationsFromFirebase();
      } else {
        // We have local data, optionally sync with Firebase in background
        _syncInBackground();
      }

      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('Error initializing locations: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Load locations from Firebase
  Future<void> _loadLocationsFromFirebase() async {
    try {
      final firebaseLocations = await _firebaseService.getAllLocations();

      if (firebaseLocations.isEmpty) {
        debugPrint('No Firebase locations found to initialize');
      } else {
        // Save Firebase locations to local database
        for (var location in firebaseLocations) {
          await _dbHelper.createLocation(location);
        }
        debugPrint(
          'Loaded ${firebaseLocations.length} locations from Firebase',
        );
      }
    } catch (e) {
      debugPrint('Error loading from Firebase: $e');
    }
  }

  // Sync in background
  void _syncInBackground() {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await _syncLocations();
      } catch (e) {
        debugPrint('Background sync error: $e');
      }
    });
  }

  // Sync locations between local and Firebase
  Future<void> _syncLocations() async {
    try {
      final localLocations = await _dbHelper.getAllLocations();
      final firebaseLocations = await _firebaseService.getAllLocations();

      // Create maps for easier comparison
      final localMap = {for (var loc in localLocations) loc.id: loc};
      final firebaseMap = {for (var loc in firebaseLocations) loc.id: loc};

      // Upload local locations not in Firebase
      for (var location in localLocations) {
        if (!firebaseMap.containsKey(location.id)) {
          try {
            await _firebaseService.saveLocation(location);
          } catch (e) {
            debugPrint('Error uploading location ${location.id}: $e');
          }
        }
      }

      // Download Firebase locations not in local
      for (var location in firebaseLocations) {
        if (!localMap.containsKey(location.id)) {
          try {
            await _dbHelper.createLocation(location);
          } catch (e) {
            debugPrint('Error saving location ${location.id}: $e');
          }
        }
      }

      debugPrint('Sync completed successfully');
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  // Force sync now
  Future<void> forceSyncNow() async {
    if (_isSyncing) return;

    _isSyncing = true;
    try {
      await _syncLocations();
      _lastSyncTime = DateTime.now();
    } finally {
      _isSyncing = false;
    }
  }

  // Add new location (Admin only)
  Future<bool> addLocation(LocationModel location) async {
    try {
      // Save locally
      await _dbHelper.createLocation(location);

      // Upload to Firebase
      try {
        await _firebaseService.saveLocation(location);
      } catch (e) {
        debugPrint('Firebase upload error: $e');
        // Continue anyway, will sync later
      }

      return true;
    } catch (e) {
      debugPrint('Error adding location: $e');
      return false;
    }
  }

  // Update location (Admin only)
  Future<bool> updateLocation(LocationModel location) async {
    try {
      // Update locally
      await _dbHelper.updateLocation(location);

      // Update in Firebase
      try {
        await _firebaseService.saveLocation(location);
      } catch (e) {
        debugPrint('Firebase update error: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error updating location: $e');
      return false;
    }
  }

  // Delete location (Admin only)
  Future<bool> deleteLocation(String locationId) async {
    try {
      // Delete locally
      await _dbHelper.deleteLocation(locationId);

      // Delete from Firebase
      try {
        await _firebaseService.deleteLocation(locationId);
      } catch (e) {
        debugPrint('Firebase delete error: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting location: $e');
      return false;
    }
  }
}
