import 'package:intl/intl.dart';

enum UserRole { student, admin, warden }

enum MealType { breakfast, lunch, dinner }

enum ComplaintSeverity { low, medium, high, critical }

enum SuggestionStatus { proposed, shortlisted, accepted, scheduled }

String todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

String mealLabel(MealType meal) {
  switch (meal) {
    case MealType.breakfast:
      return 'Breakfast';
    case MealType.lunch:
      return 'Lunch';
    case MealType.dinner:
      return 'Dinner';
  }
}

String crowdLabel(double ratio) {
  if (ratio < 0.35) return 'Low crowd';
  if (ratio < 0.7) return 'Moderate crowd';
  return 'High crowd';
}

UserRole roleFromString(String value) {
  return UserRole.values.firstWhere(
    (e) => e.name == value,
    orElse: () => UserRole.student,
  );
}

MealType mealFromString(String value) {
  return MealType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => MealType.breakfast,
  );
}

ComplaintSeverity complaintSeverityFromString(String value) {
  return ComplaintSeverity.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ComplaintSeverity.medium,
  );
}

SuggestionStatus suggestionStatusFromString(String value) {
  return SuggestionStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => SuggestionStatus.proposed,
  );
}

class MessUser {
  const MessUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.department,
    this.year,
    this.roomNumber,
    this.hostelBlock,
    this.messId = 'main_mess',
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String? department;
  final String? year;
  final String? roomNumber;
  final String? hostelBlock;
  final String messId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': password,
    'role': role.name,
    'department': department,
    'year': year,
    'roomNumber': roomNumber,
    'hostelBlock': hostelBlock,
    'messId': messId,
  };

  factory MessUser.fromJson(Map<String, dynamic> json) {
    return MessUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      role: roleFromString(json['role'] as String? ?? 'student'),
      department: json['department'] as String?,
      year: json['year'] as String?,
      roomNumber: json['roomNumber'] as String?,
      hostelBlock: json['hostelBlock'] as String?,
      messId: json['messId'] as String? ?? 'main_mess',
    );
  }
}

class Dish {
  const Dish({
    required this.id,
    required this.name,
    required this.isVeg,
    this.containsEgg = false,
    this.containsNuts = false,
    this.photoUrl,
    this.calories,
    this.proteinGrams,
    this.spiceLevel = 1,
    this.prepTimeMinutes,
    this.tags = const <String>[],
  });

  final String id;
  final String name;
  final bool isVeg;
  final bool containsEgg;
  final bool containsNuts;
  final String? photoUrl;
  final int? calories;
  final int? proteinGrams;
  final int spiceLevel;
  final int? prepTimeMinutes;
  final List<String> tags;

  Dish copyWith({
    String? id,
    String? name,
    bool? isVeg,
    bool? containsEgg,
    bool? containsNuts,
    String? photoUrl,
    int? calories,
    int? proteinGrams,
    int? spiceLevel,
    int? prepTimeMinutes,
    List<String>? tags,
  }) {
    return Dish(
      id: id ?? this.id,
      name: name ?? this.name,
      isVeg: isVeg ?? this.isVeg,
      containsEgg: containsEgg ?? this.containsEgg,
      containsNuts: containsNuts ?? this.containsNuts,
      photoUrl: photoUrl ?? this.photoUrl,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isVeg': isVeg,
    'containsEgg': containsEgg,
    'containsNuts': containsNuts,
    'photoUrl': photoUrl,
    'calories': calories,
    'proteinGrams': proteinGrams,
    'spiceLevel': spiceLevel,
    'prepTimeMinutes': prepTimeMinutes,
    'tags': tags,
  };

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] as String,
      name: json['name'] as String,
      isVeg: json['isVeg'] as bool? ?? true,
      containsEgg: json['containsEgg'] as bool? ?? false,
      containsNuts: json['containsNuts'] as bool? ?? false,
      photoUrl: json['photoUrl'] as String?,
      calories: json['calories'] as int?,
      proteinGrams: json['proteinGrams'] as int?,
      spiceLevel: json['spiceLevel'] as int? ?? 1,
      prepTimeMinutes: json['prepTimeMinutes'] as int?,
      tags: ((json['tags'] as List?) ?? <dynamic>[]).cast<String>(),
    );
  }
}

