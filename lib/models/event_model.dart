// Event Model - Represents campus events and announcements

import 'package:intl/intl.dart';

enum EventCategory {
  seminar,
  workshop,
  sports,
  cultural,
  academic,
  social,
  announcement,
  emergency,
}

enum EventStatus {
  upcoming,
  ongoing,
  completed,
  cancelled,
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? organizerName;
  final String? organizerEmail;
  final String? imageUrl;
  final List<String>? attendees;
  final int? maxAttendees;
  final bool isImportant;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startTime,
    required this.endTime,
    this.location,
    this.organizerName,
    this.organizerEmail,
    this.imageUrl,
    this.attendees,
    this.maxAttendees,
    this.isImportant = false,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get event status
  EventStatus get status {
    final now = DateTime.now();
    if (now.isBefore(startTime)) {
      return EventStatus.upcoming;
    } else if (now.isAfter(startTime) && now.isBefore(endTime)) {
      return EventStatus.ongoing;
    } else {
      return EventStatus.completed;
    }
  }

  // Get status icon
  String get statusIcon {
    switch (status) {
      case EventStatus.upcoming:
        return '⏰';
      case EventStatus.ongoing:
        return '🔴';
      case EventStatus.completed:
        return '✓';
      case EventStatus.cancelled:
        return '❌';
    }
  }

  // Get category icon
  String get categoryIcon {
    switch (category) {
      case EventCategory.seminar:
        return '🎤';
      case EventCategory.workshop:
        return '🛠️';
      case EventCategory.sports:
        return '⚽';
      case EventCategory.cultural:
        return '🎭';
      case EventCategory.academic:
        return '📚';
      case EventCategory.social:
        return '👥';
      case EventCategory.announcement:
        return '📢';
      case EventCategory.emergency:
        return '🚨';
    }
  }

  // Get formatted date
  String get formattedDate {
    return DateFormat('MMM dd, yyyy').format(startTime);
  }

  // Get formatted time
  String get formattedTime {
    return DateFormat('hh:mm a').format(startTime);
  }

  // Get formatted date range
  String get formattedDateRange {
    if (startTime.day == endTime.day) {
      return '${DateFormat('MMM dd, yyyy').format(startTime)} • ${DateFormat('hh:mm a').format(startTime)} - ${DateFormat('hh:mm a').format(endTime)}';
    } else {
      return '${DateFormat('MMM dd, yyyy hh:mm a').format(startTime)} - ${DateFormat('MMM dd, yyyy hh:mm a').format(endTime)}';
    }
  }

  // Check if happening today
  bool get isToday {
    final now = DateTime.now();
    return startTime.day == now.day &&
        startTime.month == now.month &&
        startTime.year == now.year;
  }

  // Check if happening this week
  bool get isThisWeek {
    final now = DateTime.now();
    final daysDifference = startTime.difference(now).inDays;
    return daysDifference >= 0 && daysDifference <= 7;
  }

  // Get available seats
  int? get availableSeats {
    if (maxAttendees == null) return null;
    return maxAttendees! - (attendees?.length ?? 0);
  }

  // Check if event is full
  bool get isFull {
    if (maxAttendees == null) return false;
    return (attendees?.length ?? 0) >= maxAttendees!;
  }

  // Add attendee
  EventModel addAttendee(String userId) {
    final newAttendees = List<String>.from(attendees ?? []);
    if (!newAttendees.contains(userId)) {
      newAttendees.add(userId);
    }
    return EventModel(
      id: id,
      title: title,
      description: description,
      category: category,
      startTime: startTime,
      endTime: endTime,
      location: location,
      organizerName: organizerName,
      organizerEmail: organizerEmail,
      imageUrl: imageUrl,
      attendees: newAttendees,
      maxAttendees: maxAttendees,
      isImportant: isImportant,
      tags: tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Remove attendee
  EventModel removeAttendee(String userId) {
    final newAttendees = List<String>.from(attendees ?? []);
    newAttendees.remove(userId);
    return EventModel(
      id: id,
      title: title,
      description: description,
      category: category,
      startTime: startTime,
      endTime: endTime,
      location: location,
      organizerName: organizerName,
      organizerEmail: organizerEmail,
      imageUrl: imageUrl,
      attendees: newAttendees,
      maxAttendees: maxAttendees,
      isImportant: isImportant,
      tags: tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'organizerName': organizerName,
      'organizerEmail': organizerEmail,
      'imageUrl': imageUrl,
      'attendees': attendees,
      'maxAttendees': maxAttendees,
      'isImportant': isImportant,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: EventCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => EventCategory.announcement,
      ),
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      location: json['location'],
      organizerName: json['organizerName'],
      organizerEmail: json['organizerEmail'],
      imageUrl: json['imageUrl'],
      attendees: json['attendees'] != null
          ? List<String>.from(json['attendees'])
          : null,
      maxAttendees: json['maxAttendees'],
      isImportant: json['isImportant'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Copy with modifications
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    EventCategory? category,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? organizerName,
    String? organizerEmail,
    String? imageUrl,
    List<String>? attendees,
    int? maxAttendees,
    bool? isImportant,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      organizerName: organizerName ?? this.organizerName,
      organizerEmail: organizerEmail ?? this.organizerEmail,
      imageUrl: imageUrl ?? this.imageUrl,
      attendees: attendees ?? this.attendees,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      isImportant: isImportant ?? this.isImportant,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
