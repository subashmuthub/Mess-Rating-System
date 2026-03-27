// Navigation Screen - Real GPS Navigation with Google Maps

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../services/navigation_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_style.dart';

class NavigationScreen extends StatefulWidget {
  final LocationModel destination;

  const NavigationScreen({super.key, required this.destination});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  String _currentInstruction = 'Getting your location...';
  double _distanceRemaining = 0;
  double _estimatedTime = 0;
  String _nextTurn = '';
  int _currentStepIndex = 0;
  final List<String> _navigationSteps = [];

  @override
  void initState() {
    super.initState();
    _startNavigation();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startNavigation() async {
    try {
      // Try to get current location with timeout
      Position? position;
      try {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled');
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permissions are denied');
          }
        }

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint('Could not get location: $e');
        // Use campus center as fallback
        position = null;
      }

      setState(() {
        if (position != null) {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _currentInstruction = 'Calculating route from your location...';
        } else {
          // Use campus center as starting point
          _currentPosition = const LatLng(9.1726, 77.8718);
          _currentInstruction = 'Using campus center as starting point';
        }
      });

      // Build the route
      await _buildRoute();

      // Start continuous location tracking if available
      if (position != null) {
        _startLocationTracking();
      }

      setState(() {
        if (position != null) {
          _currentInstruction = 'Navigation started';
        } else {
          _currentInstruction = 'Showing route to ${widget.destination.name}';
        }
      });

      // Announce navigation start
      NavigationService.instance.speakInstruction(
        'Navigation to ${widget.destination.name}. Distance is ${_distanceRemaining.toStringAsFixed(0)} meters',
      );
    } catch (e) {
      debugPrint('Error starting navigation: $e');
      // Even if there's an error, show the destination
      setState(() {
        _currentPosition = const LatLng(9.1726, 77.8718);
        _currentInstruction = 'Showing destination location';
      });
      await _buildRoute();
    }
  }

  Future<void> _buildRoute() async {
    if (_currentPosition == null) return;

    // Create markers
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('current'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
        Marker(
          markerId: MarkerId(widget.destination.id),
          position: widget.destination.coordinates,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: widget.destination.name,
            snippet: 'Destination',
          ),
        ),
      };
    });

    // Calculate straight-line route (for campus navigation)
    _routePoints = [_currentPosition!, widget.destination.coordinates];

    // For more realistic campus navigation, add intermediate points
    _routePoints = _generateCampusRoute(
      _currentPosition!,
      widget.destination.coordinates,
    );

    // Create polyline
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: AppStyle.primary,
          width: 5,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    });

    // Calculate distance
    _distanceRemaining = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.destination.coordinates.latitude,
      widget.destination.coordinates.longitude,
    );

    // Estimate time (assuming walking speed of 5 km/h or 1.4 m/s)
    _estimatedTime = _distanceRemaining / 1.4; // seconds

    // Generate navigation steps
    _generateNavigationSteps();

    // Fit camera to show entire route
    _fitRouteInView();
  }

  List<LatLng> _generateCampusRoute(LatLng start, LatLng end) {
    // Simple route generation with intermediate waypoints
    List<LatLng> points = [];
    points.add(start);

    // Add intermediate points for more realistic path
    double latDiff = end.latitude - start.latitude;
    double lngDiff = end.longitude - start.longitude;

    // Create a path with turns (simulate walking paths)
    int numSteps = 5;
    for (int i = 1; i < numSteps; i++) {
      double progress = i / numSteps;

      // Add slight curve to make it look like a walking path
      double offset = 0.0001 * (i % 2 == 0 ? 1 : -1);

      points.add(
        LatLng(
          start.latitude + (latDiff * progress),
          start.longitude + (lngDiff * progress) + offset,
        ),
      );
    }

    points.add(end);
    return points;
  }

  void _generateNavigationSteps() {
    _navigationSteps.clear();

    if (_routePoints.length < 2) return;

    for (int i = 0; i < _routePoints.length - 1; i++) {
      double distance = Geolocator.distanceBetween(
        _routePoints[i].latitude,
        _routePoints[i].longitude,
        _routePoints[i + 1].latitude,
        _routePoints[i + 1].longitude,
      );

      String direction = _getDirection(_routePoints[i], _routePoints[i + 1]);

      if (i == 0) {
        _navigationSteps.add(
          'Head $direction for ${distance.toStringAsFixed(0)} meters',
        );
      } else if (i == _routePoints.length - 2) {
        _navigationSteps.add('Your destination is ahead');
      } else {
        _navigationSteps.add(
          'Continue $direction for ${distance.toStringAsFixed(0)} meters',
        );
      }
    }
  }

  String _getDirection(LatLng from, LatLng to) {
    double bearing = Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );

    // Convert bearing to direction
    if (bearing >= -22.5 && bearing < 22.5) return 'north';
    if (bearing >= 22.5 && bearing < 67.5) return 'northeast';
    if (bearing >= 67.5 && bearing < 112.5) return 'east';
    if (bearing >= 112.5 && bearing < 157.5) return 'southeast';
    if (bearing >= 157.5 || bearing < -157.5) return 'south';
    if (bearing >= -157.5 && bearing < -112.5) return 'southwest';
    if (bearing >= -112.5 && bearing < -67.5) return 'west';
    if (bearing >= -67.5 && bearing < -22.5) return 'northwest';
    return 'ahead';
  }

  void _fitRouteInView() {
    if (_mapController == null || _routePoints.isEmpty) return;

    double minLat = _routePoints[0].latitude;
    double maxLat = _routePoints[0].latitude;
    double minLng = _routePoints[0].longitude;
    double maxLng = _routePoints[0].longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100, // padding
      ),
    );
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (!mounted) return;

            LatLng newPosition = LatLng(position.latitude, position.longitude);

            setState(() {
              _currentPosition = newPosition;

              // Update current marker
              _markers.removeWhere((m) => m.markerId.value == 'current');
              _markers.add(
                Marker(
                  markerId: const MarkerId('current'),
                  position: newPosition,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                  infoWindow: const InfoWindow(title: 'Your Location'),
                  rotation: position.heading,
                ),
              );

              // Recalculate remaining distance
              _distanceRemaining = Geolocator.distanceBetween(
                newPosition.latitude,
                newPosition.longitude,
                widget.destination.coordinates.latitude,
                widget.destination.coordinates.longitude,
              );

              // Update estimated time
              _estimatedTime = _distanceRemaining / 1.4; // seconds

              // Update navigation instruction
              _updateNavigationInstruction();

              // Check if arrived
              if (_distanceRemaining < 10) {
                _onArrived();
              }
            });

            // Keep camera centered on user
            _mapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
          },
        );
  }

  void _updateNavigationInstruction() {
    if (_currentStepIndex < _navigationSteps.length) {
      setState(() {
        _currentInstruction = _navigationSteps[_currentStepIndex];

        // Update next turn if available
        if (_currentStepIndex + 1 < _navigationSteps.length) {
          _nextTurn = _navigationSteps[_currentStepIndex + 1];
        } else {
          _nextTurn = 'Arriving at destination';
        }
      });

      // Advance to next step if close enough
      if (_currentStepIndex < _routePoints.length - 1) {
        double distanceToNextPoint = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _routePoints[_currentStepIndex + 1].latitude,
          _routePoints[_currentStepIndex + 1].longitude,
        );

        if (distanceToNextPoint < 20) {
          _currentStepIndex++;
          if (_currentStepIndex < _navigationSteps.length) {
            NavigationService.instance.speakInstruction(
              _navigationSteps[_currentStepIndex],
            );
          }
        }
      }
    }
  }

  void _onArrived() {
    _positionStreamSubscription?.cancel();

    NavigationService.instance.speakInstruction(
      'You have arrived at ${widget.destination.name}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Arrived!'),
        content: Text(
          'You have reached ${widget.destination.name}',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Navigate to ${widget.destination.name}',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        backgroundColor: AppStyle.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Google Map
          if (_currentPosition != null)
            GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 17,
                tilt: 45,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Navigation Info Panel
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: const [AppStyle.primary, AppStyle.accent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.navigation,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentInstruction,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoChip(
                          icon: Icons.straighten,
                          label: _distanceRemaining > 1000
                              ? '${(_distanceRemaining / 1000).toStringAsFixed(2)} km'
                              : '${_distanceRemaining.toStringAsFixed(0)} m',
                        ),
                        _buildInfoChip(
                          icon: Icons.access_time,
                          label: _estimatedTime > 60
                              ? '${(_estimatedTime / 60).toStringAsFixed(0)} min'
                              : '${_estimatedTime.toStringAsFixed(0)} sec',
                        ),
                        _buildInfoChip(icon: Icons.speed, label: '5 km/h'),
                      ],
                    ),
                    if (_nextTurn.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.turn_right,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Then: $_nextTurn',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Control Buttons
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: () {
                    if (_currentPosition != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentPosition!, 18),
                      );
                    }
                  },
                  backgroundColor: Colors.white,
                  heroTag: 'location',
                  child: const Icon(Icons.my_location, color: AppStyle.primary),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  onPressed: _fitRouteInView,
                  backgroundColor: Colors.white,
                  heroTag: 'route',
                  child: const Icon(Icons.zoom_out_map, color: AppStyle.primary),
                ),
              ],
            ),
          ),

          // Stop Navigation Button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () {
                _positionStreamSubscription?.cancel();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.stop),
              label: const Text('Stop Navigation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyle.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
