// Authentication Service - Handle user login and session with Firebase

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'database_helper.dart';
import 'firebase_service.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  UserModel? _currentUser;
  final FirebaseService _firebaseService = FirebaseService.instance;

  UserModel? get currentUser => _currentUser;

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Login user (Firebase + Local)
  Future<bool> login(String email, String password) async {
    try {
      // Try Firebase Authentication
      try {
        final userCredential = await _firebaseService.loginWithEmail(
          email,
          password,
        );
        if (userCredential != null) {
          // Get user data from Firestore
          final userData = await _firebaseService.getUserById(
            userCredential.user!.uid,
          );
          if (userData != null) {
            _currentUser = userData;
            await _saveUserSession(userData);
            return true;
          }
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Auth Error: ${e.message}');
        // Fall back to local database
      }

      // Fallback: Check local database
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      if (user != null) {
        _currentUser = user;
        await _saveUserSession(user);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  // Register new user (Firebase + Local)
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? department,
    String? phoneNumber,
  }) async {
    try {
      // Check if user already exists locally
      final existingUser = await DatabaseHelper.instance.getUserByEmail(email);
      if (existingUser != null) {
        debugPrint('User with email $email already exists');
        return false;
      }

      // Try to register with Firebase
      UserCredential? userCredential;
      try {
        userCredential = await _firebaseService.registerWithEmail(
          email,
          password,
        );
      } on FirebaseAuthException catch (e) {
        debugPrint('Firebase Registration Error: ${e.message}');
        // Continue with local registration even if Firebase fails
      }

      // Create user model
      final userId =
          userCredential?.user?.uid ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final user = UserModel(
        id: userId,
        name: name,
        email: email,
        role: role,
        department: department,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
      );

      // Save to Firestore if Firebase auth was successful
      if (userCredential != null) {
        try {
          await _firebaseService.createUserDocument(user);
        } catch (e) {
          debugPrint('Error saving to Firestore: $e');
        }
      }

      // Always save locally
      debugPrint('Creating user locally: ${user.email}');
      final result = await DatabaseHelper.instance.createUser(user);
      debugPrint('User created with result: $result');

      _currentUser = user;
      await _saveUserSession(user);
      return true;
    } catch (e, stackTrace) {
      debugPrint('Registration error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // Save user session
  Future<void> _saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Load user session
  Future<void> loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      _currentUser = UserModel.fromJson(json.decode(userJson));
    }
  }

  // Logout (Firebase + Local)
  Future<void> logout() async {
    // Logout from Firebase
    try {
      await _firebaseService.logout();
    } catch (e) {
      debugPrint('Firebase logout error: $e');
    }

    // Clear local session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
    _currentUser = null;
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    String? department,
  }) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        department: department,
      );

      await DatabaseHelper.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      await _saveUserSession(updatedUser);
      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  // Check if user has admin privileges
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  // Check if user is faculty
  bool get isFaculty => _currentUser?.role == UserRole.faculty;

  // Check if user is student
  bool get isStudent => _currentUser?.role == UserRole.student;

  // Check if user is visitor
  bool get isVisitor => _currentUser?.role == UserRole.visitor;
}
