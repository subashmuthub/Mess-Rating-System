/// DateTime utilities and extensions
extension DateTimeExtensions on DateTime {
  /// Check if date is today
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is past
  bool isPast() {
    return isBefore(DateTime.now());
  }

  /// Check if date is future
  bool isFuture() {
    return isAfter(DateTime.now());
  }

  /// Format as readable time (e.g., "2:30 PM")
  String toFormattedTime() {
    final hours = hour.toString().padLeft(2, '0');
    final minutes = minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  /// Format as readable date (e.g., "March 27, 2026")
  String toFormattedDate() {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[month - 1]} $day, $year';
  }

  /// Get days difference
  int daysDifference(DateTime other) {
    return difference(other).inDays.abs();
  }

  /// Get time remaining until event
  String timeUntilEvent() {
    final now = DateTime.now();
    final diff = difference(now);

    if (diff.inSeconds < 0) return 'Event passed';
    if (diff.inMinutes == 0) return 'Starting now';
    if (diff.inHours == 0) return '${diff.inMinutes}m away';
    if (diff.inDays == 0) return '${diff.inHours}h away';
    return '${diff.inDays}d away';
  }
}
