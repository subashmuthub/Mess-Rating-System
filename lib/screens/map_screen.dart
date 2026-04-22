// Map Screen - Interactive campus map with Google Maps

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/location_model.dart';
import '../services/database_helper.dart';
import 'location_details_screen.dart';
import 'navigation_screen.dart';
import '../theme/app_style.dart';
import '../utils/network_status.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _routePreviewPolylines = {};
  final TextEditingController _searchController = TextEditingController();
  List<LocationModel> _locations = [];
  List<LocationModel> _filteredLocations = [];
  LocationModel? _selectedLocation;
  LatLng? _currentPosition;
  bool _isLoading = true;
  bool _isTrackingLocation = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  String _locationStatus = 'Getting your location...';
  MapType _mapType = MapType.normal;
  bool _trafficEnabled = false;
  String _nearbyFilter = 'All';
  String _searchQuery = '';
  double _cameraBearing = 0;
  bool _isNightMap = false;
  bool _isOnline = true;
  bool _checkingMapAvailability = true;

  static const LatLng _fallbackCampusCenter = LatLng(9.1726, 77.8718);
  static const String _nightMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
  {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#64779e"}]},
  {"featureType":"administrative.province","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#334e87"}]},
  {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#023e58"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},
  {"featureType":"poi","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#3C7680"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"road","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#255763"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0d5ce"}]},
  {"featureType":"road.highway","elementType":"labels.text.stroke","stylers":[{"color":"#023e58"}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"transit","elementType":"labels.text.stroke","stylers":[{"color":"#1d2c4d"}]},
  {"featureType":"transit.line","elementType":"geometry.fill","stylers":[{"color":"#283d6a"}]},
  {"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#3a4762"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
]
''';

  @override
  void initState() {
    super.initState();
    _checkMapAvailability();
    _initializeMap();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadMarkers();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _checkMapAvailability() async {
    final online = await hasInternetAccess();
    if (!mounted) return;
    setState(() {
      _isOnline = online;
      _checkingMapAvailability = false;
    });
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
      _filteredLocations = locations;
    });
    _refreshMarkers();
  }

  void _refreshMarkers() {
    _markers
      ..clear()
      ..addAll(
        _filteredLocations.map(
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
            onTap: () => _onMarkerTapped(location),
          ),
        ),
      );
  }

  void _searchLocations(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      final lower = _searchQuery.toLowerCase().trim();

      _filteredLocations = _locations.where((location) {
        final matchesSearch = lower.isEmpty ||
            location.name.toLowerCase().contains(lower) ||
            location.description.toLowerCase().contains(lower) ||
            (location.buildingCode?.toLowerCase().contains(lower) ?? false) ||
            (location.tags?.any((tag) => tag.toLowerCase().contains(lower)) ?? false);

        final matchesFilter = _nearbyFilter == 'All' ||
            (_nearbyFilter == 'Academic' &&
                (location.type == LocationType.building ||
                    location.type == LocationType.department ||
                    location.type == LocationType.classroom)) ||
            (_nearbyFilter == 'Labs' && location.type == LocationType.lab) ||
            (_nearbyFilter == 'Library' && location.type == LocationType.library) ||
            (_nearbyFilter == 'Food' && location.type == LocationType.cafeteria) ||
            (_nearbyFilter == 'Hostel' && location.type == LocationType.hostel) ||
            (_nearbyFilter == 'Parking' && location.type == LocationType.parking);

        return matchesSearch && matchesFilter;
      }).toList();

      if (_selectedLocation != null &&
          !_filteredLocations.any((l) => l.id == _selectedLocation!.id)) {
        _selectedLocation = null;
        _routePreviewPolylines.clear();
      }

      _selectedLocation = null;
      _refreshMarkers();
    });
  }

  void _updateRoutePreview(LocationModel? destination) {
    _routePreviewPolylines.clear();
    if (_currentPosition == null || destination == null) {
      return;
    }

    final points = _buildPreviewPoints(_currentPosition!, destination.coordinates);
    _routePreviewPolylines.add(
      Polyline(
        polylineId: const PolylineId('preview-route'),
        points: points,
        color: AppStyle.primary,
        width: 5,
        geodesic: true,
      ),
    );
  }

  List<LatLng> _buildPreviewPoints(LatLng start, LatLng end) {
    final mid = LatLng(
      (start.latitude + end.latitude) / 2,
      (start.longitude + end.longitude) / 2 + 0.00012,
    );
    return [start, mid, end];
  }

  String _selectedDistanceLabel() {
    if (_currentPosition == null || _selectedLocation == null) return '--';
    final meters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _selectedLocation!.coordinates.latitude,
      _selectedLocation!.coordinates.longitude,
    );

    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String _selectedEtaLabel() {
    if (_currentPosition == null || _selectedLocation == null) return '--';
    final meters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _selectedLocation!.coordinates.latitude,
      _selectedLocation!.coordinates.longitude,
    );
    final minutes = (meters / 80).ceil();
    return '$minutes min';
  }

  Future<void> _centerOnUser() async {
    if (_currentPosition == null) return;
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition!, 17),
    );
  }

  Future<void> _recenterNorth() async {
    if (_currentPosition == null || _mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition!,
          zoom: 17,
          bearing: 0,
          tilt: 0,
        ),
      ),
    );
  }

  Future<void> _recalculatePreviewRoute() async {
    if (_selectedLocation == null) return;
    setState(() {
      _updateRoutePreview(_selectedLocation);
    });
    if (_currentPosition != null) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              (_currentPosition!.latitude < _selectedLocation!.coordinates.latitude)
                  ? _currentPosition!.latitude
                  : _selectedLocation!.coordinates.latitude,
              (_currentPosition!.longitude < _selectedLocation!.coordinates.longitude)
                  ? _currentPosition!.longitude
                  : _selectedLocation!.coordinates.longitude,
            ),
            northeast: LatLng(
              (_currentPosition!.latitude > _selectedLocation!.coordinates.latitude)
                  ? _currentPosition!.latitude
                  : _selectedLocation!.coordinates.latitude,
              (_currentPosition!.longitude > _selectedLocation!.coordinates.longitude)
                  ? _currentPosition!.longitude
                  : _selectedLocation!.coordinates.longitude,
            ),
          ),
          70,
        ),
      );
    }
  }

  Future<void> _zoomBy(double delta) async {
    if (_mapController == null) return;
    final currentZoom = await _mapController!.getZoomLevel();
    await _mapController!.animateCamera(
      CameraUpdate.zoomTo((currentZoom + delta).clamp(2, 21)),
    );
  }

  Future<void> _openExternalMap(LocationModel location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${location.coordinates.latitude},${location.coordinates.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openExternalDirections(LocationModel location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${location.coordinates.latitude},${location.coordinates.longitude}&travelmode=walking',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
    setState(() {
      _selectedLocation = location;
      _updateRoutePreview(location);
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location.coordinates, 17),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_checkingMapAvailability) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isOnline) {
      return _buildOfflineMapView();
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentPosition ?? _fallbackCampusCenter,
            zoom: 15,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: _markers,
          polylines: _routePreviewPolylines,
          style: _isNightMap ? _nightMapStyle : null,
          myLocationEnabled: !kIsWeb,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          trafficEnabled: _trafficEnabled,
          mapType: _mapType,
          compassEnabled: true,
          onCameraMove: (position) {
            _cameraBearing = position.bearing;
          },
          onTap: (_) => setState(() {
            _selectedLocation = null;
            _routePreviewPolylines.clear();
          }),
        ),

        Positioned(
          top: 14,
          left: 12,
          right: 12,
          child: Column(
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchLocations,
                  decoration: InputDecoration(
                    hintText: 'Search campus locations',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchLocations('');
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionChip(
                      label: 'Default',
                      icon: Icons.map,
                      selected: _mapType == MapType.normal,
                      onTap: () => setState(() => _mapType = MapType.normal),
                    ),
                    _buildActionChip(
                      label: 'Satellite',
                      icon: Icons.satellite_alt,
                      selected: _mapType == MapType.satellite,
                      onTap: () => setState(() => _mapType = MapType.satellite),
                    ),
                    _buildActionChip(
                      label: 'Terrain',
                      icon: Icons.terrain,
                      selected: _mapType == MapType.terrain,
                      onTap: () => setState(() => _mapType = MapType.terrain),
                    ),
                    _buildActionChip(
                      label: 'Traffic',
                      icon: Icons.traffic,
                      selected: _trafficEnabled,
                      onTap: () => setState(
                        () => _trafficEnabled = !_trafficEnabled,
                      ),
                    ),
                    _buildActionChip(
                      label: 'Night',
                      icon: Icons.nightlight_round,
                      selected: _isNightMap,
                      onTap: () => setState(() => _isNightMap = !_isNightMap),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in const [
                      'All',
                      'Academic',
                      'Labs',
                      'Library',
                      'Food',
                      'Hostel',
                      'Parking',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: _nearbyFilter == filter,
                          onSelected: (_) {
                            setState(() => _nearbyFilter = filter);
                            _applyFilters();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _locationStatus,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppStyle.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        Positioned(
          right: 12,
          bottom: 150,
          child: Column(
            children: [
              _buildRoundMapControl(
                icon: Icons.add,
                onTap: () => _zoomBy(1),
                tooltip: 'Zoom in',
              ),
              const SizedBox(height: 8),
              _buildRoundMapControl(
                icon: Icons.remove,
                onTap: () => _zoomBy(-1),
                tooltip: 'Zoom out',
              ),
              const SizedBox(height: 8),
              _buildRoundMapControl(
                icon: _isTrackingLocation ? Icons.gps_fixed : Icons.my_location,
                onTap: _centerOnUser,
                tooltip: 'My location',
              ),
              const SizedBox(height: 8),
              _buildRoundMapControl(
                icon: Icons.explore,
                onTap: _recenterNorth,
                tooltip: 'Recenter north',
                angleDeg: _cameraBearing,
              ),
            ],
          ),
        ),

        Positioned(
          left: 12,
          right: 12,
          bottom: _selectedLocation != null ? 190 : 16,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickActionButton(
                    icon: Icons.place,
                    label: '${_filteredLocations.length} Places',
                    onTap: null,
                  ),
                  _quickActionButton(
                    icon: Icons.navigation,
                    label: 'Directions',
                    onTap: _selectedLocation == null
                        ? null
                        : () => _openExternalDirections(_selectedLocation!),
                  ),
                  _quickActionButton(
                    icon: Icons.open_in_new,
                    label: 'Open Maps',
                    onTap: _selectedLocation == null
                        ? null
                        : () => _openExternalMap(_selectedLocation!),
                  ),
                ],
              ),
            ),
          ),
        ),

        DraggableScrollableSheet(
          initialChildSize: 0.12,
          minChildSize: 0.08,
          maxChildSize: 0.42,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Places Nearby',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_filteredLocations.length}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: AppStyle.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredLocations.length,
                      itemBuilder: (context, index) {
                        final location = _filteredLocations[index];
                        return ListTile(
                          leading: Icon(
                            _getLocationIcon(location.type),
                            color: _getLocationTypeColor(location.type),
                          ),
                          title: Text(
                            location.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            location.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _onMarkerTapped(location),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Selected Location Card
        if (_selectedLocation != null)
          Positioned(
            bottom: 96,
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.straighten, size: 16),
                          label: Text('Distance: ${_selectedDistanceLabel()}'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.access_time, size: 16),
                          label: Text('ETA: ${_selectedEtaLabel()}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _recalculatePreviewRoute,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Recalc'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _openExternalMap(_selectedLocation!),
                          icon: const Icon(Icons.open_in_new),
                          tooltip: 'Open in Google Maps',
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

  Widget _buildOfflineMapView() {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 72, color: AppStyle.primary),
            const SizedBox(height: 16),
            Text(
              'Map unavailable offline',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to the internet to load the live campus map. You can still browse locations below and open navigation details.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppStyle.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _checkMapAvailability,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppStyle.primary.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildRoundMapControl({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    double angleDeg = 0,
  }) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        icon: Transform.rotate(
          angle: angleDeg * (3.14159265359 / 180),
          child: Icon(icon),
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: onTap == null ? AppStyle.textMuted : AppStyle.primary),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: onTap == null ? AppStyle.textMuted : AppStyle.textPrimary,
              ),
            ),
          ],
        ),
      ),
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
