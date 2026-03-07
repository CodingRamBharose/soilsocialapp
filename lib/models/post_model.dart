import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String content;
  final List<String> images;
  final List<String> videos;
  final String authorId;
  final String authorName;
  final String? authorProfilePicture;
  final List<String> likes;
  final int commentCount;
  final int shares;
  final String? cropType;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostModel({
    required this.id,
    required this.content,
    this.images = const [],
    this.videos = const [],
    required this.authorId,
    required this.authorName,
    this.authorProfilePicture,
    this.likes = const [],
    this.commentCount = 0,
    this.shares = 0,
    this.cropType,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      content: data['content'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      videos: List<String>.from(data['videos'] ?? []),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorProfilePicture: data['authorProfilePicture'],
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      shares: data['shares'] ?? 0,
      cropType: data['cropType'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'images': images,
      'videos': videos,
      'authorId': authorId,
      'authorName': authorName,
      'authorProfilePicture': authorProfilePicture,
      'likes': likes,
      'commentCount': commentCount,
      'shares': shares,
      'cropType': cropType,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }
}
