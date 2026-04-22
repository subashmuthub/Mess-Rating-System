import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mess_models.dart';

class MessRepository {
  MessRepository._();

  static final MessRepository instance = MessRepository._();

  static const _usersKey = 'mess_users_v2';
  static const _sessionKey = 'mess_session_user_id_v2';
  static const _menusKey = 'mess_menus_v2';
  static const _ratingsKey = 'mess_ratings_v2';
  static const _complaintsKey = 'mess_complaints_v2';
  static const _suggestionsKey = 'mess_suggestions_v2';
  static const _mealIntentsKey = 'mess_meal_intents_v2';

  Future<void> init() async {
    final users = await _getUsers();
    if (users.isEmpty) {
      await _seedDefaults();
    }
  }

  Future<void> _seedDefaults() async {
    final defaultUsers = <MessUser>[
      const MessUser(
        id: 'u_admin',
        name: 'Mess Admin',
        email: 'admin@college.edu',
        password: 'admin123',
        role: UserRole.admin,
      ),
      const MessUser(
        id: 'u_warden',
        name: 'Hostel Warden',
        email: 'warden@college.edu',
        password: 'warden123',
        role: UserRole.warden,
      ),
      const MessUser(
        id: 'u_student_demo',
        name: 'Demo Student',
        email: 'student@college.edu',
        password: 'student123',
        role: UserRole.student,
        department: 'CSE',
        year: '3',
        roomNumber: 'B-213',
        hostelBlock: 'Boys Block B',
      ),
    ];

    await _setUsers(defaultUsers);

    final today = todayKey();
    final sampleMenu = DailyMenu(
      dateKey: today,
      breakfast: const [
        Dish(
          id: 'd1',
          name: 'Idli',
          isVeg: true,
          calories: 140,
          proteinGrams: 5,
          prepTimeMinutes: 20,
          tags: ['fermented', 'light'],
        ),
        Dish(
          id: 'd2',
          name: 'Sambar',
          isVeg: true,
          calories: 100,
          proteinGrams: 4,
          spiceLevel: 2,
          prepTimeMinutes: 35,
          tags: ['lentils', 'fiber'],
        ),
        Dish(
          id: 'd3',
          name: 'Coconut Chutney',
          isVeg: true,
          calories: 90,
          proteinGrams: 2,
          prepTimeMinutes: 15,
          containsNuts: true,
          tags: ['fresh'],
        ),
      ],
      lunch: const [
        Dish(
          id: 'd4',
          name: 'Rice',
          isVeg: true,
          calories: 260,
          proteinGrams: 5,
          prepTimeMinutes: 25,
          tags: ['staple'],
        ),
        Dish(
          id: 'd5',
          name: 'Sambar',
          isVeg: true,
          calories: 110,
          proteinGrams: 5,
          spiceLevel: 2,
          prepTimeMinutes: 35,
          tags: ['lentils', 'fiber'],
        ),
        Dish(
          id: 'd6',
          name: 'Potato Fry',
          isVeg: true,
          calories: 220,
          proteinGrams: 3,
          spiceLevel: 3,
          prepTimeMinutes: 30,
          tags: ['crispy'],
        ),
      ],
      dinner: const [
        Dish(
          id: 'd7',
          name: 'Chapati',
          isVeg: true,
          calories: 180,
          proteinGrams: 6,
          prepTimeMinutes: 25,
          tags: ['whole wheat'],
        ),
        Dish(
          id: 'd8',
          name: 'Dal',
          isVeg: true,
          calories: 170,
          proteinGrams: 9,
          prepTimeMinutes: 30,
          tags: ['protein'],
        ),
        Dish(
          id: 'd9',
          name: 'Paneer Curry',
          isVeg: true,
          calories: 260,
          proteinGrams: 11,
          spiceLevel: 3,
          prepTimeMinutes: 35,
          tags: ['protein', 'rich'],
        ),
      ],
      updatedAt: DateTime.now(),
      publishedBy: 'u_admin',
    );

    final menus = {today: sampleMenu};
    await _setMenus(menus);

    final intents = <MealIntent>[
      MealIntent(
        id: 'i_demo_b',
        userId: 'u_student_demo',
        dateKey: today,
        meal: MealType.breakfast,
        willEat: true,
        createdAt: DateTime.now(),
      ),
      MealIntent(
        id: 'i_demo_l',
        userId: 'u_student_demo',
        dateKey: today,
        meal: MealType.lunch,
        willEat: true,
        createdAt: DateTime.now(),
      ),
    ];

    await _setRatings(<DishRating>[]);
    await _setComplaints(<Complaint>[]);
    await _setSuggestions(<Suggestion>[]);
    await _setMealIntents(intents);
  }

