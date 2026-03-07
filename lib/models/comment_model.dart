import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorProfilePicture;
  final String postId;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorProfilePicture,
    required this.postId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorProfilePicture: data['authorProfilePicture'],
      postId: data['postId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfilePicture': authorProfilePicture,
      'postId': postId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
