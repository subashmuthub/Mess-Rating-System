// Favorites Screen - User's saved locations

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../models/favorite_model.dart';
import '../models/location_model.dart';
import '../theme/app_style.dart';
import 'location_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<LocationModel> _favoriteLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final favorites = await DatabaseHelper.instance.getUserFavorites(userId);
      final locations = <LocationModel>[];

      for (var favorite in favorites) {
        final location = await DatabaseHelper.instance.getLocationById(
          favorite.locationId,
        );
        if (location != null) {
          locations.add(location);
        }
      }

      setState(() {
        _favoriteLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(LocationModel location) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;

    try {
      final favorites = await DatabaseHelper.instance.getUserFavorites(userId);
      FavoriteModel? favorite;
      for (final fav in favorites) {
        if (fav.locationId == location.id) {
          favorite = fav;
          break;
        }
      }

      if (favorite != null) {
        await DatabaseHelper.instance.removeFavorite(favorite.id);
      } else {
        await DatabaseHelper.instance.deleteFavoriteByLocation(
          userId,
          location.id,
        );
      }

      setState(() {
        _favoriteLocations.remove(location);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${location.name} removed from favorites'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                // Re-add to favorites
                final newFavorite = FavoriteModel(
                  id: '${userId}_${location.id}',
                  userId: userId,
                  locationId: location.id,
                  createdAt: DateTime.now(),
                );
                await DatabaseHelper.instance.addFavorite(newFavorite);
                _loadFavorites();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove from favorites')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteLocations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Favorites Yet',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppStyle.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save your frequently visited places here',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppStyle.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.favorite, color: AppStyle.danger),
              const SizedBox(width: 8),
              Text(
                'My Favorites',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _favoriteLocations.length,
            itemBuilder: (context, index) {
              final location = _favoriteLocations[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppStyle.danger.withValues(alpha: 0.10),
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
                  subtitle: Text(
                    location.fullAddress,
                    style: GoogleFonts.poppins(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.directions,
                          color: AppStyle.primary,
                        ),
                        onPressed: () {
                          // Navigate to location
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Navigating to ${location.name}'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppStyle.danger),
                        onPressed: () => _removeFavorite(location),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LocationDetailsScreen(location: location),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
