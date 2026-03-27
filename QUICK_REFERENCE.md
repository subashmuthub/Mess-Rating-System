# 🚀 Quick Reference Guide

## Project Structure at a Glance

```
lib/
├── screens/         → UI Layers: auth/, main/, details/
├── models/          → Data structures (A-Z)
├── services/        → Business logic (A-Z)
├── theme/           → Design tokens & styling
├── data/
│   ├── constants/   → App routes & constants
│   └── config/      → Feature flags & configs
├── utils/           → Extensions & helpers
├── widgets/         → (Reserved) Reusable components
└── main.dart        → Entry point
```

## File Naming Convention

| Type | Format | Example |
|------|--------|---------|
| **Files** | snake_case | `login_screen.dart` |
| **Classes** | PascalCase | `class LoginScreen` |
| **Methods** | camelCase | `void loadUserData()` |
| **Variables** | camelCase | `var isLoading = true;` |
| **Constants** | camelCase | `const maxRetries = 3;` |

## Common Tasks

### Add a New Screen
1. Create: `lib/screens/[auth\|main\|details]/new_screen.dart`
2. Class: `class NewScreen extends StatelessWidget { ... }`
3. Export: Add to `lib/screens/[category]/index.dart`
4. Import: `import 'package:campus_navigation_system/screens/index.dart';`

### Add a New Model
1. Create: `lib/models/new_model.dart`
2. Class: `class NewModel { ... }`
3. Export: Add to `lib/models/index.dart`
4. Keep alphabetically ordered!

### Add a New Service
1. Create: `lib/services/new_service.dart`
2. Class: `class NewService { static final instance = NewService._(); ... }`
3. Export: Add to `lib/services/index.dart`
4. Keep alphabetically ordered!

### Add a New Utility
1. Create: `lib/utils/new_extension.dart`
2. Extension: `extension NewExtension on SomeType { ... }`
3. Export: Add to `lib/utils/index.dart`

### Add a New Constant
1. Location: `lib/data/constants/app_constants.dart`
2. Add: `static const String myConstant = 'value';`
3. Keep organized by category

## Import Examples

```dart
// ✅ Import entire category
import 'package:campus_navigation_system/screens/index.dart';

// ✅ Import specific subcategory
import 'package:campus_navigation_system/screens/auth/index.dart';

// ✅ Use services directly (singleton pattern)
final user = AuthService.instance.currentUser;

// ✅ Use extensions
print('hello'.capitalize()); // "Hello"

// ❌ Never do this
import 'package:campus_navigation_system/screens/login_screen.dart';
```

## Analyzer & Tests

```bash
# Check code quality
flutter analyze

# Run tests
flutter test

# Fix issues
dart fix --apply
```

## File Count Summary
- 🎨 **Screens:** 14 (auth: 2, main: 8, details: 4)
- 📊 **Models:** 5
- ⚙️ **Services:** 5
- 🎭 **Theme:** 1
- 📝 **Constants:** 2
- ⚙️ **Config:** 2
- 🛠️ **Utils:** 2

---

**Total Organized Files: 48+**  
**Status: ✅ Production Ready**
