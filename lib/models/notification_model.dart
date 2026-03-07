import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { connection, like, comment, message, event, marketplace }

class NotificationModel {
  final String id;
  final String userId;
  final String? senderId;
  final String? senderName;
  final String? senderProfilePicture;
  final NotificationType type;
  final String? relatedId;
  final String content;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    this.senderId,
    this.senderName,
    this.senderProfilePicture,
    required this.type,
    this.relatedId,
    required this.content,
    this.read = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      senderId: data['senderId'],
      senderName: data['senderName'],
      senderProfilePicture: data['senderProfilePicture'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.message,
      ),
      relatedId: data['relatedId'],
      content: data['content'] ?? '',
      read: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfilePicture': senderProfilePicture,
      'type': type.name,
      'relatedId': relatedId,
      'content': content,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
