// Location Sync Service - Sync locations between local DB and Firebase

import '../models/location_model.dart';
import '../data/location_data.dart';
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
      print('Error initializing locations: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // Load locations from Firebase
  Future<void> _loadLocationsFromFirebase() async {
    try {
      final firebaseLocations = await _firebaseService.getAllLocations();
      
      if (firebaseLocations.isEmpty) {
        // No data in Firebase, use default locations and upload them
        await _uploadDefaultLocations();
      } else {
        // Save Firebase locations to local database
        for (var location in firebaseLocations) {
          await _dbHelper.createLocation(location);
        }
        print('Loaded ${firebaseLocations.length} locations from Firebase');
      }
    } catch (e) {
      print('Error loading from Firebase: $e');
      // Fall back to default locations
      await _useDefaultLocations();
    }
  }

  // Upload default locations to Firebase
  Future<void> _uploadDefaultLocations() async {
    try {
      final defaultLocations = LocationData.getAllLocations();
      
      // Save to local database first
      for (var location in defaultLocations) {
        await _dbHelper.createLocation(location);
      }
      
      // Upload to Firebase
      for (var location in defaultLocations) {
        try {
          await _firebaseService.saveLocation(location);
        } catch (e) {
          print('Error uploading location ${location.name}: $e');
        }
      }
      
      print('Uploaded ${defaultLocations.length} default locations to Firebase');
    } catch (e) {
      print('Error uploading default locations: $e');
    }
  }

  // Use default locations (offline mode)
  Future<void> _useDefaultLocations() async {
    try {
      final defaultLocations = LocationData.getAllLocations();
      for (var location in defaultLocations) {
        await _dbHelper.createLocation(location);
      }
      print('Loaded ${defaultLocations.length} default locations locally');
    } catch (e) {
      print('Error loading default locations: $e');
    }
  }

  // Sync in background
  void _syncInBackground() {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        await _syncLocations();
      } catch (e) {
        print('Background sync error: $e');
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
            print('Error uploading location ${location.id}: $e');
          }
        }
      }
      
      // Download Firebase locations not in local
      for (var location in firebaseLocations) {
        if (!localMap.containsKey(location.id)) {
          try {
            await _dbHelper.createLocation(location);
          } catch (e) {
            print('Error saving location ${location.id}: $e');
          }
        }
      }
      
      print('Sync completed successfully');
    } catch (e) {
      print('Sync error: $e');
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
        print('Firebase upload error: $e');
        // Continue anyway, will sync later
      }
      
      return true;
    } catch (e) {
      print('Error adding location: $e');
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
        print('Firebase update error: $e');
      }
      
      return true;
    } catch (e) {
      print('Error updating location: $e');
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
        print('Firebase delete error: $e');
      }
      
      return true;
    } catch (e) {
      print('Error deleting location: $e');
      return false;
    }
  }
}
