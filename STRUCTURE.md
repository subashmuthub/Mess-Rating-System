# Campus Navigation System - Project Structure

## 📁 Directory Organization

```
lib/
├── screens/                    # UI Screens (organized by functionality)
│   ├── auth/                   # Authentication screens
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── main/                   # Main application screens
│   │   ├── admin_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── events_screen.dart
│   │   ├── favorites_screen.dart
│   │   ├── home_screen.dart
│   │   ├── map_screen.dart
│   │   ├── profile_screen.dart
│   │   └── search_screen.dart
│   ├── details/                # Detail and feature screens
│   │   ├── event_details_screen.dart
│   │   ├── location_details_screen.dart
│   │   ├── navigation_screen.dart
│   │   └── virtual_tour_screen.dart
│   └── index.dart              # Screen barrel export
│
├── models/                     # Data models (alphabetically)
│   ├── event_model.dart
│   ├── favorite_model.dart
│   ├── location_model.dart
│   ├── route_model.dart
│   ├── user_model.dart
│   └── index.dart              # Models barrel export
│
├── services/                   # Business logic services (alphabetically)
│   ├── auth_service.dart       # Authentication service
│   ├── database_helper.dart    # Local database operations
│   ├── firebase_service.dart   # Firebase integration
│   ├── location_sync_service.dart
│   ├── navigation_service.dart
│   └── index.dart              # Services barrel export
│
├── theme/                      # UI theming and styling
│   ├── app_style.dart          # Centralized design tokens
│   └── index.dart              # Theme barrel export
│
├── data/                       # Application data
│   ├── constants/              # Application constants
│   │   ├── app_constants.dart
│   │   ├── app_routes.dart
│   │   └── index.dart
│   ├── config/                 # Configuration files
│   │   ├── app_config.dart
│   │   ├── firebase_config.dart
│   │   └── index.dart
│   └── (Future: seed data, mock data, etc.)
│
├── utils/                      # Utility functions and extensions
│   ├── datetime_extensions.dart
│   ├── string_extensions.dart
│   └── index.dart
│
├── widgets/                    # Reusable widget components (future)
│   └── (custom buttons, forms, dialogs, etc.)
│
├── main.dart                   # App entry point
├── firebase_options.dart       # Firebase configuration (auto-generated)
└── README.md                   # This file

```

## 📋 File Naming Conventions

- **Files:** snake_case (e.g., `login_screen.dart`, `auth_service.dart`)
- **Classes:** PascalCase (e.g., `LoginScreen`, `AuthService`)
- **Variables/Methods:** camelCase (e.g., `isLoading`, `getCurrentUser()`)
- **Constants:** camelCase or UPPER_SNAKE_CASE (e.g., `maxRetries`, `API_KEY`)

## 📦 Import Strategy

### Prefer barrel exports for cleaner imports:
```dart
// ✅ Good - Using barrel exports
import 'package:campus_navigation_system/screens/index.dart';
import 'package:campus_navigation_system/models/index.dart';
import 'package:campus_navigation_system/services/index.dart';

// ❌ Avoid - Long individual imports
import 'package:campus_navigation_system/screens/auth/login_screen.dart';
import 'package:campus_navigation_system/screens/main/home_screen.dart';
```

## 🎯 Layer Responsibilities

### Screens Layer
- UI presentation only
- User interaction handling
- State management (using Provider)
- No business logic

### Models Layer
- Data structures
- Serialization/Deserialization
- Immutability where possible

### Services Layer
- Business logic
- Firebase operations
- Database operations
- External API calls
- State management (Singleton pattern)

### Theme Layer
- Color tokens (AppStyle)
- Typography
- Layout constants
- Shared decorations

### Data Layer
- Constants (app-wide values)
- Configuration (feature flags, settings)
- Routes (navigation paths)
- Seed data (future)

### Utils Layer
- Helper functions
- Extensions
- Formatters
- Validators

## 🚀 How to Add New Components

### Add a new screen:
1. Create in appropriate subfolder (auth/main/details)
2. Add to barrel export in `screens/[subfolder]/index.dart`
3. Update main screens `index.dart`

### Add a new service:
1. Create in `services/` folder (follow alphabetical order)
2. Add to `services/index.dart`
3. Update imports in dependent files

### Add a new model:
1. Create in `models/` folder (follow alphabetical order)
2. Add to `models/index.dart`
3. Update imports in dependent files

### Add a new utility:
1. Create extension/utility file in `utils/`
2. Export in `utils/index.dart`
3. Use `import 'package:campus_navigation_system/utils/index.dart';`

## 📝 Navigation Structure

All routes are defined in `lib/data/constants/app_routes.dart`:
- Auth routes: `/login`, `/register`
- Main routes: `/home`, `/dashboard`, `/map`, `/search`, etc.
- Detail routes: `/location-details`, `/event-details`, `/navigation`

## ⚙️ Configuration

- **App Config:** `lib/data/config/app_config.dart` (feature flags, settings)
- **Firebase Config:** `lib/data/config/firebase_config.dart` (Firebase setup)
- **Constants:** `lib/data/constants/app_constants.dart` (app-wide constants)

## 📊 Total File Count

- Screens: 14 files (organized in 3 subfolders)
- Models: 5 files
- Services: 5 files
- Theme: 1 file (plus index)
- Data: Constants (2) + Config (2)
- Utils: 2 files (plus index)
- Widgets: 0 files (reserved for future reusable components)

## ✅ Alignment Checklist

- [x] Folder structure organized by feature/layer
- [x] File naming consistent (snake_case)
- [x] Barrel exports for clean imports
- [x] Alphabetical ordering within categories
- [x] Configuration and constants centralized
- [x] Services and models properly separated
- [x] Theme/styling tokens isolated
- [x] Utility extensions organized
- [x] Reserved folders for future expansion (widgets)

---

**Last Updated:** March 27, 2026
**Version:** 1.0.0
