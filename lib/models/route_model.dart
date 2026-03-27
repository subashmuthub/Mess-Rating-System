// Route Model - Represents navigation routes between locations

import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteModel {
  final String id;
  final String startLocationId;
  final String endLocationId;
  final List<LatLng> pathPoints;
  final double distance; // in meters
  final int estimatedTime; // in seconds
  final List<String> instructions;
  final bool isIndoor;
  final List<int>? floors; // For multi-floor navigation

  RouteModel({
    required this.id,
    required this.startLocationId,
    required this.endLocationId,
    required this.pathPoints,
    required this.distance,
    required this.estimatedTime,
    required this.instructions,
    this.isIndoor = false,
    this.floors,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startLocationId': startLocationId,
      'endLocationId': endLocationId,
      'pathPoints': pathPoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'distance': distance,
      'estimatedTime': estimatedTime,
      'instructions': instructions,
      'isIndoor': isIndoor,
      'floors': floors,
    };
  }

  // Create from JSON
  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'],
      startLocationId: json['startLocationId'],
      endLocationId: json['endLocationId'],
      pathPoints: (json['pathPoints'] as List)
          .map((p) => LatLng(p['lat'], p['lng']))
          .toList(),
      distance: json['distance'],
      estimatedTime: json['estimatedTime'],
      instructions: List<String>.from(json['instructions']),
      isIndoor: json['isIndoor'] ?? false,
      floors: json['floors'] != null ? List<int>.from(json['floors']) : null,
    );
  }

  // Get formatted distance
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  // Get formatted time
  String get formattedTime {
    if (estimatedTime < 60) {
      return '$estimatedTime sec';
    } else {
      final minutes = (estimatedTime / 60).floor();
      final seconds = estimatedTime % 60;
      return seconds > 0 ? '$minutes min $seconds sec' : '$minutes min';
    }
  }
}
