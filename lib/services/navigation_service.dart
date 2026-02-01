// Navigation Service - Handle route calculations and voice navigation

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/route_model.dart';
import '../models/location_model.dart';
import 'dart:math' show cos, sqrt, asin;

class NavigationService {
  static final NavigationService instance = NavigationService._init();
  NavigationService._init();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  // Initialize TTS
  Future<void> initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  // Calculate distance between two coordinates (Haversine formula)
  double calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371000; // meters

    double lat1 = start.latitude * (3.14159265359 / 180.0);
    double lat2 = end.latitude * (3.14159265359 / 180.0);
    double dLat = lat2 - lat1;
    double dLng = (end.longitude - start.longitude) * (3.14159265359 / 180.0);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2));
    double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  // Helper function for sin (approximation)
  double sin(double x) {
    // Taylor series approximation for sin
    double result = 0;
    double term = x;
    int n = 1;
    
    for (int i = 0; i < 10; i++) {
      result += term;
      term *= -x * x / ((2 * n) * (2 * n + 1));
      n++;
    }
    
    return result;
  }

  // Calculate route between two locations
  Future<RouteModel> calculateRoute(
    LocationModel start,
    LocationModel end,
  ) async {
    // In a real app, you would use Google Directions API
    // For demo, we'll create a simple straight-line route

    final distance = calculateDistance(start.coordinates, end.coordinates);
    final estimatedTime = (distance / 1.4).round(); // Assuming 1.4 m/s walking speed

    // Create path points (simplified - in real app, use actual path)
    final pathPoints = [start.coordinates, end.coordinates];

    // Generate instructions
    final instructions = _generateInstructions(start, end, distance);

    return RouteModel(
      id: '${start.id}_${end.id}',
      startLocationId: start.id,
      endLocationId: end.id,
      pathPoints: pathPoints,
      distance: distance,
      estimatedTime: estimatedTime,
      instructions: instructions,
      isIndoor: start.buildingCode == end.buildingCode,
      floors: start.floorNumber != end.floorNumber
          ? [start.floorNumber ?? 0, end.floorNumber ?? 0]
          : null,
    );
  }

  // Generate navigation instructions
  List<String> _generateInstructions(
    LocationModel start,
    LocationModel end,
    double distance,
  ) {
    List<String> instructions = [];

    instructions.add('Start at ${start.name}');

    if (start.buildingCode != end.buildingCode) {
      instructions.add('Exit ${start.buildingCode ?? "the building"}');
      instructions.add('Head towards ${end.buildingCode ?? end.name}');
      instructions.add('Enter ${end.buildingCode ?? "the building"}');
    }

    if (start.floorNumber != end.floorNumber) {
      if ((end.floorNumber ?? 0) > (start.floorNumber ?? 0)) {
        instructions.add('Take stairs/elevator to Floor ${end.floorNumber}');
      } else {
        instructions.add('Go down to Floor ${end.floorNumber}');
      }
    }

    instructions.add('You have arrived at ${end.name}');

    return instructions;
  }

  // Speak navigation instruction
  Future<void> speakInstruction(String instruction) async {
    if (!_isSpeaking) {
      _isSpeaking = true;
      await _flutterTts.speak(instruction);
      _isSpeaking = false;
    }
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  // Get nearest location from current position
  LocationModel? getNearestLocation(
    LatLng currentPosition,
    List<LocationModel> locations,
  ) {
    if (locations.isEmpty) return null;

    LocationModel? nearest;
    double minDistance = double.infinity;

    for (var location in locations) {
      final distance = calculateDistance(currentPosition, location.coordinates);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = location;
      }
    }

    return nearest;
  }

  // Check if user is near destination (within 10 meters)
  bool isNearDestination(LatLng currentPosition, LatLng destination) {
    final distance = calculateDistance(currentPosition, destination);
    return distance <= 10;
  }

  // Get direction angle between two points
  double getDirection(LatLng from, LatLng to) {
    double dLon = (to.longitude - from.longitude);
    double y = sin(dLon) * cos(to.latitude);
    double x = cos(from.latitude) * sin(to.latitude) -
        sin(from.latitude) * cos(to.latitude) * cos(dLon);
    double bearing = atan2(y, x);
    return (bearing * 180 / 3.14159265359 + 360) % 360;
  }

  // Helper for atan2
  double atan2(double y, double x) {
    if (x > 0) {
      return atan(y / x);
    } else if (x < 0 && y >= 0) {
      return atan(y / x) + 3.14159265359;
    } else if (x < 0 && y < 0) {
      return atan(y / x) - 3.14159265359;
    } else if (x == 0 && y > 0) {
      return 3.14159265359 / 2;
    } else if (x == 0 && y < 0) {
      return -3.14159265359 / 2;
    }
    return 0;
  }

  // Helper for atan
  double atan(double x) {
    // Taylor series approximation
    if (x.abs() > 1) {
      return (3.14159265359 / 2) - atan(1 / x);
    }
    
    double result = 0;
    double term = x;
    int n = 1;
    
    for (int i = 0; i < 15; i++) {
      result += term;
      term *= -x * x * (2 * n - 1) / (2 * n + 1);
      n++;
    }
    
    return result;
  }

  // Get direction name (N, NE, E, SE, S, SW, W, NW)
  String getDirectionName(double angle) {
    if (angle >= 337.5 || angle < 22.5) return 'North';
    if (angle >= 22.5 && angle < 67.5) return 'Northeast';
    if (angle >= 67.5 && angle < 112.5) return 'East';
    if (angle >= 112.5 && angle < 157.5) return 'Southeast';
    if (angle >= 157.5 && angle < 202.5) return 'South';
    if (angle >= 202.5 && angle < 247.5) return 'Southwest';
    if (angle >= 247.5 && angle < 292.5) return 'West';
    return 'Northwest';
  }
}
