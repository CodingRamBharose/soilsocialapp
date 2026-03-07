import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soilsocial/models/crop_group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CropGroupModel>> getAllGroups() async {
    final snapshot = await _firestore
        .collection('groups')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => CropGroupModel.fromFirestore(doc))
        .toList();
  }

  Future<List<CropGroupModel>> getUserGroups(String userId) async {
    final allGroups = await getAllGroups();
    return allGroups
        .where((group) => group.members.any((m) => m.userId == userId))
        .toList();
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
}
