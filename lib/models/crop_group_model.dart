import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMember {
  final String userId;
  final String role;
  final DateTime joinedAt;

  GroupMember({required this.userId, this.role = 'member', DateTime? joinedAt})
    : joinedAt = joinedAt ?? DateTime.now();

  factory GroupMember.fromMap(Map<String, dynamic> data) {
    return GroupMember(
      userId: data['userId'] ?? '',
      role: data['role'] ?? 'member',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

class CropGroupModel {
  final String id;
  final String name;
  final String description;
  final String cropType;
  final String createdBy;
  final List<GroupMember> members;
  final DateTime createdAt;
  final DateTime updatedAt;

  CropGroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.cropType,
    required this.createdBy,
    this.members = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory CropGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CropGroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      cropType: data['cropType'] ?? '',
      createdBy: data['createdBy'] ?? '',
      members:
          (data['members'] as List<dynamic>?)
              ?.map((m) => GroupMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'cropType': cropType,
      'createdBy': createdBy,
      'members': members.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }
}
