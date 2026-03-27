// Comprehensive Campus Navigation Dashboard

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../services/database_helper.dart';
import '../theme/app_style.dart';
import 'location_details_screen.dart';
import 'navigation_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // Data management
  List<LocationModel> _allLocations = [];
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // UI State
  bool _isLoading = true;
  int _totalUsers = 0;
  int _totalLocations = 0;
  int _totalFavorites = 0;
  LatLng? _currentPosition;
  late TabController _tabController;
  String _searchQuery = '';

  // Campus center (NEC Kovilpatti)
  static const LatLng _campusCenter = LatLng(9.1726, 77.8718);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    await Future.wait([_loadDashboardData(), _getCurrentLocation()]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final locations = await dbHelper.getAllLocations();
      final users = await dbHelper.getAllUsers();
      final favoritesCount = await dbHelper.getFavoritesCount();

      if (mounted) {
        setState(() {
          _allLocations = locations;
          _totalLocations = locations.length;
          _totalUsers = users.length;
          _totalFavorites = favoritesCount;
          _setupMarkers();
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentPosition = _campusCenter);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentPosition = _campusCenter);
          return;
        }
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        setState(
          () =>
              _currentPosition = LatLng(position.latitude, position.longitude),
        );
      } catch (e) {
        setState(() => _currentPosition = _campusCenter);
      }
    } catch (e) {
      setState(() => _currentPosition = _campusCenter);
    }
  }

  void _setupMarkers() {
    _markers.clear();
    for (final location in _allLocations) {
      _markers.add(
        Marker(
          markerId: MarkerId(location.id),
          position: location.coordinates,
          infoWindow: InfoWindow(
            title: location.name,
            snippet: location.description,
          ),
          onTap: () => _onMarkerSelected(location),
        ),
      );
    }
  }

  void _onMarkerSelected(LocationModel location) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location.coordinates, 18),
    );
  }

  List<LocationModel> get _filteredLocations {
    if (_searchQuery.isEmpty) return _allLocations;
    return _allLocations
        .where(
          (loc) =>
              loc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              loc.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppStyle.pageBackground,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Stats
            _buildHeaderSection(),

            // Search Bar
            _buildSearchBar(),

            // Feature Tabs
            _buildTabSection(),

            // Tab Content
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMapView(),
                  _buildLocationsView(),
                  _buildFeaturesView(),
                ],
              ),
            ),

            // Quick Actions Section
            _buildQuickActionsSection(),

            // Campus Information
            _buildCampusInfoSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppStyle.primary,
      title: Text(
        'Campus Navigator',
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
        IconButton(icon: const Icon(Icons.person), onPressed: () {}),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppStyle.primary, AppStyle.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'National Engineering College',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Kovilpatti, Tamil Nadu',
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatTile(
                icon: Icons.location_on,
                value: '$_totalLocations',
                label: 'Locations',
              ),
              _buildStatTile(
                icon: Icons.people,
                value: '$_totalUsers',
                label: 'Users',
              ),
              _buildStatTile(
                icon: Icons.favorite,
                value: '$_totalFavorites',
                label: 'Favorites',
              ),
              _buildStatTile(
                icon: Icons.navigation,
                value: 'GPS',
                label: 'Active',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search locations...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          border: Border(
            bottom: const BorderSide(color: AppStyle.primary, width: 3),
          ),
        ),
        labelColor: AppStyle.primary,
        unselectedLabelColor: Colors.grey,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.map), text: 'Map'),
          Tab(icon: Icon(Icons.list), text: 'Locations'),
          Tab(icon: Icon(Icons.apps), text: 'Features'),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return GoogleMap(
      onMapCreated: (controller) => _mapController = controller,
      initialCameraPosition: CameraPosition(
        target: _currentPosition ?? _campusCenter,
        zoom: 16.5,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: true,
      onTap: (_) {},
    );
  }

  Widget _buildLocationsView() {
    final locations = _filteredLocations;

    if (locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No locations found',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];

        return _buildLocationCard(location);
      },
    );
  }

  Widget _buildLocationCard(LocationModel location) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppStyle.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.location_on, color: AppStyle.primary, size: 22),
        ),
        title: Text(
          location.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.grey.shade900,
          ),
        ),
        subtitle: Text(
          location.description,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 12),
                  const Text('Details'),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LocationDetailsScreen(location: location),
                ),
              ),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  const Icon(Icons.navigation, size: 18),
                  const SizedBox(width: 12),
                  const Text('Navigate'),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NavigationScreen(destination: location),
                ),
              ),
            ),
          ],
        ),
        onTap: () => _onMarkerSelected(location),
      ),
    );
  }

  Widget _buildFeaturesView() {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _buildFeatureCategory(
          title: '📍 Navigation',
          features: [
            ('Find Route', 'Navigate to any campus location'),
            ('Traffic Info', 'Real-time navigation updates'),
            ('Offline Maps', 'Download maps for offline use'),
          ],
        ),
        const SizedBox(height: 12),
        _buildFeatureCategory(
          title: '📚 Information',
          features: [
            ('Departments', 'View department details'),
            ('Buildings', 'Explore campus buildings'),
            ('Events', 'Campus events & schedules'),
          ],
        ),
        const SizedBox(height: 12),
        _buildFeatureCategory(
          title: '👤 User',
          features: [
            ('Profile', 'Manage your account'),
            ('Preferences', 'Customize app settings'),
            ('Help & Support', 'Get assistance'),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCategory({
    required String title,
    required List<(String, String)> features,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 10),
            ...features.asMap().entries.map((entry) {
              final isLast = entry.key == features.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: AppStyle.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value.$1,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            entry.value.$2,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildQuickActionTile(Icons.near_me, 'Navigate', AppStyle.primary),
              _buildQuickActionTile(Icons.favorite, 'Favorites', AppStyle.danger),
              _buildQuickActionTile(Icons.search, 'Search', AppStyle.success),
              _buildQuickActionTile(Icons.settings, 'Settings', AppStyle.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(IconData icon, String label, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampusInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campus Information',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppStyle.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppStyle.primary.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppStyle.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'National Engineering College, Kovilpatti is a premier educational institution with modern facilities and infrastructure dedicated to excellence in education.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: AppStyle.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kovilpatti, Tamil Nadu - 628503, India',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
