import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soilsocial/models/post_model.dart';
import 'package:soilsocial/models/comment_model.dart';
import 'package:soilsocial/models/notification_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<PostModel>> getPosts({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  Future<PostModel?> getPost(String postId) async {
    final doc = await _firestore.collection('posts').doc(postId).get();
    if (!doc.exists) return null;
    return PostModel.fromFirestore(doc);
  }

  Future<String> createPost(PostModel post) async {
    final docRef = await _firestore.collection('posts').add(post.toMap());
    return docRef.id;
  }

  Future<void> deletePost(String postId) async {
    // Delete all comments for this post
    final comments = await _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .get();
    final batch = _firestore.batch();
    for (final doc in comments.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('posts').doc(postId));
    await batch.commit();
  }

  Future<void> toggleLike(
    String postId,
    String userId,
    String postAuthorId,
  ) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final postDoc = await postRef.get();
    final likes = List<String>.from(
      (postDoc.data() as Map<String, dynamic>)['likes'] ?? [],
    );

    if (likes.contains(userId)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([userId]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([userId]),
      });

      if (userId != postAuthorId) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userName = userDoc.data()?['name'] ?? 'Someone';
        await _firestore
            .collection('notifications')
            .add(
              NotificationModel(
                id: '',
                userId: postAuthorId,
                senderId: userId,
                senderName: userName,
                type: NotificationType.like,
                content: '$userName liked your post',
                relatedId: postId,
              ).toMap(),
            );
      }
    }
  }

  Future<List<CommentModel>> getComments(String postId) async {
    final snapshot = await _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs.map((doc) => CommentModel.fromFirestore(doc)).toList();
  }

  Future<void> addComment(CommentModel comment, String postAuthorId) async {
    await _firestore.collection('comments').add(comment.toMap());
    await _firestore.collection('posts').doc(comment.postId).update({
      'commentCount': FieldValue.increment(1),
    });

    if (comment.authorId != postAuthorId) {
      await _firestore
          .collection('notifications')
          .add(
            NotificationModel(
              id: '',
              userId: postAuthorId,
              senderId: comment.authorId,
              senderName: comment.authorName,
              type: NotificationType.comment,
              content: '${comment.authorName} commented on your post',
              relatedId: comment.postId,
            ).toMap(),
          );
    }
  }

  Future<List<PostModel>> getUserPosts(String userId) async {
    final snapshot = await _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }

  Future<List<PostModel>> searchPosts(String query) async {
    final snapshot = await _firestore.collection('posts').get();
    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .where(
          (post) =>
              post.content.toLowerCase().contains(lowerQuery) ||
              (post.cropType?.toLowerCase().contains(lowerQuery) ?? false) ||
              post.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)),
        )
        .toList();
  }
}
