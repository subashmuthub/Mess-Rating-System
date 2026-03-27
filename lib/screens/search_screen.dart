// Search Screen - Search for campus locations

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/location_model.dart';
import '../services/database_helper.dart';
import '../theme/app_style.dart';
import 'location_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<LocationModel> _allLocations = [];
  List<LocationModel> _searchResults = [];
  List<LocationModel> _recentSearches = [];
  bool _isSearching = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locations = await DatabaseHelper.instance.getAllLocations();
    if (!mounted) return;

    setState(() {
      _allLocations = locations;
      _recentSearches = locations.take(8).toList();
      _isLoading = false;
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      final lowerQuery = query.toLowerCase();
      _searchResults = _allLocations.where((location) {
        return location.name.toLowerCase().contains(lowerQuery) ||
            location.description.toLowerCase().contains(lowerQuery) ||
            (location.buildingCode?.toLowerCase().contains(lowerQuery) ??
                false) ||
            (location.tags?.any(
                  (tag) => tag.toLowerCase().contains(lowerQuery),
                ) ??
                false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppStyle.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _performSearch,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search buildings, departments, places...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Search Results or Recent Searches
        Expanded(
          child: _isSearching ? _buildSearchResults() : _buildRecentSearches(),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                            color: AppStyle.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppStyle.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final location = _searchResults[index];
        return _buildLocationCard(location);
      },
    );
  }

  Widget _buildRecentSearches() {
    if (_allLocations.isEmpty) {
      return Center(
        child: Text(
          'No locations available. Add locations from Admin Panel.',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Popular Locations',
            style: GoogleFonts.poppins(
              fontSize: 18,
                color: AppStyle.textMuted,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              final location = _recentSearches[index];
              return _buildLocationCard(location, showIcon: true);
            },
          ),
        ),

        // Quick Categories
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Browse by Category',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCategoryChip('Departments', LocationType.department),
                  _buildCategoryChip('Libraries', LocationType.library),
                  _buildCategoryChip('Labs', LocationType.lab),
                  _buildCategoryChip('Cafeteria', LocationType.cafeteria),
                  _buildCategoryChip('Hostels', LocationType.hostel),
                  _buildCategoryChip('Sports', LocationType.sports),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(LocationModel location, {bool showIcon = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppStyle.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              location.typeIcon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          location.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.description,
              style: GoogleFonts.poppins(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (location.buildingCode != null)
              Text(
                location.buildingCode!,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppStyle.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LocationDetailsScreen(location: location),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, LocationType type) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        final locations = _allLocations
            .where((location) => location.type == type)
            .toList();
        setState(() {
          _isSearching = true;
          _searchResults = locations;
          _searchController.text = label;
        });
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
