// Favorite Model - User's saved/favorite locations

import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteModel {
  final String id;
  final String userId;
  final String locationId;
  final String? customName; // User can give custom name like "My Lab"
  final DateTime createdAt;

  FavoriteModel({
    required this.id,
    required this.userId,
    required this.locationId,
    this.customName,
    required this.createdAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'locationId': locationId,
      'customName': customName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    final createdAtValue = json['createdAt'];
    return FavoriteModel(
      id: json['id'],
      userId: json['userId'],
      locationId: json['locationId'],
      customName: json['customName'],
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.parse(createdAtValue.toString()),
    );
  }
}
