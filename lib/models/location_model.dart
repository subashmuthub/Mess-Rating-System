// Location Model - Represents buildings, departments, and places on campus

import 'package:google_maps_flutter/google_maps_flutter.dart';

enum LocationType {
  building,
  department,
  classroom,
  lab,
  library,
  office,
  cafeteria,
  hostel,
  parking,
  sports,
  auditorium,
  medical,
  other,
}

class LocationModel {
  final String id;
  final String name;
  final String description;
  final LocationType type;
  final LatLng coordinates;
  final String? buildingCode;
  final int? floorNumber;
  final String? roomNumber;
  final List<String>? images;
  final Map<String, dynamic>? contactInfo;
  final bool isAccessible; // For wheelchair accessibility
  final String? openingHours;
  final List<String>? tags; // For better search

  LocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.coordinates,
    this.buildingCode,
    this.floorNumber,
    this.roomNumber,
    this.images,
    this.contactInfo,
    this.isAccessible = true,
    this.openingHours,
    this.tags,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString(),
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'buildingCode': buildingCode,
      'floorNumber': floorNumber,
      'roomNumber': roomNumber,
      'images': images,
      'contactInfo': contactInfo,
      'isAccessible': isAccessible,
      'openingHours': openingHours,
      'tags': tags,
    };
  }

  // Create from JSON
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final latitude = (json['latitude'] as num).toDouble();
    final longitude = (json['longitude'] as num).toDouble();
    return LocationModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: LocationType.values.firstWhere((e) => e.toString() == json['type']),
      coordinates: LatLng(latitude, longitude),
      buildingCode: json['buildingCode'],
      floorNumber: json['floorNumber'],
      roomNumber: json['roomNumber'],
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      contactInfo: json['contactInfo'],
      isAccessible: json['isAccessible'] ?? true,
      openingHours: json['openingHours'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }

  // Get location type icon
  String get typeIcon {
    switch (type) {
      case LocationType.building:
        return '🏢';
      case LocationType.department:
        return '🏛️';
      case LocationType.classroom:
        return '📚';
      case LocationType.lab:
        return '🔬';
      case LocationType.library:
        return '📖';
      case LocationType.office:
        return '💼';
      case LocationType.cafeteria:
        return '🍽️';
      case LocationType.hostel:
        return '🏠';
      case LocationType.parking:
        return '🅿️';
      case LocationType.sports:
        return '⚽';
      case LocationType.auditorium:
        return '🎭';
      case LocationType.medical:
        return '🏥';
      case LocationType.other:
        return '📍';
    }
  }

  // Get full address
  String get fullAddress {
    String address = name;
    if (buildingCode != null) address += ' - $buildingCode';
    if (floorNumber != null) address += ', Floor $floorNumber';
    if (roomNumber != null) address += ', Room $roomNumber';
    return address;
  }
}
