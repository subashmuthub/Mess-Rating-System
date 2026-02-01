# 🎓 Campus Navigation System

A comprehensive Flutter-based mobile application designed to help students, faculty, staff, and visitors navigate through a campus with ease. The system provides interactive maps, real-time navigation, voice guidance, and location management features.

## 📱 Features

### 🗺️ Core Features
- **Interactive Campus Map** - View all buildings, departments, and facilities on an interactive Google Maps interface
- **Advanced Search** - Search for locations by name, building code, department, or facility type
- **Turn-by-Turn Navigation** - Get step-by-step directions to any campus location
- **Voice Navigation** - Hands-free navigation with text-to-speech guidance
- **Multi-Floor Navigation** - Navigate between different floors within buildings
- **Offline Maps** - Access cached maps even without internet connection
- **Favorites System** - Save frequently visited locations for quick access
- **Real-time Location** - GPS-based current location tracking

### 👥 User Roles

#### 1. **Student**
- Search and navigate to classrooms, labs, libraries
- Save favorite locations (hostel, regular classrooms)
- View campus facilities and services
- Access building information and hours

#### 2. **Faculty/Staff**
- Locate departments and meeting rooms
- Share directions with students and visitors
- Access staff-specific facilities
- Navigate to different campus buildings

#### 3. **Visitor/Guest**
- Browse campus map without registration
- Search for public facilities
- Get directions to main buildings
- Guest mode access

#### 4. **Admin**
- Manage location database
- Add/update/delete campus locations
- View system analytics
- Manage user access
- Configure system settings

## 🏗️ Project Structure

```
campus_navigation_system/
├── lib/
│   ├── main.dart                      # App entry point
│   ├── models/                        # Data models
│   │   ├── user_model.dart           # User data structure
│   │   ├── location_model.dart       # Location data structure
│   │   ├── route_model.dart          # Route data structure
│   │   └── favorite_model.dart       # Favorite locations
│   ├── services/                      # Business logic
│   │   ├── auth_service.dart         # Authentication & session
│   │   ├── database_helper.dart      # SQLite database operations
│   │   └── navigation_service.dart   # Route calculation & voice
│   ├── screens/                       # UI screens
│   │   ├── login_screen.dart         # User login
│   │   ├── register_screen.dart      # New user registration
│   │   ├── home_screen.dart          # Main navigation hub
│   │   ├── map_screen.dart           # Interactive map view
│   │   ├── search_screen.dart        # Location search
│   │   ├── favorites_screen.dart     # Saved locations
│   │   ├── profile_screen.dart       # User profile
│   │   ├── location_details_screen.dart # Location info
│   │   └── admin_screen.dart         # Admin panel
│   └── data/
│       └── location_data.dart        # Sample campus locations
├── pubspec.yaml                       # Dependencies
└── README.md                          # This file
```

## 🛠️ Technologies Used

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Material Design 3** - Modern UI components
- **Google Fonts** - Custom typography (Poppins)

### Maps & Location
- **Google Maps Flutter** - Interactive map display
- **Geolocator** - GPS location services
- **Geocoding** - Address to coordinates conversion
- **Polyline Points** - Route path visualization

### State & Storage
- **Provider** - State management
- **SQLite (sqflite)** - Local database
- **Shared Preferences** - User session storage

### Voice & Accessibility
- **Flutter TTS** - Text-to-speech for voice guidance
- **Speech to Text** - Voice search capability

### Additional
- **Permission Handler** - Runtime permissions
- **Font Awesome Flutter** - Icon library

## 📦 Installation & Setup

### Prerequisites
- Flutter SDK (3.10.4 or higher)
- Dart SDK
- Android Studio / VS Code
- Android/iOS device or emulator
- Google Maps API Key (for production)

### Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd campus_navigation_system
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Google Maps API**
   - Get API key from [Google Cloud Console](https://console.cloud.google.com/)
   - For Android: Add to `android/app/src/main/AndroidManifest.xml`
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_API_KEY_HERE"/>
     ```
   - For iOS: Add to `ios/Runner/AppDelegate.swift`

4. **Run the app**
   ```bash
   flutter run
   ```

## 🎯 Usage Guide

### For Students/Faculty/Visitors

1. **First Time Setup**
   - Open the app
   - Choose "Register" to create account
   - Select your role (Student/Faculty/Visitor)
   - Complete registration
   - Or tap "Continue as Guest" for visitor access

2. **Finding a Location**
   - Tap on "Search" tab
   - Enter building name, department, or facility
   - Tap on search result to view details
   - Tap "Navigate" to get directions

3. **Using the Map**
   - View all campus locations on interactive map
   - Tap markers to see location info
   - Use filters to show specific types (labs, libraries, etc.)
   - Pinch to zoom in/out

4. **Saving Favorites**
   - Open any location details
   - Tap the ♥ icon to save
   - Access favorites from "Favorites" tab

5. **Voice Navigation**
   - Start navigation to a location
   - App will speak turn-by-turn instructions
   - Keep screen on for continuous guidance

### For Administrators

1. **Access Admin Panel**
   - Login with admin credentials
   - Tap admin icon in app bar
   - Access management features

2. **Managing Locations**
   - View all campus locations
   - Add new buildings/facilities
   - Edit existing location details
   - Delete outdated locations

3. **View Analytics**
   - Daily active users
   - Popular searches
   - Most navigated routes
   - System usage statistics

## 📊 Database Schema

### Users Table
```sql
id, name, email, role, department, phoneNumber, profileImage, createdAt
```

### Locations Table
```sql
id, name, description, type, latitude, longitude, buildingCode, 
floorNumber, roomNumber, images, contactInfo, isAccessible, 
openingHours, tags
```

### Favorites Table
```sql
id, userId, locationId, customName, createdAt
```

### Search History Table
```sql
id, userId, searchQuery, searchedAt
```

## 🎨 Key Features Explanation

### 1. Multi-Floor Navigation
The system supports indoor navigation across multiple floors. When navigating between floors, the app provides:
- Floor change indicators
- Elevator/stairs recommendations
- Floor-specific maps

### 2. Offline Functionality
- Maps are cached when viewed online
- Location database stored locally in SQLite
- Works without internet for previously visited areas

### 3. Voice Guidance
- Text-to-speech engine provides spoken directions
- Customizable voice speed and volume
- Background operation support

### 4. Role-Based Access
- Different features based on user role
- Admins have full system access
- Students/Faculty have standard navigation
- Visitors have limited read-only access

## 🔐 Security Features

- Password-based authentication
- Session management with SharedPreferences
- Role-based authorization
- Input validation on all forms
- Secure database storage

## 📝 Sample Locations

The app comes pre-loaded with 15 sample locations including:
- Computer Science Department
- Central Library
- Mechanical Engineering Block
- Student Cafeteria
- Electronics Lab
- Administrative Office
- Auditorium
- Sports Complex
- Parking Areas
- Hostels
- And more...

## 🎓 Viva/Project Review Q&A

**Q: What is Campus Navigation System?**
A: It's a mobile application that helps students, staff, and visitors navigate through campus using interactive maps, search functionality, and turn-by-turn navigation with voice guidance.

**Q: What technologies did you use?**
A: Flutter for cross-platform development, Google Maps for mapping, SQLite for local database, and Flutter TTS for voice navigation.

**Q: What are the main user roles?**
A: Student, Faculty/Staff, Visitor/Guest, and Administrator.

**Q: How does offline mode work?**
A: Maps are cached when viewed online and the location database is stored locally in SQLite, allowing basic functionality without internet.

**Q: What makes this different from Google Maps?**
A: It's customized for campus-specific navigation with:
- Pre-loaded campus locations
- Multi-floor indoor navigation
- Department and staff information
- Campus-specific facilities
- Role-based access control

## 🚀 Future Enhancements

- [ ] AR-based indoor navigation
- [ ] Real-time bus/shuttle tracking
- [ ] Event-based navigation
- [ ] QR code-based location identification
- [ ] Push notifications for campus events
- [ ] Integration with academic schedule
- [ ] Crowdsourced location updates
- [ ] Accessibility features enhancement

## 👨‍💻 Development Team

This project was developed as a college project for Final Year Engineering.

## 📄 License

This project is licensed for educational purposes.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Google Maps Platform
- Open source community
- College faculty for guidance

---

**Made with ❤️ for better campus navigation**

For questions or support, contact: support@campus.edu


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