class DailyMenu {
  const DailyMenu({
    required this.dateKey,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    this.isHoliday = false,
    this.updatedAt,
    this.publishedBy,
  });

  final String dateKey;
  final List<Dish> breakfast;
  final List<Dish> lunch;
  final List<Dish> dinner;
  final bool isHoliday;
  final DateTime? updatedAt;
  final String? publishedBy;

  List<Dish> dishesFor(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return breakfast;
      case MealType.lunch:
        return lunch;
      case MealType.dinner:
        return dinner;
    }
  }

  DailyMenu copyWith({
    String? dateKey,
    List<Dish>? breakfast,
    List<Dish>? lunch,
    List<Dish>? dinner,
    bool? isHoliday,
    DateTime? updatedAt,
    String? publishedBy,
  }) {
    return DailyMenu(
      dateKey: dateKey ?? this.dateKey,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      isHoliday: isHoliday ?? this.isHoliday,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedBy: publishedBy ?? this.publishedBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'dateKey': dateKey,
    'breakfast': breakfast.map((e) => e.toJson()).toList(),
    'lunch': lunch.map((e) => e.toJson()).toList(),
    'dinner': dinner.map((e) => e.toJson()).toList(),
    'isHoliday': isHoliday,
    'updatedAt': updatedAt?.toIso8601String(),
    'publishedBy': publishedBy,
  };

  factory DailyMenu.fromJson(Map<String, dynamic> json) {
    List<Dish> parseList(String key) {
      final raw = (json[key] as List? ?? <dynamic>[])
          .cast<Map<String, dynamic>>();
      return raw.map(Dish.fromJson).toList();
    }

    return DailyMenu(
      dateKey: json['dateKey'] as String,
      breakfast: parseList('breakfast'),
      lunch: parseList('lunch'),
      dinner: parseList('dinner'),
      isHoliday: json['isHoliday'] as bool? ?? false,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      publishedBy: json['publishedBy'] as String?,
    );
  }
}

class DishRating {
  const DishRating({
    required this.id,
    required this.userId,
    required this.dateKey,
    required this.meal,
    required this.dishId,
    required this.stars,
    required this.tags,
    required this.createdAt,
    this.review,
  });

