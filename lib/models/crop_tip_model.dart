import 'package:cloud_firestore/cloud_firestore.dart';

class CropTipModel {
  final String id;
  final String title;
  final String content;
  final String cropType;
  final String season;
  final String? imageUrl;
  final DateTime createdAt;

  CropTipModel({
    required this.id,
    required this.title,
    required this.content,
    required this.cropType,
    this.season = '',
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CropTipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CropTipModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      cropType: data['cropType'] ?? '',
      season: data['season'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'cropType': cropType,
      'season': season,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
