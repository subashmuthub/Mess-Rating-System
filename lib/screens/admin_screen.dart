// Admin Screen - Admin panel for data management

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/auth_service.dart';
import '../services/database_helper.dart';
import '../models/event_model.dart';
import '../models/location_model.dart';
import '../models/user_model.dart';
import '../theme/app_style.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const LatLng _defaultCoordinates = LatLng(0, 0);

  int _selectedTab = 0;
  bool _isLoading = true;
  String _searchQuery = '';

  List<LocationModel> _locations = [];
  List<EventModel> _events = [];
  List<UserModel> _users = [];
  int _favoritesCount = 0;

  bool _voiceNavigationEnabled = true;
  bool _guestAccessEnabled = true;
  bool _offlineCachingEnabled = true;
  bool _maintenanceModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final savedLocations = await DatabaseHelper.instance.getAllLocations();
    final savedEvents = await DatabaseHelper.instance.getAllEvents();

    final users = await DatabaseHelper.instance.getAllUsers();
    final favoritesCount = await DatabaseHelper.instance.getFavoritesCount();

    if (!mounted) return;
    setState(() {
      _locations = savedLocations;
      _events = savedEvents;
      _users = users;
      _favoritesCount = favoritesCount;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.instance.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text('You do not have permission to access this page'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppStyle.pageBackground,
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: AppStyle.pageBackground,
            child: ListView(
              children: [
                const SizedBox(height: 8),
                _buildSidebarItem(0, Icons.location_on, 'Locations'),
                _buildSidebarItem(1, Icons.people, 'Users'),
                  _buildSidebarItem(2, Icons.event, 'Events'),
                  _buildSidebarItem(3, Icons.route, 'Routes'),
                  _buildSidebarItem(4, Icons.analytics, 'Analytics'),
                  _buildSidebarItem(5, Icons.settings, 'Settings'),
              ],
            ),
          ),

          // Main Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final primary = AppStyle.primary;
    final isSelected = _selectedTab == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primary : AppStyle.textMuted,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isSelected ? primary : AppStyle.textMuted,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppStyle.accent.withValues(alpha: 0.15),
      onTap: () => setState(() => _selectedTab = index),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildLocationsTab();
      case 1:
        return _buildUsersTab();
      case 2:
        return _buildEventsTab();
      case 3:
        return _buildRoutesTab();
      case 4:
        return _buildAnalyticsTab();
      case 5:
        return _buildSettingsTab();
      default:
        return const Center(child: Text('Not implemented'));
    }
  }

  Widget _buildLocationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredLocations = _locations.where((location) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return location.name.toLowerCase().contains(q) ||
          location.description.toLowerCase().contains(q) ||
          (location.buildingCode?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Locations',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await _showLocationFormDialog();
                  if (result == null) return;

                  final newLocation = LocationModel(
                    id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
                    name: result.name,
                    description: result.description,
                    type: result.type,
                    coordinates: result.coordinates,
                    buildingCode: result.buildingCode.isEmpty
                        ? null
                        : result.buildingCode,
                    openingHours: result.openingHours.isEmpty
                        ? null
                        : result.openingHours,
                    tags: result.tags,
                  );

                  await DatabaseHelper.instance.createLocation(newLocation);
                  await _loadAdminData();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location added successfully'),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Location'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search by name, description, or code',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => _searchQuery = ''),
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredLocations.length,
            itemBuilder: (context, index) {
              final location = filteredLocations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Text(
                    location.typeIcon,
                    style: const TextStyle(fontSize: 30),
                  ),
                  title: Text(
                    location.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(location.fullAddress),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppStyle.primary),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final result = await _showLocationFormDialog(
                            existing: location,
                          );
                          if (result == null) return;

                          final updated = LocationModel(
                            id: location.id,
                            name: result.name,
                            description: result.description,
                            type: result.type,
                            coordinates: result.coordinates,
                            buildingCode: result.buildingCode.isEmpty
                                ? null
                                : result.buildingCode,
                            openingHours: result.openingHours.isEmpty
                                ? null
                                : result.openingHours,
                            tags: result.tags,
                          );

                          await DatabaseHelper.instance.updateLocation(updated);
                          await _loadAdminData();

                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Location updated successfully'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppStyle.danger),
                        onPressed: () => _confirmDelete(location),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final roleCounts = {
      UserRole.student: 0,
      UserRole.faculty: 0,
      UserRole.visitor: 0,
      UserRole.admin: 0,
    };
    for (final user in _users) {
      roleCounts[user.role] = (roleCounts[user.role] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Management',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Total Users', '${_users.length}'),
          _buildStatRow('Students', '${roleCounts[UserRole.student] ?? 0}'),
          _buildStatRow('Faculty', '${roleCounts[UserRole.faculty] ?? 0}'),
          _buildStatRow('Visitors', '${roleCounts[UserRole.visitor] ?? 0}'),
          _buildStatRow('Admins', '${roleCounts[UserRole.admin] ?? 0}'),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: _users.length,
                separatorBuilder: (_, dividerIndex) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: Text(user.roleName),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Manage Events',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await _showEventFormDialog();
                  if (result == null) return;

                  final currentUser = AuthService.instance.currentUser;
                  final newEvent = EventModel(
                    id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
                    title: result.title,
                    description: result.description,
                    category: result.category,
                    startTime: result.startTime,
                    endTime: result.endTime,
                    location: result.location.isEmpty ? null : result.location,
                    organizerName: result.organizerName.isEmpty
                        ? currentUser?.name
                        : result.organizerName,
                    organizerEmail: result.organizerEmail.isEmpty
                        ? currentUser?.email
                        : result.organizerEmail,
                    imageUrl: result.imageUrl.isEmpty ? null : result.imageUrl,
                    attendees: const [],
                    maxAttendees: result.maxAttendees,
                    isImportant: result.isImportant,
                    tags: result.tags,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  await DatabaseHelper.instance.createEvent(newEvent);
                  await _loadAdminData();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event added successfully')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Event'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'All created events are stored in Firestore with local fallback for offline access.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppStyle.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _events.length,
            itemBuilder: (context, index) {
              final event = _events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppStyle.primary.withValues(alpha: 0.12),
                    child: Text(event.categoryIcon),
                  ),
                  title: Text(
                    event.title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${event.formattedDateRange}\n${event.location ?? 'No location'}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppStyle.primary),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(this.context);
                          final result = await _showEventFormDialog(
                            existing: event,
                          );
                          if (result == null) return;

                          final updatedEvent = event.copyWith(
                            title: result.title,
                            description: result.description,
                            category: result.category,
                            startTime: result.startTime,
                            endTime: result.endTime,
                            location: result.location.isEmpty
                                ? null
                                : result.location,
                            organizerName: result.organizerName.isEmpty
                                ? event.organizerName
                                : result.organizerName,
                            organizerEmail: result.organizerEmail.isEmpty
                                ? event.organizerEmail
                                : result.organizerEmail,
                            imageUrl: result.imageUrl.isEmpty
                                ? null
                                : result.imageUrl,
                            maxAttendees: result.maxAttendees,
                            isImportant: result.isImportant,
                            tags: result.tags,
                            updatedAt: DateTime.now(),
                          );

                          await DatabaseHelper.instance.updateEvent(
                            updatedEvent,
                          );
                          await _loadAdminData();

                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Event updated successfully'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppStyle.danger),
                        onPressed: () => _confirmDeleteEvent(event),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoutesTab() {
    final indoorCount = _locations.where((l) {
      return l.type == LocationType.building ||
          l.type == LocationType.department ||
          l.type == LocationType.classroom ||
          l.type == LocationType.lab ||
          l.type == LocationType.library ||
          l.type == LocationType.office ||
          l.type == LocationType.auditorium;
    }).length;
    final outdoorCount = _locations.length - indoorCount;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Management',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Total Routes', '${_locations.length}'),
          _buildStatRow('Indoor Routes', '$indoorCount'),
          _buildStatRow('Outdoor Routes', '$outdoorCount'),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final departmentCount = _locations
        .where((l) => l.type == LocationType.department)
        .length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Analytics',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Users',
                  '${_users.length}',
                  Icons.people,
                  AppStyle.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Locations',
                  '${_locations.length}',
                  Icons.location_on,
                  AppStyle.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Departments',
                  '$departmentCount',
                  Icons.account_tree,
                  AppStyle.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  'Favorites',
                  '$_favoritesCount',
                  Icons.favorite,
                  AppStyle.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Settings',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Enable Voice Navigation'),
            value: _voiceNavigationEnabled,
            onChanged: (value) =>
                setState(() => _voiceNavigationEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Allow Guest Access'),
            value: _guestAccessEnabled,
            onChanged: (value) => setState(() => _guestAccessEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Offline Map Caching'),
            value: _offlineCachingEnabled,
            onChanged: (value) =>
                setState(() => _offlineCachingEnabled = value),
          ),
          SwitchListTile(
            title: const Text('Maintenance Mode'),
            value: _maintenanceModeEnabled,
            onChanged: (value) =>
                setState(() => _maintenanceModeEnabled = value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: GoogleFonts.poppins()),
        trailing: Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppStyle.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppStyle.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<_LocationFormData?> _showLocationFormDialog({
    LocationModel? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final codeController = TextEditingController(
      text: existing?.buildingCode ?? '',
    );
    final openingHoursController = TextEditingController(
      text: existing?.openingHours ?? '',
    );
    final tagsController = TextEditingController(
      text: existing?.tags?.join(', ') ?? '',
    );
    final latitudeController = TextEditingController(
      text: (existing?.coordinates.latitude ?? _defaultCoordinates.latitude)
          .toString(),
    );
    final longitudeController = TextEditingController(
      text: (existing?.coordinates.longitude ?? _defaultCoordinates.longitude)
          .toString(),
    );

    final formKey = GlobalKey<FormState>();
    var selectedType = existing?.type ?? LocationType.other;

    return showDialog<_LocationFormData>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Location' : 'Edit Location',
                style: GoogleFonts.poppins(),
              ),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Description is required'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<LocationType>(
                          initialValue: selectedType,
                          items: LocationType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.toString().split('.').last),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() => selectedType = value);
                          },
                          decoration: const InputDecoration(labelText: 'Type'),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: codeController,
                          decoration: const InputDecoration(
                            labelText: 'Building Code (optional)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: latitudeController,
                                decoration: const InputDecoration(
                                  labelText: 'Latitude',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: longitudeController,
                                decoration: const InputDecoration(
                                  labelText: 'Longitude',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: openingHoursController,
                          decoration: const InputDecoration(
                            labelText: 'Opening Hours (optional)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags (comma separated)',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    final lat =
                        double.tryParse(latitudeController.text.trim()) ??
                        _defaultCoordinates.latitude;
                    final lng =
                        double.tryParse(longitudeController.text.trim()) ??
                        _defaultCoordinates.longitude;

                    final tags = tagsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    Navigator.pop(
                      context,
                      _LocationFormData(
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        buildingCode: codeController.text.trim(),
                        openingHours: openingHoursController.text.trim(),
                        type: selectedType,
                        coordinates: LatLng(lat, lng),
                        tags: tags,
                      ),
                    );
                  },
                  child: Text(existing == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(LocationModel location) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Location', style: GoogleFonts.poppins()),
        content: Text('Are you sure you want to delete ${location.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteLocation(location.id);
              await _loadAdminData();
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text('${location.name} deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppStyle.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<_EventFormData?> _showEventFormDialog({EventModel? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final locationController = TextEditingController(
      text: existing?.location ?? '',
    );
    final organizerNameController = TextEditingController(
      text: existing?.organizerName ?? '',
    );
    final organizerEmailController = TextEditingController(
      text: existing?.organizerEmail ?? '',
    );
    final imageUrlController = TextEditingController(
      text: existing?.imageUrl ?? '',
    );
    final maxAttendeesController = TextEditingController(
      text: existing?.maxAttendees?.toString() ?? '',
    );
    final tagsController = TextEditingController(
      text: existing?.tags?.join(', ') ?? '',
    );
    final startTimeDisplayController = TextEditingController(
      text: existing != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(existing.startTime)
          : '',
    );
    final endTimeDisplayController = TextEditingController(
      text: existing != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(existing.endTime)
          : '',
    );

    final formKey = GlobalKey<FormState>();
    var selectedCategory = existing?.category ?? EventCategory.announcement;
    var isImportant = existing?.isImportant ?? false;
    DateTime? startTime = existing?.startTime;
    DateTime? endTime = existing?.endTime;

    Future<DateTime?> pickDateTime(DateTime? initialValue) async {
      final date = await showDatePicker(
        context: context,
        initialDate: initialValue ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (date == null) return null;

      if (!mounted) return null;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialValue ?? DateTime.now()),
      );
      if (time == null) return null;

      return DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    }

    return showDialog<_EventFormData>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Add Event' : 'Edit Event',
                style: GoogleFonts.poppins(),
              ),
              content: SizedBox(
                width: 560,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Title is required'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          minLines: 3,
                          maxLines: 5,
                          validator: (value) => value == null || value.trim().isEmpty
                              ? 'Description is required'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<EventCategory>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: EventCategory.values.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() => selectedCategory = value);
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                controller: startTimeDisplayController,
                                decoration: const InputDecoration(
                                  labelText: 'Start Time',
                                ),
                                validator: (value) => value == null || value.trim().isEmpty
                                    ? 'Start time is required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final picked = await pickDateTime(startTime);
                                if (picked == null) return;
                                setDialogState(() {
                                  startTime = picked;
                                  startTimeDisplayController.text =
                                      DateFormat('yyyy-MM-dd HH:mm').format(
                                        picked,
                                      );
                                });
                              },
                              icon: const Icon(Icons.date_range),
                              label: const Text('Pick'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                controller: endTimeDisplayController,
                                decoration: const InputDecoration(
                                  labelText: 'End Time',
                                ),
                                validator: (value) => value == null || value.trim().isEmpty
                                    ? 'End time is required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () async {
                                final picked = await pickDateTime(endTime);
                                if (picked == null) return;
                                setDialogState(() {
                                  endTime = picked;
                                  endTimeDisplayController.text =
                                      DateFormat('yyyy-MM-dd HH:mm').format(
                                        picked,
                                      );
                                });
                              },
                              icon: const Icon(Icons.date_range),
                              label: const Text('Pick'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location (optional)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: organizerNameController,
                          decoration: const InputDecoration(
                            labelText: 'Organizer Name (optional)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: organizerEmailController,
                          decoration: const InputDecoration(
                            labelText: 'Organizer Email (optional)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image URL (optional)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: maxAttendeesController,
                          decoration: const InputDecoration(
                            labelText: 'Max Attendees (optional)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: false,
                            decimal: false,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags (comma separated)',
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Important event'),
                          value: isImportant,
                          onChanged: (value) {
                            setDialogState(() => isImportant = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    if (startTime == null || endTime == null) return;
                    if (endTime!.isBefore(startTime!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('End time must be after start time'),
                        ),
                      );
                      return;
                    }

                    final maxAttendees = int.tryParse(
                      maxAttendeesController.text.trim(),
                    );
                    final tags = tagsController.text
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();

                    Navigator.pop(
                      context,
                      _EventFormData(
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        category: selectedCategory,
                        startTime: startTime!,
                        endTime: endTime!,
                        location: locationController.text.trim(),
                        organizerName: organizerNameController.text.trim(),
                        organizerEmail: organizerEmailController.text.trim(),
                        imageUrl: imageUrlController.text.trim(),
                        maxAttendees: maxAttendees,
                        isImportant: isImportant,
                        tags: tags,
                      ),
                    );
                  },
                  child: Text(existing == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteEvent(EventModel event) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event', style: GoogleFonts.poppins()),
        content: Text('Are you sure you want to delete ${event.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.deleteEvent(event.id);
              await _loadAdminData();
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text('${event.title} deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppStyle.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _LocationFormData {
  final String name;
  final String description;
  final String buildingCode;
  final String openingHours;
  final LocationType type;
  final LatLng coordinates;
  final List<String> tags;

  _LocationFormData({
    required this.name,
    required this.description,
    required this.buildingCode,
    required this.openingHours,
    required this.type,
    required this.coordinates,
    required this.tags,
  });
}

class _EventFormData {
  final String title;
  final String description;
  final EventCategory category;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String organizerName;
  final String organizerEmail;
  final String imageUrl;
  final int? maxAttendees;
  final bool isImportant;
  final List<String> tags;

  const _EventFormData({
    required this.title,
    required this.description,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.organizerName,
    required this.organizerEmail,
    required this.imageUrl,
    required this.maxAttendees,
    required this.isImportant,
    required this.tags,
  });
}