  final String id;
  final String userId;
  final String dateKey;
  final MealType meal;
  final String dishId;
  final int stars;
  final String? review;
  final List<String> tags;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'dateKey': dateKey,
    'meal': meal.name,
    'dishId': dishId,
    'stars': stars,
    'review': review,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DishRating.fromJson(Map<String, dynamic> json) {
    return DishRating(
      id: json['id'] as String,
      userId: json['userId'] as String,
      dateKey: json['dateKey'] as String,
      meal: mealFromString(json['meal'] as String? ?? 'breakfast'),
      dishId: json['dishId'] as String,
      stars: json['stars'] as int,
      review: json['review'] as String?,
      tags: ((json['tags'] as List?) ?? <dynamic>[]).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class MealIntent {
  const MealIntent({
    required this.id,
    required this.userId,
    required this.dateKey,
    required this.meal,
    required this.willEat,
    required this.createdAt,
    this.noShowReason,
  });

  final String id;
  final String userId;
  final String dateKey;
  final MealType meal;
  final bool willEat;
  final String? noShowReason;
  final DateTime createdAt;

  MealIntent copyWith({
    bool? willEat,
    String? noShowReason,
    DateTime? createdAt,
  }) {
    return MealIntent(
      id: id,
      userId: userId,
      dateKey: dateKey,
      meal: meal,
      willEat: willEat ?? this.willEat,
      noShowReason: noShowReason ?? this.noShowReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'dateKey': dateKey,
    'meal': meal.name,
    'willEat': willEat,
    'noShowReason': noShowReason,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MealIntent.fromJson(Map<String, dynamic> json) {
    return MealIntent(
      id: json['id'] as String,
      userId: json['userId'] as String,
      dateKey: json['dateKey'] as String,
      meal: mealFromString(json['meal'] as String? ?? 'breakfast'),
      willEat: json['willEat'] as bool? ?? true,
      noShowReason: json['noShowReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class Complaint {
  const Complaint({
    required this.id,
    required this.userId,
    required this.dateKey,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.meal,
    this.dishName,
    this.severity = ComplaintSeverity.medium,
    this.anonymous = false,
    this.assignedTo,
    this.updatedAt,
    this.resolvedAt,
  });

  final String id;
  final String userId;
  final String dateKey;
  final MealType? meal;
  final String? dishName;
  final String category;
  final String description;
  final String status;
  final ComplaintSeverity severity;
  final bool anonymous;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  Complaint copyWith({
    String? status,
    ComplaintSeverity? severity,
    bool? anonymous,
    String? assignedTo,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return Complaint(
      id: id,
      userId: userId,
      dateKey: dateKey,
      meal: meal,
      dishName: dishName,
      category: category,
      description: description,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      anonymous: anonymous ?? this.anonymous,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'dateKey': dateKey,
    'meal': meal?.name,
    'dishName': dishName,
    'category': category,
    'description': description,
    'status': status,
    'severity': severity.name,
    'anonymous': anonymous,
    'assignedTo': assignedTo,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
  };

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'] as String,
      userId: json['userId'] as String,
      dateKey: json['dateKey'] as String,
      meal: json['meal'] == null ? null : mealFromString(json['meal'] as String),
      dishName: json['dishName'] as String?,
      category: json['category'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      severity: complaintSeverityFromString(json['severity'] as String? ?? 'medium'),
      anonymous: json['anonymous'] as bool? ?? false,
      assignedTo: json['assignedTo'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
    );
  }
}

class Suggestion {
  const Suggestion({
    required this.id,
    required this.userId,
    required this.dishName,
    required this.votes,
    required this.createdAt,
    this.accepted = false,
    this.status = SuggestionStatus.proposed,
    this.scheduledForDateKey,
    this.acceptedByUserId,
    this.voterUserIds = const <String>[],
    this.preferredMeal,
  });

  final String id;
  final String userId;
  final String dishName;
  final int votes;
  final bool accepted;
  final SuggestionStatus status;
  final String? scheduledForDateKey;
  final String? acceptedByUserId;
  final List<String> voterUserIds;
  final MealType? preferredMeal;
  final DateTime createdAt;

  Suggestion copyWith({
    int? votes,
    bool? accepted,
    SuggestionStatus? status,
    String? scheduledForDateKey,
    String? acceptedByUserId,
    List<String>? voterUserIds,
    MealType? preferredMeal,
  }) {
    return Suggestion(
      id: id,
      userId: userId,
      dishName: dishName,
      votes: votes ?? this.votes,
      accepted: accepted ?? this.accepted,
      status: status ?? this.status,
      scheduledForDateKey: scheduledForDateKey ?? this.scheduledForDateKey,
      acceptedByUserId: acceptedByUserId ?? this.acceptedByUserId,
      voterUserIds: voterUserIds ?? this.voterUserIds,
      preferredMeal: preferredMeal ?? this.preferredMeal,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'dishName': dishName,
    'votes': votes,
    'accepted': accepted,
    'status': status.name,
    'scheduledForDateKey': scheduledForDateKey,
    'acceptedByUserId': acceptedByUserId,
    'voterUserIds': voterUserIds,
    'preferredMeal': preferredMeal?.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      id: json['id'] as String,
      userId: json['userId'] as String,
      dishName: json['dishName'] as String,
      votes: json['votes'] as int? ?? 0,
      accepted: json['accepted'] as bool? ?? false,
      status: suggestionStatusFromString(json['status'] as String? ?? 'proposed'),
      scheduledForDateKey: json['scheduledForDateKey'] as String?,
      acceptedByUserId: json['acceptedByUserId'] as String?,
      voterUserIds: ((json['voterUserIds'] as List?) ?? <dynamic>[]).cast<String>(),
      preferredMeal: json['preferredMeal'] == null
          ? null
          : mealFromString(json['preferredMeal'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
