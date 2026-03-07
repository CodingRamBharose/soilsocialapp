import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soilsocial/models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<EventModel>> getEvents() async {
    final snapshot = await _firestore
        .collection('events')
        .orderBy('startDate', descending: false)
        .get();
    return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
  }

  Future<EventModel?> getEvent(String eventId) async {
    final doc = await _firestore.collection('events').doc(eventId).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  Future<String> createEvent(EventModel event) async {
    final docRef = await _firestore.collection('events').add(event.toMap());
    return docRef.id;
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firestore.collection('events').doc(eventId).update(data);
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  Future<void> rsvpEvent(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'attendees': FieldValue.arrayUnion([userId]),
    });
    await _firestore.collection('users').doc(userId).update({
      'eventsAttending': FieldValue.arrayUnion([eventId]),
    });
  }

  Future<void> cancelRsvp(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'attendees': FieldValue.arrayRemove([userId]),
    });
    await _firestore.collection('users').doc(userId).update({
      'eventsAttending': FieldValue.arrayRemove([eventId]),
    });
  }

  Future<List<EventModel>> searchEvents(String query) async {
    final snapshot = await _firestore.collection('events').get();
    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) => EventModel.fromFirestore(doc))
        .where(
          (event) =>
              event.title.toLowerCase().contains(lowerQuery) ||
              event.description.toLowerCase().contains(lowerQuery) ||
              (event.address?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .toList();
  }
}
