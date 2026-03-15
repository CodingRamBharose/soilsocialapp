import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soilsocial/models/message_model.dart';
import 'package:soilsocial/models/user_model.dart';
import 'package:soilsocial/models/notification_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MessageModel>> getMessages(
    String currentUserId,
    String otherUserId,
  ) {
    return _firestore
        .collection('messages')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .where(
            (msg) =>
                (msg.senderId == currentUserId &&
                    msg.receiverId == otherUserId) ||
                (msg.senderId == otherUserId &&
                    msg.receiverId == currentUserId),
          )
          .toList();
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return messages;
    });
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    required String senderName,
  }) async {
    await _firestore.collection('messages').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'read': false,
      'participants': [senderId, receiverId],
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });

    await _firestore.collection('notifications').add(
          NotificationModel(
            id: '',
            userId: receiverId,
            senderId: senderId,
            senderName: senderName,
            type: NotificationType.message,
            content: '$senderName sent you a message',
          ).toMap(),
        );
  }

  Future<void> markMessagesAsRead(
    String currentUserId,
    String otherUserId,
  ) async {
    final snapshot = await _firestore
        .collection('messages')
        .where('senderId', isEqualTo: otherUserId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<List<ConversationModel>> getConversations(
      String currentUserId) async {
    final snapshot = await _firestore
        .collection('messages')
        .where('participants', arrayContains: currentUserId)
        .get();

    final allMessages = snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc))
        .toList();
    allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final Map<String, List<MessageModel>> grouped = {};
    for (final msg in allMessages) {
      final otherUserId =
          msg.senderId == currentUserId ? msg.receiverId : msg.senderId;
      grouped.putIfAbsent(otherUserId, () => []).add(msg);
    }

    final conversations = <ConversationModel>[];
    for (final entry in grouped.entries) {
      final otherUserId = entry.key;
      final messages = entry.value;
      final lastMsg = messages.first;
      final unreadCount = messages
          .where((m) => m.receiverId == currentUserId && !m.read)
          .length;

      final userDoc =
          await _firestore.collection('users').doc(otherUserId).get();
      if (!userDoc.exists) continue;
      final otherUser = UserModel.fromFirestore(userDoc);

      conversations.add(
        ConversationModel(
          otherUserId: otherUserId,
          otherUserName: otherUser.name,
          otherUserProfilePicture: otherUser.profilePicture,
          lastMessage: lastMsg.content,
          lastMessageTime: lastMsg.createdAt,
          unreadCount: unreadCount,
        ),
      );
    }

    return conversations;
  }
}
