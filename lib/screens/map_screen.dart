// Map Screen - Interactive campus map with Google Maps

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../services/database_helper.dart';
import 'location_details_screen.dart';
import 'navigation_screen.dart';
import '../theme/app_style.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  List<LocationModel> _locations = [];
  LocationModel? _selectedLocation;
  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _isTrackingLocation = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  String _locationStatus = 'Getting your location...';

  static const LatLng _fallbackCampusCenter = LatLng(9.1726, 77.8718);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadMarkers();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus =
              'Location services disabled. Using fallback location.';
          _currentPosition = _fallbackCampusCenter;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please enable location services for accurate positioning',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus =
                'Location permission denied. Using fallback location.';
            _currentPosition = _fallbackCampusCenter;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatus = 'Location permission permanently denied.';
          _currentPosition = _fallbackCampusCenter;
        });
        return;
      }

      // Get current position with high accuracy
      setState(() => _locationStatus = 'Getting GPS fix...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _locationStatus =
            'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });

      // Start continuous location tracking
      _startLocationTracking();
    } catch (e) {
      setState(() {
        _locationStatus = 'Error getting location: $e';
        _currentPosition = _fallbackCampusCenter;
      });
      debugPrint('Error getting location: $e');
    }
  }

  void _startLocationTracking() {
    _positionStreamSubscription?.cancel();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              _currentPosition = LatLng(position.latitude, position.longitude);
              _locationStatus =
                  'Live GPS: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
              _isTrackingLocation = true;
            });

            // Update camera position if tracking is enabled
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(_currentPosition!),
            );
          }
        });
  }

  Future<void> _loadMarkers() async {
    final locations = await DatabaseHelper.instance.getAllLocations();

    if (!mounted) return;
    setState(() {
      _locations = locations;
      _markers
        ..clear()
        ..addAll(
          locations.map(
            (location) => Marker(
              markerId: MarkerId(location.id),
              position: location.coordinates,
              infoWindow: InfoWindow(
                title: location.name,
                snippet: location.description,
                onTap: () => _onMarkerTapped(location),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getMarkerColor(location.type),
              ),
            ),
          ),
        );
    });
  }

  double _getMarkerColor(LocationType type) {
    switch (type) {
      case LocationType.department:
        return BitmapDescriptor.hueBlue;
      case LocationType.library:
        return BitmapDescriptor.hueViolet;
      case LocationType.lab:
        return BitmapDescriptor.hueOrange;
      case LocationType.cafeteria:
        return BitmapDescriptor.hueGreen;
      case LocationType.hostel:
        return BitmapDescriptor.hueCyan;
      case LocationType.parking:
        return BitmapDescriptor.hueYellow;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  Color _getLocationTypeColor(LocationType type) {
    switch (type) {
      case LocationType.department:
        return AppStyle.primary;
      case LocationType.library:
        return AppStyle.accent;
      case LocationType.lab:
        return AppStyle.warning;
      case LocationType.cafeteria:
        return AppStyle.success;
      case LocationType.hostel:
        return AppStyle.accent;
      case LocationType.parking:
        return AppStyle.warning;
      default:
        return AppStyle.danger;
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

  void _onMarkerTapped(LocationModel location) {
    setState(() => _selectedLocation = location);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // For web, show location list instead of map (Google Maps API requires configuration)
    return Stack(
      children: [
        // Campus Locations List View
        Container(
          color: AppStyle.pageBackground,
          child: Column(
            children: [
              // Map Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: const [AppStyle.primary, AppStyle.accent],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.map, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Campus Locations',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${_locations.length} locations available',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isTrackingLocation
                                ? Icons.gps_fixed
                                : Icons.gps_not_fixed,
                            color: _isTrackingLocation
                                ? AppStyle.success
                                : Colors.white70,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locationStatus,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_currentPosition != null)
                            IconButton(
                              icon: const Icon(
                                Icons.my_location,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    _currentPosition!,
                                    16,
                                  ),
                                );
                              },
                              tooltip: 'Center on my location',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Location List
              Expanded(
                child: _locations.isEmpty
                    ? Center(
                        child: Text(
                          'No locations available. Add locations from Admin Panel.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppStyle.textMuted,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _locations.length,
                        itemBuilder: (context, index) {
                          final location = _locations[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _onMarkerTapped(location),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: _getLocationTypeColor(
                                          location.type,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _getLocationIcon(location.type),
                                        color: _getLocationTypeColor(
                                          location.type,
                                        ),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            location.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            location.description,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: AppStyle.textMuted,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (location.buildingCode !=
                                              null) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.business,
                                                  size: 14,
                                                  color: AppStyle.textMuted,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  location.buildingCode!,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: AppStyle.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: AppStyle.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),

        // Selected Location Card
        if (_selectedLocation != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getLocationTypeColor(
                              _selectedLocation!.type,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getLocationIcon(_selectedLocation!.type),
                            color: _getLocationTypeColor(
                              _selectedLocation!.type,
                            ),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedLocation!.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _selectedLocation!.description,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppStyle.textMuted,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LocationDetailsScreen(
                                    location: _selectedLocation!,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.info_outline),
                            label: const Text('Details'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Navigate to this location
                              _showNavigationDialog(_selectedLocation!);
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Navigate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStyle.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showNavigationDialog(LocationModel destination) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Navigate to ${destination.name}',
          style: GoogleFonts.poppins(),
        ),
        content: Text(
          'Start real-time GPS navigation to ${destination.name}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _startNavigation(destination);
            },
            icon: const Icon(Icons.navigation),
            label: const Text('Navigate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _startNavigation(LocationModel destination) {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get your current location'),
          backgroundColor: AppStyle.danger,
        ),
      );
      return;
    }

    // Navigate to real GPS navigation screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NavigationScreen(destination: destination),
      ),
    );
  }
}
