import 'package:cloud_firestore/cloud_firestore.dart';

enum EventType { workshop, harvestFestival, farmTour, market, training, other }

class EventModel {
  final String id;
  final String organizerId;
  final String organizerName;
  final String? organizerProfilePicture;
  final List<String> attendees;
  final EventType eventType;
  final String title;
  final String description;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime startDate;
  final DateTime endDate;
  final int? maxAttendees;
  final List<String> tags;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.organizerId,
    required this.organizerName,
    this.organizerProfilePicture,
    this.attendees = const [],
    required this.eventType,
    required this.title,
    required this.description,
    this.address,
    this.latitude,
    this.longitude,
    required this.startDate,
    required this.endDate,
    this.maxAttendees,
    this.tags = const [],
    this.imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isFull => maxAttendees != null && attendees.length >= maxAttendees!;

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      organizerProfilePicture: data['organizerProfilePicture'],
      attendees: List<String>.from(data['attendees'] ?? []),
      eventType: EventType.values.firstWhere(
        (e) => e.name == data['eventType'],
        orElse: () => EventType.other,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      address: data['address'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxAttendees: data['maxAttendees'],
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerProfilePicture': organizerProfilePicture,
      'attendees': attendees,
      'eventType': eventType.name,
      'title': title,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'maxAttendees': maxAttendees,
      'tags': tags,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  static String eventTypeLabel(EventType type) {
    switch (type) {
      case EventType.workshop:
        return 'Workshop';
      case EventType.harvestFestival:
        return 'Harvest Festival';
      case EventType.farmTour:
        return 'Farm Tour';
      case EventType.market:
        return 'Market';
      case EventType.training:
        return 'Training';
      case EventType.other:
        return 'Other';
    }
  }
}
