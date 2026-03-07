import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/event_model.dart';
import 'package:soilsocial/services/event_service.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

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
    final l = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(l.translate('deleteEvent')),
        content: Text(l.translate('deleteEventConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
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
    final l = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.translate('eventNotFound'))),
      );
    }

    final uid = context.read<AuthProvider>().firebaseUser!.uid;
    final isOrganizer = _event!.organizerId == uid;
    final isAttending = _event!.attendees.contains(uid);
    final dateFormat = DateFormat('EEE, MMM d, yyyy h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(l.translate('eventDetails')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.dividerColor, height: 1),
        ),
        actions: [
          if (isOrganizer)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppTheme.textSecondary,
              ),
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
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          EventModel.eventTypeLabel(_event!.eventType),
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_event!.attendees.length}${_event!.maxAttendees != null ? '/${_event!.maxAttendees}' : ''} ${l.translate('attending')}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _event!.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormat.format(_event!.startDate),
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'to ${dateFormat.format(_event!.endDate)}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
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
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _event!.address!,
                            style: const TextStyle(color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: _event!.organizerProfilePicture != null
                            ? CachedNetworkImageProvider(
                                _event!.organizerProfilePicture!,
                              )
                            : null,
                        backgroundColor: AppTheme.primaryGreen.withValues(
                          alpha: 0.1,
                        ),
                        child: _event!.organizerProfilePicture == null
                            ? const Icon(
                                Icons.person,
                                size: 18,
                                color: AppTheme.primaryGreen,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.translate('organizedBy'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            _event!.organizerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.translate('about'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _event!.description,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  if (_event!.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _event!.tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (!isOrganizer) ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: isAttending
                          ? OutlinedButton.icon(
                              onPressed: _toggleRsvp,
                              icon: const Icon(Icons.check),
                              label: Text(l.translate('cancelRsvp')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                side: const BorderSide(
                                  color: AppTheme.cardBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            )
                          : FilledButton.icon(
                              onPressed: (_event!.isFull) ? null : _toggleRsvp,
                              icon: const Icon(Icons.event_available),
                              label: Text(
                                _event!.isFull
                                    ? l.translate('eventFull')
                                    : l.translate('rsvp'),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
