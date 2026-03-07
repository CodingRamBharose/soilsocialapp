import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soilsocial/models/user_model.dart';
import 'package:soilsocial/models/notification_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<List<UserModel>> getSuggestedUsers(String currentUserId) async {
    final currentUser = await getUser(currentUserId);
    if (currentUser == null) return [];

    final excludeIds = [
      currentUserId,
      ...currentUser.connections,
      ...currentUser.connectionRequestsSent,
      ...currentUser.connectionRequestsReceived,
    ];

    final query = await _firestore.collection('users').limit(20).get();

    return query.docs
        .where((doc) => !excludeIds.contains(doc.id))
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  Future<void> sendConnectionRequest(String fromId, String toId) async {
    final batch = _firestore.batch();
    final fromRef = _firestore.collection('users').doc(fromId);
    final toRef = _firestore.collection('users').doc(toId);

    batch.update(fromRef, {
      'connectionRequestsSent': FieldValue.arrayUnion([toId]),
    });
    batch.update(toRef, {
      'connectionRequestsReceived': FieldValue.arrayUnion([fromId]),
    });
    await batch.commit();

    final sender = await getUser(fromId);
    await _createNotification(
      userId: toId,
      senderId: fromId,
      senderName: sender?.name ?? '',
      senderProfilePicture: sender?.profilePicture,
      type: NotificationType.connection,
      content: '${sender?.name ?? 'Someone'} sent you a connection request',
    );
  }

  Future<void> acceptConnectionRequest(
    String currentUserId,
    String requesterId,
  ) async {
    final batch = _firestore.batch();
    final currentRef = _firestore.collection('users').doc(currentUserId);
    final requesterRef = _firestore.collection('users').doc(requesterId);

    batch.update(currentRef, {
      'connectionRequestsReceived': FieldValue.arrayRemove([requesterId]),
      'connections': FieldValue.arrayUnion([requesterId]),
    });
    batch.update(requesterRef, {
      'connectionRequestsSent': FieldValue.arrayRemove([currentUserId]),
      'connections': FieldValue.arrayUnion([currentUserId]),
    });
    await batch.commit();

    final currentUser = await getUser(currentUserId);
    await _createNotification(
      userId: requesterId,
      senderId: currentUserId,
      senderName: currentUser?.name ?? '',
      senderProfilePicture: currentUser?.profilePicture,
      type: NotificationType.connection,
      content:
          '${currentUser?.name ?? 'Someone'} accepted your connection request',
    );
  }

  Future<void> rejectConnectionRequest(
    String currentUserId,
    String requesterId,
  ) async {
    final batch = _firestore.batch();
    final currentRef = _firestore.collection('users').doc(currentUserId);
    final requesterRef = _firestore.collection('users').doc(requesterId);

    batch.update(currentRef, {
      'connectionRequestsReceived': FieldValue.arrayRemove([requesterId]),
    });
    batch.update(requesterRef, {
      'connectionRequestsSent': FieldValue.arrayRemove([currentUserId]),
    });
    await batch.commit();
  }

  Future<List<UserModel>> getConnectionRequests(String userId) async {
    final user = await getUser(userId);
    if (user == null || user.connectionRequestsReceived.isEmpty) return [];

    final docs = await Future.wait(
      user.connectionRequestsReceived.map(
        (id) => _firestore.collection('users').doc(id).get(),
      ),
    );
    return docs
        .where((d) => d.exists)
        .map((d) => UserModel.fromFirestore(d))
        .toList();
  }

  Future<List<UserModel>> getConnections(String userId) async {
    final user = await getUser(userId);
    if (user == null || user.connections.isEmpty) return [];

    final docs = await Future.wait(
      user.connections.map(
        (id) => _firestore.collection('users').doc(id).get(),
      ),
    );
    return docs
        .where((d) => d.exists)
        .map((d) => UserModel.fromFirestore(d))
        .toList();
  }

  String getConnectionStatus(UserModel currentUser, String otherUserId) {
    if (currentUser.connections.contains(otherUserId)) return 'connected';
    if (currentUser.connectionRequestsSent.contains(otherUserId))
      return 'pending';
    if (currentUser.connectionRequestsReceived.contains(otherUserId))
      return 'received';
    return 'none';
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final snapshot = await _firestore.collection('users').get();
    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where(
          (user) =>
              user.name.toLowerCase().contains(lowerQuery) ||
              user.email.toLowerCase().contains(lowerQuery) ||
              (user.location?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .toList();
  }

  Future<void> _createNotification({
    required String userId,
    String? senderId,
    String? senderName,
    String? senderProfilePicture,
    required NotificationType type,
    required String content,
    String? relatedId,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      senderId: senderId,
      senderName: senderName,
      senderProfilePicture: senderProfilePicture,
      type: type,
      content: content,
      relatedId: relatedId,
    );
    await _firestore.collection('notifications').add(notification.toMap());
  }
}
