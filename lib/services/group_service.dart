import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soilsocial/models/crop_group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CropGroupModel>> getAllGroups() async {
    final snapshot = await _firestore.collection('groups').get();
    final groups = snapshot.docs
        .map((doc) => CropGroupModel.fromFirestore(doc))
        .toList();
    groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return groups;
  }

  Future<List<CropGroupModel>> getUserGroups(String userId) async {
    // Fetch user doc to get group IDs
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final groupIds = List<String>.from(userDoc.data()?['groups'] ?? []);
    if (groupIds.isEmpty) return [];

    // Firestore whereIn supports max 30 items per query
    final List<CropGroupModel> groups = [];
    for (var i = 0; i < groupIds.length; i += 30) {
      final batch = groupIds.sublist(
        i,
        i + 30 > groupIds.length ? groupIds.length : i + 30,
      );
      final snapshot = await _firestore
          .collection('groups')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      groups.addAll(
        snapshot.docs.map((doc) => CropGroupModel.fromFirestore(doc)),
      );
    }
    groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return groups;
  }

  Future<String> createGroup({
    required String name,
    required String description,
    required String cropType,
    required String userId,
  }) async {
    final group = CropGroupModel(
      id: '',
      name: name,
      description: description,
      cropType: cropType,
      createdBy: userId,
      members: [GroupMember(userId: userId, role: 'admin')],
    );
    final docRef = await _firestore.collection('groups').add(group.toMap());

    await _firestore.collection('users').doc(userId).update({
      'groups': FieldValue.arrayUnion([docRef.id]),
    });

    return docRef.id;
  }

  Future<void> joinGroup(String groupId, String userId) async {
    final member = GroupMember(userId: userId, role: 'member');
    await _firestore.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([member.toMap()]),
    });
    await _firestore.collection('users').doc(userId).update({
      'groups': FieldValue.arrayUnion([groupId]),
    });
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    // Get current group doc to find the member entry to remove
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    final members = (groupDoc.data()?['members'] as List<dynamic>?) ?? [];
    final memberEntry = members.firstWhere(
      (m) => (m as Map<String, dynamic>)['userId'] == userId,
      orElse: () => null,
    );
    if (memberEntry != null) {
      await _firestore.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayRemove([memberEntry]),
      });
    }
    await _firestore.collection('users').doc(userId).update({
      'groups': FieldValue.arrayRemove([groupId]),
    });
  }
}
