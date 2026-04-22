// Event Details Screen - Detailed event information

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event_model.dart';
import '../services/database_helper.dart';
import '../services/auth_service.dart';
import '../theme/app_style.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late EventModel _event;
  bool _isAttending = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _checkAttendance();
  }

  void _checkAttendance() {
    final userId = AuthService.instance.currentUser?.id;
    if (userId != null) {
      _isAttending = _event.attendees?.contains(userId) ?? false;
    }
  }


  Future<void> _toggleAttendance() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to register for events')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      late EventModel updatedEvent;
      if (_isAttending) {
        updatedEvent = _event.removeAttendee(userId);
      } else {
        if (_event.isFull) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event is fully booked')),
          );
          setState(() => _isLoading = false);
          return;
        }
        updatedEvent = _event.addAttendee(userId);
      }

      await DatabaseHelper.instance.updateEvent(updatedEvent);

      if (!mounted) return;
      setState(() {
        _event = updatedEvent;
        _isAttending = !_isAttending;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAttending
                ? 'You registered for this event'
                : 'You unregistered from this event',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  void _shareEvent() {
    final text = '''
Check out this event: ${_event.title}
📅 ${_event.formattedDateRange}
📍 ${_event.location ?? 'TBD'}

${_event.description}

Mess Management System''';

    Share.share(text, subject: _event.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyle.pageBackground,
      appBar: AppBar(
        backgroundColor: AppStyle.primary,
        title: Text(
          'Event Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareEvent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Event Header
            _buildEventHeader(),

            // Event Details
            _buildEventDetailsSection(),

            // Organizer Info
            if (_event.organizerName != null) _buildOrganizerSection(),

            // Attendees
            if (_event.maxAttendees != null) _buildAttendeesSection(),

            // Description
            _buildDescriptionSection(),

            // Tags
            if (_event.tags != null && _event.tags!.isNotEmpty)
              _buildTagsSection(),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildEventHeader() {
    final statusColor = {
      EventStatus.upcoming: AppStyle.primary,
      EventStatus.ongoing: Colors.red,
      EventStatus.completed: AppStyle.success,
      EventStatus.cancelled: Colors.grey,
    }[_event.status];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor?.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _event.statusIcon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  _event.status.name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            _event.title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 8),

          // Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppStyle.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_event.categoryIcon} ${_event.category.name.toUpperCase()}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppStyle.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetailsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: _event.formattedDate,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.access_time,
            label: 'Time',
            value: _event.formattedTime,
          ),
          if (_event.location != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.location_on,
              label: 'Location',
              value: _event.location!,
            ),
          ],
          if (_event.maxAttendees != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.people,
              label: 'Capacity',
              value:
                  '${_event.attendees?.length ?? 0}/${_event.maxAttendees} Attendees',
              valueColor: _event.isFull ? Colors.red : Colors.grey.shade700,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppStyle.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppStyle.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organizer',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppStyle.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      _event.organizerName?.substring(0, 1).toUpperCase() ??
                          '?',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _event.organizerName ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      if (_event.organizerEmail != null)
                        Text(
                          _event.organizerEmail!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registrations',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              Text(
                '${_event.attendees?.length ?? 0}/${_event.maxAttendees}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppStyle.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_event.attendees?.length ?? 0) /
                  (_event.maxAttendees ?? 1),
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                _event.isFull ? Colors.red : Colors.green,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_event.isFull)
            Text(
              '🔴 Event is fully booked',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            Text(
              '${_event.availableSeats} seats available',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppStyle.success,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Event',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _event.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _event.tags!
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$tag',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _toggleAttendance,
              icon: Icon(_isAttending ? Icons.check : Icons.add),
              label: Text(_isAttending ? 'Registered' : 'Register'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isAttending ? AppStyle.success : AppStyle.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _shareEvent,
              icon: const Icon(Icons.share),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppStyle.primary,
                side: const BorderSide(color: AppStyle.primary, width: 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
