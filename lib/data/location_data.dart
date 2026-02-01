// Location Service - National Engineering College, Kovilpatti Campus Data

import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';

class LocationData {
  // National Engineering College, Kovilpatti - Main Campus Center
  static const LatLng campusCenter = LatLng(9.1726, 77.8718);

  static List<LocationModel> getSampleLocations() {
    return [
      // Main Administrative Building
      LocationModel(
        id: 'nec_001',
        name: 'Main Administrative Block',
        description: 'Principal office, Admin offices, and main reception',
        type: LocationType.office,
        coordinates: LatLng(9.1726, 77.8718),
        buildingCode: 'ADMIN',
        images: [],
        contactInfo: {'phone': '+91-4632-225000', 'email': 'info@nec.edu.in'},
        tags: ['Administration', 'Office', 'Principal', 'Reception'],
        openingHours: '9:00 AM - 5:00 PM',
      ),
      
      // Department Buildings
      LocationModel(
        id: 'nec_002',
        name: 'Computer Science & Engineering Department',
        description: 'CSE Department with computer labs, classrooms, and faculty rooms',
        type: LocationType.department,
        coordinates: LatLng(9.1730, 77.8715),
        buildingCode: 'CSE',
        images: [],
        contactInfo: {'phone': '+91-4632-225001', 'email': 'cse@nec.edu.in'},
        tags: ['CSE', 'Computer Science', 'Programming', 'Labs', 'Department'],
        openingHours: '8:30 AM - 5:30 PM',
      ),
      
      LocationModel(
        id: 'nec_003',
        name: 'Electronics & Communication Engineering',
        description: 'ECE Department with electronics labs and project rooms',
        type: LocationType.department,
        coordinates: LatLng(9.1728, 77.8720),
        buildingCode: 'ECE',
        images: [],
        contactInfo: {'phone': '+91-4632-225002', 'email': 'ece@nec.edu.in'},
        tags: ['ECE', 'Electronics', 'Communication', 'Department'],
        openingHours: '8:30 AM - 5:30 PM',
      ),
      
      LocationModel(
        id: 'nec_004',
        name: 'Electrical & Electronics Engineering',
        description: 'EEE Department with power systems and control labs',
        type: LocationType.department,
        coordinates: LatLng(9.1724, 77.8722),
        buildingCode: 'EEE',
        images: [],
        contactInfo: {'phone': '+91-4632-225003', 'email': 'eee@nec.edu.in'},
        tags: ['EEE', 'Electrical', 'Electronics', 'Department'],
        openingHours: '8:30 AM - 5:30 PM',
      ),
      
      LocationModel(
        id: 'nec_005',
        name: 'Mechanical Engineering Department',
        description: 'Mechanical Department with workshops, CAD labs, and thermal labs',
        type: LocationType.department,
        coordinates: LatLng(9.1722, 77.8716),
        buildingCode: 'MECH',
        images: [],
        contactInfo: {'phone': '+91-4632-225004', 'email': 'mech@nec.edu.in'},
        tags: ['Mechanical', 'Engineering', 'Workshop', 'Department'],
        openingHours: '8:30 AM - 5:30 PM',
      ),
      
      LocationModel(
        id: 'nec_006',
        name: 'Civil Engineering Department',
        description: 'Civil Department with surveying lab and material testing facilities',
        type: LocationType.department,
        coordinates: LatLng(9.1720, 77.8720),
        buildingCode: 'CIVIL',
        images: [],
        contactInfo: {'phone': '+91-4632-225005', 'email': 'civil@nec.edu.in'},
        tags: ['Civil', 'Engineering', 'Department', 'Surveying'],
        openingHours: '8:30 AM - 5:30 PM',
      ),
      
      LocationModel(
        id: 'nec_007',
        name: 'Information Technology Department',
        description: 'IT Department with networking labs and software development facilities',
        type: LocationType.department,
        coordinates: LatLng(9.1732, 77.8717),
        buildingCode: 'IT',
        images: [],
        contactInfo: {'phone': '+91-4632-225006', 'email': 'it@nec.edu.in'},
        tags: ['IT', 'Information Technology', 'Networking', 'Department'],
        openingHours: '8:30 AM - 5:30 PM',
      ),
      
      // Central Library
      LocationModel(
        id: 'nec_008',
        name: 'Central Library (Knowledge Resource Center)',
        description: 'Multi-storey library with books, e-resources, digital library, and reading halls',
        type: LocationType.library,
        coordinates: LatLng(9.1725, 77.8718),
        buildingCode: 'LIBRARY',
        images: [],
        contactInfo: {'phone': '+91-4632-225020'},
        tags: ['Library', 'Books', 'E-Resources', 'Study', 'Reading Hall'],
        openingHours: '8:00 AM - 8:00 PM',
      ),
      
      // Hostels
      LocationModel(
        id: 'nec_009',
        name: 'Boys Hostel - Block A',
        description: 'Men\'s hostel accommodation with mess facility',
        type: LocationType.hostel,
        coordinates: LatLng(9.1735, 77.8712),
        buildingCode: 'BH-A',
        tags: ['Hostel', 'Boys', 'Accommodation', 'Mess'],
        openingHours: '24/7',
      ),
      
      LocationModel(
        id: 'nec_010',
        name: 'Girls Hostel',
        description: 'Women\'s hostel with mess and recreation facilities',
        type: LocationType.hostel,
        coordinates: LatLng(9.1718, 77.8724),
        buildingCode: 'GH',
        tags: ['Hostel', 'Girls', 'Accommodation', 'Mess'],
        openingHours: '24/7',
      ),
      
      // Cafeteria & Canteens
      LocationModel(
        id: 'nec_011',
        name: 'Main Cafeteria',
        description: 'Student cafeteria with variety of food options',
        type: LocationType.cafeteria,
        coordinates: LatLng(9.1727, 77.8714),
        buildingCode: 'CAFETERIA',
        tags: ['Food', 'Cafeteria', 'Dining', 'Canteen'],
        openingHours: '8:00 AM - 7:00 PM',
      ),
      
      // Sports & Facilities
      LocationModel(
        id: 'nec_012',
        name: 'Sports Ground & Stadium',
        description: 'Cricket ground, football field, and outdoor sports facilities',
        type: LocationType.sports,
        coordinates: LatLng(9.1738, 77.8720),
        buildingCode: 'SPORTS',
        tags: ['Sports', 'Ground', 'Stadium', 'Cricket', 'Football'],
        openingHours: '6:00 AM - 6:30 PM',
      ),
      
      LocationModel(
        id: 'nec_013',
        name: 'Indoor Sports Complex',
        description: 'Basketball court, badminton courts, and table tennis',
        type: LocationType.sports,
        coordinates: LatLng(9.1736, 77.8718),
        buildingCode: 'INDOOR',
        tags: ['Sports', 'Indoor', 'Basketball', 'Badminton', 'Table Tennis'],
        openingHours: '6:00 AM - 8:00 PM',
      ),
      
      LocationModel(
        id: 'nec_014',
        name: 'Gymnasium',
        description: 'Fitness center with modern equipment',
        type: LocationType.sports,
        coordinates: LatLng(9.1734, 77.8716),
        buildingCode: 'GYM',
        tags: ['Gym', 'Fitness', 'Workout', 'Health'],
        openingHours: '6:00 AM - 8:00 PM',
      ),
      
      // Auditorium & Halls
      LocationModel(
        id: 'nec_015',
        name: 'Main Auditorium',
        description: 'Large auditorium for events, seminars, and cultural programs',
        type: LocationType.auditorium,
        coordinates: LatLng(9.1724, 77.8719),
        buildingCode: 'AUDI',
        tags: ['Auditorium', 'Events', 'Seminars', 'Cultural'],
        openingHours: '9:00 AM - 6:00 PM',
      ),
      
      LocationModel(
        id: 'nec_016',
        name: 'Seminar Hall',
        description: 'Conference hall for workshops and seminars',
        type: LocationType.classroom,
        coordinates: LatLng(9.1723, 77.8717),
        buildingCode: 'SEM-HALL',
        tags: ['Seminar', 'Conference', 'Workshop', 'Hall'],
        openingHours: '9:00 AM - 6:00 PM',
      ),
      
      // Labs & Centers
      LocationModel(
        id: 'nec_017',
        name: 'Computer Center',
        description: 'Central computing facility with high-speed internet',
        type: LocationType.lab,
        coordinates: LatLng(9.1729, 77.8716),
        buildingCode: 'CC',
        tags: ['Computer', 'Lab', 'Internet', 'Computing'],
        openingHours: '8:30 AM - 5:30 PM',
      ),
      
      LocationModel(
        id: 'nec_018',
        name: 'Research & Development Center',
        description: 'R&D center for research projects and innovation',
        type: LocationType.lab,
        coordinates: LatLng(9.1731, 77.8719),
        buildingCode: 'R&D',
        tags: ['Research', 'Development', 'Innovation', 'Projects'],
        openingHours: '9:00 AM - 5:00 PM',
      ),
      
      LocationModel(
        id: 'nec_019',
        name: 'Workshop & Training Center',
        description: 'Central workshop for practical training and fabrication',
        type: LocationType.lab,
        coordinates: LatLng(9.1721, 77.8715),
        buildingCode: 'WORKSHOP',
        tags: ['Workshop', 'Training', 'Fabrication', 'Practical'],
        openingHours: '8:30 AM - 5:00 PM',
      ),
      
      // Medical & Services
      LocationModel(
        id: 'nec_020',
        name: 'Medical Center',
        description: 'Campus health center with medical facilities',
        type: LocationType.medical,
        coordinates: LatLng(9.1719, 77.8718),
        buildingCode: 'MEDICAL',
        tags: ['Medical', 'Health', 'Doctor', 'First Aid'],
        openingHours: '8:00 AM - 6:00 PM',
      ),
      
      LocationModel(
        id: 'nec_021',
        name: 'ATM & Bank',
        description: 'Banking facilities and ATM services',
        type: LocationType.other,
        coordinates: LatLng(9.1726, 77.8716),
        buildingCode: 'BANK',
        tags: ['ATM', 'Bank', 'Money', 'Services'],
        openingHours: '24/7 (ATM), 9:00 AM - 4:00 PM (Bank)',
      ),
      
      LocationModel(
        id: 'nec_022',
        name: 'Main Gate & Security',
        description: 'Main entrance gate with security office',
        type: LocationType.other,
        coordinates: LatLng(9.1740, 77.8715),
        buildingCode: 'GATE',
        tags: ['Gate', 'Entrance', 'Security', 'Reception'],
        openingHours: '24/7',
      ),
      
      LocationModel(
        id: 'nec_023',
        name: 'Parking Area',
        description: 'Student and staff vehicle parking',
        type: LocationType.parking,
        coordinates: LatLng(9.1738, 77.8716),
        buildingCode: 'PARKING',
        tags: ['Parking', 'Vehicles', 'Bikes', 'Cars'],
        openingHours: '24/7',
      ),
      
      LocationModel(
        id: 'nec_024',
        name: 'Student Activity Center',
        description: 'Center for student clubs, activities, and events',
        type: LocationType.other,
        coordinates: LatLng(9.1728, 77.8722),
        buildingCode: 'SAC',
        tags: ['Activities', 'Clubs', 'Students', 'Events'],
        openingHours: '9:00 AM - 7:00 PM',
      ),
      
      LocationModel(
        id: 'nec_025',
        name: 'Placement & Training Office',
        description: 'Placement cell and training coordination office',
        type: LocationType.office,
        coordinates: LatLng(9.1725, 77.8721),
        buildingCode: 'PLACEMENT',
        tags: ['Placement', 'Training', 'Jobs', 'Career'],
        openingHours: '9:00 AM - 5:00 PM',
      ),
    ];
  }

  // Get location by ID
  static LocationModel? getLocationById(String id) {
    try {
      return getSampleLocations().firstWhere((loc) => loc.id == id);
    } catch (e) {
      return null;
    }
  }

  // Search locations
  static List<LocationModel> searchLocations(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getSampleLocations().where((location) {
      return location.name.toLowerCase().contains(lowercaseQuery) ||
          location.description.toLowerCase().contains(lowercaseQuery) ||
          (location.buildingCode?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (location.tags?.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ?? false);
    }).toList();
  }

  // Get locations by type
  static List<LocationModel> getLocationsByType(LocationType type) {
    return getSampleLocations().where((loc) => loc.type == type).toList();
  }

  // Get all locations (alias for getSampleLocations)
  static List<LocationModel> getAllLocations() {
    return getSampleLocations();
  }
}
