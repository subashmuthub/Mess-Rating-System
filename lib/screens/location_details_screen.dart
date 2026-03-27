// Location Details Screen - Detailed view of a location

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/location_model.dart';
import '../services/navigation_service.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../models/favorite_model.dart';

class LocationDetailsScreen extends StatefulWidget {
  final LocationModel location;

  const LocationDetailsScreen({super.key, required this.location});

  @override
  State<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId != null) {
      final isFav = await DatabaseHelper.instance.isFavorite(
        userId,
        widget.location.id,
      );
      setState(() {
        _isFavorite = isFav;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;

    if (_isFavorite) {
      // Remove from favorites
      final favorites = await DatabaseHelper.instance.getUserFavorites(userId);
      final favorite = favorites.firstWhere(
        (fav) => fav.locationId == widget.location.id,
      );
      await DatabaseHelper.instance.removeFavorite(favorite.id);
    } else {
      // Add to favorites
      final favorite = FavoriteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        locationId: widget.location.id,
        createdAt: DateTime.now(),
      );
      await DatabaseHelper.instance.addFavorite(favorite);
    }

    setState(() => _isFavorite = !_isFavorite);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.location.name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  shadows: [const Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Location Icon Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getLocationColor(widget.location.type),
                          _getLocationColor(
                            widget.location.type,
                          ).withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _getLocationIcon(widget.location.type),
                        size: 120,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (!_isLoading)
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // Share location
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon')),
                  );
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.location.typeIcon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.location.type
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'About',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.location.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _buildDetailCard(),
                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.location.buildingCode != null)
              _buildDetailRow(
                Icons.business,
                'Building Code',
                widget.location.buildingCode!,
              ),
            if (widget.location.floorNumber != null)
              _buildDetailRow(
                Icons.stairs,
                'Floor',
                'Floor ${widget.location.floorNumber}',
              ),
            if (widget.location.roomNumber != null)
              _buildDetailRow(
                Icons.door_front_door,
                'Room',
                widget.location.roomNumber!,
              ),
            if (widget.location.openingHours != null)
              _buildDetailRow(
                Icons.access_time,
                'Opening Hours',
                widget.location.openingHours!,
              ),
            _buildDetailRow(
              Icons.accessible,
              'Accessibility',
              widget.location.isAccessible ? 'Accessible' : 'Not Accessible',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _startNavigation();
            },
            icon: const Icon(Icons.directions),
            label: const Text('Navigate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              _callLocation();
            },
            icon: const Icon(Icons.phone),
            label: const Text('Contact'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _startNavigation() {
    NavigationService.instance.speakInstruction(
      'Starting navigation to ${widget.location.name}',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to ${widget.location.name}'),
        action: SnackBarAction(
          label: 'Stop',
          onPressed: () {
            NavigationService.instance.stopSpeaking();
          },
        ),
      ),
    );
  }

  void _callLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Information', style: GoogleFonts.poppins()),
        content: Text(
          widget.location.contactInfo?.toString() ??
              'No contact information available',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getLocationColor(LocationType type) {
    switch (type) {
      case LocationType.department:
        return Colors.blue;
      case LocationType.library:
        return Colors.purple;
      case LocationType.lab:
        return Colors.orange;
      case LocationType.cafeteria:
        return Colors.green;
      case LocationType.hostel:
        return Colors.cyan;
      case LocationType.parking:
        return Colors.amber;
      default:
        return Colors.red;
    }
  }

  IconData _getLocationIcon(LocationType type) {
    switch (type) {
      case LocationType.department:
        return Icons.business;
      case LocationType.library:
        return Icons.local_library;
      case LocationType.lab:
        return Icons.science;
      case LocationType.cafeteria:
        return Icons.restaurant;
      case LocationType.hostel:
        return Icons.hotel;
      case LocationType.parking:
        return Icons.local_parking;
      default:
        return Icons.location_on;
    }
  }
}
