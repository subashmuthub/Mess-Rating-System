// Home Screen - Main navigation hub

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import 'map_screen.dart';
import 'search_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import '../theme/app_style.dart';

import 'admin_screen.dart';
import 'virtual_tour_screen.dart';
import 'events_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;


  List<Widget> get _screens => [
    const DashboardScreen(showTopBar: false),
    const SearchScreen(),
    const EventsScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: AppStyle.pageBackground,
      appBar: AppBar(
        title: Text(
          'Campus Navigation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0.5,
        actions: [
          // Admin Panel Access (only for admins)
          if (user?.role == UserRole.admin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AdminScreen()));
              },
              tooltip: 'Admin Panel',
            ),

          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppStyle.primary,
        unselectedItemColor: AppStyle.textMuted,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      drawer: _buildDrawer(context, user),
    );
  }
  Widget _buildDrawer(BuildContext context, UserModel? user) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: AppStyle.authGradient,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  fontSize: 40,
                  color: AppStyle.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            accountName: Text(
              user?.name ?? 'User',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            accountEmail: Text(
              user?.roleName ?? 'User',
              style: GoogleFonts.poppins(),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 0);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.map,
                  title: 'Campus Map',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MapScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.explore,
                  title: 'Explore Campus',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 1);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.favorite,
                  title: 'My Favorites',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _currentIndex = 3);
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.threesixty,
                  title: '360° Virtual Tour',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VirtualTourScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.directions_walk,
                  title: 'Navigation Guide',
                  onTap: () {
                    Navigator.pop(context);
                    _showNavigationGuide();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.download,
                  title: 'Offline Maps',
                  onTap: () {
                    Navigator.pop(context);
                    _showOfflineInfo();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    _showSettings();
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    _showHelp();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    _showAbout();
                  },
                ),
              ],
            ),
          ),

          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            textColor: AppStyle.danger,
            onTap: () async {
              final navigator = Navigator.of(context);
              await AuthService.instance.logout();
              if (!mounted) return;
              navigator.pushReplacementNamed('/login');
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(title, style: GoogleFonts.poppins(color: textColor)),
      onTap: onTap,
    );
  }


  void _showNavigationGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Navigation Guide', style: GoogleFonts.poppins()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideItem(
                '🗺️',
                'View Map',
                'Browse the interactive campus map',
              ),
              _buildGuideItem(
                '🔍',
                'Search Location',
                'Find buildings, departments & places',
              ),
              _buildGuideItem(
                '🧭',
                'Get Directions',
                'Navigate to any campus location',
              ),
              _buildGuideItem(
                '🔊',
                'Voice Guide',
                'Enable voice navigation for hands-free',
              ),
              _buildGuideItem(
                '⭐',
                'Save Favorites',
                'Quick access to frequently visited places',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
  Widget _buildGuideItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppStyle.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOfflineInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Offline Maps', style: GoogleFonts.poppins()),
        content: Text(
          'Offline maps are automatically cached when you view them. You can access previously viewed areas without internet connection.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settings', style: GoogleFonts.poppins()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Voice Navigation', style: GoogleFonts.poppins()),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Auto-rotate Map', style: GoogleFonts.poppins()),
              value: false,
              onChanged: (value) {},
            ),
          ],
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

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Help & Support', style: GoogleFonts.poppins()),
        content: Text(
          'For assistance:\n\n'
          '📧 Email: support@campus.edu\n'
          '📞 Phone: +91-xxx-xxx-xxxx\n\n'
          'Monday - Friday: 9:00 AM - 5:00 PM',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About', style: GoogleFonts.poppins()),
        content: Text(
          'Campus Navigation System v1.0.0\n\n'
          'An intelligent navigation system to help you find your way around campus.\n\n'
          '© 2026 Campus Navigation Team',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