  Future<List<MessUser>> _getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey) ?? '[]';
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(MessUser.fromJson).toList();
  }

  Future<void> _setUsers(List<MessUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usersKey,
      json.encode(users.map((e) => e.toJson()).toList()),
    );
  }

  Future<Map<String, DailyMenu>> _getMenus() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_menusKey) ?? '{}';
    final map = (json.decode(raw) as Map).cast<String, dynamic>();
    return map.map(
      (key, value) => MapEntry(
        key,
        DailyMenu.fromJson((value as Map).cast<String, dynamic>()),
      ),
    );
  }

  Future<void> _setMenus(Map<String, DailyMenu> menus) async {
    final prefs = await SharedPreferences.getInstance();
    final map = menus.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString(_menusKey, json.encode(map));
  }

  Future<List<DishRating>> _getRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ratingsKey) ?? '[]';
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(DishRating.fromJson).toList();
  }

  Future<void> _setRatings(List<DishRating> ratings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ratingsKey,
      json.encode(ratings.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<Complaint>> _getComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_complaintsKey) ?? '[]';
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Complaint.fromJson).toList();
  }

  Future<void> _setComplaints(List<Complaint> complaints) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _complaintsKey,
      json.encode(complaints.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<Suggestion>> _getSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_suggestionsKey) ?? '[]';
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Suggestion.fromJson).toList();
  }

  Future<void> _setSuggestions(List<Suggestion> suggestions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _suggestionsKey,
      json.encode(suggestions.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<MealIntent>> _getMealIntents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mealIntentsKey) ?? '[]';
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(MealIntent.fromJson).toList();
  }

  Future<void> _setMealIntents(List<MealIntent> intents) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _mealIntentsKey,
      json.encode(intents.map((e) => e.toJson()).toList()),
    );
  }

  Future<MessUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_sessionKey);
    if (id == null) return null;
    final users = await _getUsers();
    for (final user in users) {
      if (user.id == id) {
        return user;
      }
    }
    return null;
  }

  Future<MessUser?> login(String email, String password) async {
    final users = await _getUsers();
    for (final user in users) {
      if (user.email.toLowerCase() == email.toLowerCase() &&
          user.password == password) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionKey, user.id);
        return user;
      }
    }
    return null;
  }

  Future<MessUser?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? department,
    String? year,
    String? roomNumber,
    String? hostelBlock,
  }) async {
    final users = await _getUsers();
    if (users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      return null;
    }

    final user = MessUser(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      email: email,
      password: password,
      role: role,
      department: department,
      year: year,
      roomNumber: roomNumber,
      hostelBlock: hostelBlock,
    );

    users.add(user);
    await _setUsers(users);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, user.id);
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<DailyMenu> getMenuForDate(String dateKey) async {
    final menus = await _getMenus();
    return menus[dateKey] ??
        DailyMenu(
          dateKey: dateKey,
          breakfast: const [],
          lunch: const [],
          dinner: const [],
        );
  }

  Future<void> saveMenu(DailyMenu menu) async {
    final menus = await _getMenus();
    menus[menu.dateKey] = menu.copyWith(updatedAt: DateTime.now());
    await _setMenus(menus);
  }

  Future<bool> copyPreviousDayMenu(String dateKey, String adminUserId) async {
    final targetDate = DateTime.parse(dateKey);
    final previousKey = DateFormat('yyyy-MM-dd').format(
      targetDate.subtract(const Duration(days: 1)),
    );
    final menus = await _getMenus();
    final previous = menus[previousKey];
    if (previous == null) return false;
    menus[dateKey] = previous.copyWith(
      dateKey: dateKey,
      updatedAt: DateTime.now(),
      publishedBy: adminUserId,
    );
    await _setMenus(menus);
    return true;
  }

  Future<List<DishRating>> ratingsForDate(String dateKey) async {
    final ratings = await _getRatings();
    return ratings.where((r) => r.dateKey == dateKey).toList();
  }

  Future<List<DishRating>> ratingsByUser(String userId) async {
    final ratings = await _getRatings();
    return ratings.where((r) => r.userId == userId).toList();
  }

  Future<bool> submitRating(DishRating rating) async {
    final ratings = await _getRatings();
    final alreadyExists = ratings.any(
      (r) =>
          r.userId == rating.userId &&
          r.dateKey == rating.dateKey &&
          r.meal == rating.meal &&
          r.dishId == rating.dishId,
    );
    if (alreadyExists) return false;
    ratings.add(rating);
    await _setRatings(ratings);
    return true;
  }

  Future<double> averageForDish(String dishId) async {
    final ratings = await _getRatings();
    final dishRatings = ratings.where((r) => r.dishId == dishId).toList();
    if (dishRatings.isEmpty) return 0;
    final total = dishRatings.fold<int>(0, (sum, item) => sum + item.stars);
    return total / dishRatings.length;
  }

  Future<Map<String, double>> dishAverages() async {
    final ratings = await _getRatings();
    final bucket = <String, List<int>>{};
    for (final rating in ratings) {
      bucket.putIfAbsent(rating.dishId, () => <int>[]).add(rating.stars);
    }

    return bucket.map((dishId, values) {
      final total = values.fold<int>(0, (sum, v) => sum + v);
      return MapEntry(dishId, total / values.length);
    });
  }

  Future<double> weeklyAverage({int days = 7}) async {
    final ratings = await _getRatings();
    if (ratings.isEmpty) return 0;
    final today = DateTime.now();
    final validDateKeys = <String>{};
    for (var i = 0; i < days; i++) {
      validDateKeys.add(
        DateFormat('yyyy-MM-dd').format(today.subtract(Duration(days: i))),
      );
    }
    final recent = ratings.where((r) => validDateKeys.contains(r.dateKey)).toList();
    if (recent.isEmpty) return 0;
    final total = recent.fold<int>(0, (sum, item) => sum + item.stars);
    return total / recent.length;
  }

  Future<List<MapEntry<String, double>>> dailyAverageTimeline({int days = 7}) async {
    final ratings = await _getRatings();
    final today = DateTime.now();
    final output = <MapEntry<String, double>>[];
    for (var i = days - 1; i >= 0; i--) {
      final key = DateFormat('yyyy-MM-dd').format(today.subtract(Duration(days: i)));
      final dayRatings = ratings.where((r) => r.dateKey == key).toList();
      if (dayRatings.isEmpty) {
        output.add(MapEntry(key, 0));
      } else {
        final total = dayRatings.fold<int>(0, (sum, item) => sum + item.stars);
        output.add(MapEntry(key, total / dayRatings.length));
      }
    }
    return output;
  }

  Future<void> addComplaint(Complaint complaint) async {
    final complaints = await _getComplaints();
    complaints.add(complaint);
    await _setComplaints(complaints);
  }

  Future<List<Complaint>> complaints() => _getComplaints();

  Future<List<Complaint>> complaintsByUser(String userId) async {
    final list = await _getComplaints();
    return list.where((c) => c.userId == userId).toList();
  }

  Future<void> updateComplaintStatus(
    String complaintId,
    String status, {
    String? assignedTo,
  }) async {
    final complaints = await _getComplaints();
    final updated = complaints.map((c) {
      if (c.id != complaintId) return c;
      return c.copyWith(
        status: status,
        assignedTo: assignedTo,
        updatedAt: DateTime.now(),
        resolvedAt: status == 'Resolved' ? DateTime.now() : c.resolvedAt,
      );
    }).toList();
    await _setComplaints(updated);
  }

  Future<List<Complaint>> overdueComplaints({int hours = 24}) async {
    final list = await _getComplaints();
    final now = DateTime.now();
    return list.where((c) {
      if (c.status == 'Resolved') return false;
      return now.difference(c.createdAt).inHours >= hours;
    }).toList();
  }

  Future<Map<String, int>> topComplaintCategories({int days = 7}) async {
    final list = await _getComplaints();
    final now = DateTime.now();
    final counts = <String, int>{};
    for (final complaint in list) {
      if (now.difference(complaint.createdAt).inDays > days) continue;
      counts.update(complaint.category, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  Future<void> addSuggestion(Suggestion suggestion) async {
    final suggestions = await _getSuggestions();
    suggestions.add(suggestion);
    await _setSuggestions(suggestions);
  }

  Future<bool> upvoteSuggestion(
    String suggestionId, {
    required String voterUserId,
  }) async {
    final suggestions = await _getSuggestions();
    var voted = false;
    final updated = suggestions.map((s) {
      if (s.id != suggestionId) return s;
      if (s.voterUserIds.contains(voterUserId)) return s;
      voted = true;
      return s.copyWith(
        votes: s.votes + 1,
        voterUserIds: [...s.voterUserIds, voterUserId],
      );
    }).toList();
    if (!voted) return false;
    await _setSuggestions(updated);
    return true;
  }

  Future<void> acceptSuggestion(
    String suggestionId, {
    required String adminUserId,
  }) async {
    final suggestions = await _getSuggestions();
    final updated = suggestions.map((s) {
      if (s.id != suggestionId) return s;
      return s.copyWith(
        accepted: true,
        status: SuggestionStatus.accepted,
        acceptedByUserId: adminUserId,
      );
    }).toList();
    await _setSuggestions(updated);
  }

  Future<void> scheduleSuggestion(
    String suggestionId,
    String dateKey, {
    required String adminUserId,
  }) async {
    final suggestions = await _getSuggestions();
    final updated = suggestions.map((s) {
      if (s.id != suggestionId) return s;
      return s.copyWith(
        accepted: true,
        status: SuggestionStatus.scheduled,
        scheduledForDateKey: dateKey,
        acceptedByUserId: adminUserId,
      );
    }).toList();
    await _setSuggestions(updated);
  }

  Future<List<Suggestion>> suggestions() => _getSuggestions();

  Future<MealIntent?> mealIntentByUser({
    required String userId,
    required String dateKey,
    required MealType meal,
  }) async {
    final intents = await _getMealIntents();
    for (final intent in intents) {
      if (intent.userId == userId && intent.dateKey == dateKey && intent.meal == meal) {
        return intent;
      }
    }
    return null;
  }

  Future<void> upsertMealIntent({
    required String userId,
    required String dateKey,
    required MealType meal,
    required bool willEat,
    String? noShowReason,
  }) async {
    final intents = await _getMealIntents();
    var found = false;
    final updated = intents.map((intent) {
      if (intent.userId == userId && intent.dateKey == dateKey && intent.meal == meal) {
        found = true;
        return intent.copyWith(
          willEat: willEat,
          noShowReason: noShowReason,
          createdAt: DateTime.now(),
        );
      }
      return intent;
    }).toList();

    if (!found) {
      updated.add(
        MealIntent(
          id: 'i_${DateTime.now().microsecondsSinceEpoch}',
          userId: userId,
          dateKey: dateKey,
          meal: meal,
          willEat: willEat,
          noShowReason: noShowReason,
          createdAt: DateTime.now(),
        ),
      );
    }

    await _setMealIntents(updated);
  }

  Future<List<MealIntent>> mealIntentsForDate(String dateKey) async {
    final intents = await _getMealIntents();
    return intents.where((i) => i.dateKey == dateKey).toList();
  }

  Future<double> crowdForecastRatio({
    required String dateKey,
    required MealType meal,
  }) async {
    final users = await _getUsers();
    final studentCount = users.where((u) => u.role == UserRole.student).length;
    if (studentCount == 0) return 0;
    final intents = await _getMealIntents();
    final eatCount = intents.where((i) => i.dateKey == dateKey && i.meal == meal && i.willEat).length;
    return eatCount / studentCount;
  }
}
