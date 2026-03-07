import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/event_model.dart';
import 'package:soilsocial/services/event_service.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _eventService = EventService();
  EventModel? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final event = await _eventService.getEvent(widget.eventId);
    if (mounted)
      setState(() {
        _event = event;
        _isLoading = false;
      });
  }

  Future<void> _toggleRsvp() async {
    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final isAttending = _event!.attendees.contains(uid);

    if (isAttending) {
      await _eventService.cancelRsvp(_event!.id, uid);
    } else {
      await _eventService.rsvpEvent(_event!.id, uid);
    }
    _loadEvent();
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _eventService.deleteEvent(_event!.id);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Event not found')),
      );
    }

    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final isOrganizer = _event!.organizerId == uid;
    final isAttending = _event!.attendees.contains(uid);
    final dateFormat = DateFormat('EEE, MMM d, yyyy h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          if (isOrganizer)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteEvent,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_event!.imageUrl != null)
              CachedNetworkImage(
                imageUrl: _event!.imageUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          EventModel.eventTypeLabel(_event!.eventType),
                        ),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                      ),
                      const Spacer(),
                      Text(
                        '${_event!.attendees.length}${_event!.maxAttendees != null ? '/${_event!.maxAttendees}' : ''} attending',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _event!.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date/time
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateFormat.format(_event!.startDate)),
                            Text(
                              'to ${dateFormat.format(_event!.endDate)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_event!.address != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 20,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_event!.address!)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Organizer
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: _event!.organizerProfilePicture != null
                            ? CachedNetworkImageProvider(
                                _event!.organizerProfilePicture!,
                              )
                            : null,
                        child: _event!.organizerProfilePicture == null
                            ? const Icon(Icons.person, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Organized by',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _event!.organizerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_event!.description),
                  if (_event!.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _event!.tags
                          .map(
                            (t) => Chip(
                              label: Text(
                                t,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // RSVP button
                  if (!isOrganizer)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_event!.isFull && !isAttending)
                            ? null
                            : _toggleRsvp,
                        icon: Icon(
                          isAttending ? Icons.check : Icons.event_available,
                        ),
                        label: Text(
                          isAttending
                              ? 'Cancel RSVP'
                              : _event!.isFull
                              ? 'Event Full'
                              : 'RSVP',
                        ),
                        style: isAttending
                            ? ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
