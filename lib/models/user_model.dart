import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final bool isVerified;
  final String? profilePicture;
  final String? location;
  final String? bio;
  final List<String> cropsGrown;
  final List<String> farmingTechniques;
  final List<String> connections;
  final List<String> connectionRequestsSent;
  final List<String> connectionRequestsReceived;
  final List<String> groups;
  final List<String> savedPosts;
  final List<String> eventsAttending;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.isVerified = false,
    this.profilePicture,
    this.location,
    this.bio,
    this.cropsGrown = const [],
    this.farmingTechniques = const [],
    this.connections = const [],
    this.connectionRequestsSent = const [],
    this.connectionRequestsReceived = const [],
    this.groups = const [],
    this.savedPosts = const [],
    this.eventsAttending = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      isVerified: data['isVerified'] ?? false,
      profilePicture: data['profilePicture'],
      location: data['location'],
      bio: data['bio'],
      cropsGrown: List<String>.from(data['cropsGrown'] ?? []),
      farmingTechniques: List<String>.from(data['farmingTechniques'] ?? []),
      connections: List<String>.from(data['connections'] ?? []),
      connectionRequestsSent: List<String>.from(
        data['connectionRequestsSent'] ?? [],
      ),
      connectionRequestsReceived: List<String>.from(
        data['connectionRequestsReceived'] ?? [],
      ),
      groups: List<String>.from(data['groups'] ?? []),
      savedPosts: List<String>.from(data['savedPosts'] ?? []),
      eventsAttending: List<String>.from(data['eventsAttending'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'isVerified': isVerified,
      'profilePicture': profilePicture,
      'location': location,
      'bio': bio,
      'cropsGrown': cropsGrown,
      'farmingTechniques': farmingTechniques,
      'connections': connections,
      'connectionRequestsSent': connectionRequestsSent,
      'connectionRequestsReceived': connectionRequestsReceived,
      'groups': groups,
      'savedPosts': savedPosts,
      'eventsAttending': eventsAttending,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    bool? isVerified,
    String? profilePicture,
    String? location,
    String? bio,
    List<String>? cropsGrown,
    List<String>? farmingTechniques,
    List<String>? connections,
    List<String>? connectionRequestsSent,
    List<String>? connectionRequestsReceived,
    List<String>? groups,
    List<String>? savedPosts,
    List<String>? eventsAttending,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      isVerified: isVerified ?? this.isVerified,
      profilePicture: profilePicture ?? this.profilePicture,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      cropsGrown: cropsGrown ?? this.cropsGrown,
      farmingTechniques: farmingTechniques ?? this.farmingTechniques,
      connections: connections ?? this.connections,
      connectionRequestsSent:
          connectionRequestsSent ?? this.connectionRequestsSent,
      connectionRequestsReceived:
          connectionRequestsReceived ?? this.connectionRequestsReceived,
      groups: groups ?? this.groups,
      savedPosts: savedPosts ?? this.savedPosts,
      eventsAttending: eventsAttending ?? this.eventsAttending,
      createdAt: createdAt,
    );
  }
}
