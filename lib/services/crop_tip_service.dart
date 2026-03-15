import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soilsocial/models/crop_tip_model.dart';

class CropTipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<CropTipModel>> getLatestTips({int limit = 10}) async {
    final snapshot = await _firestore
        .collection('cropTips')
        .limit(limit)
        .get();
    final tips = snapshot.docs
        .map((doc) => CropTipModel.fromFirestore(doc))
        .toList();
    tips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tips;
  }

  Future<List<CropTipModel>> getTipsByCrop(String cropType) async {
    final snapshot = await _firestore
        .collection('cropTips')
        .where('cropType', isEqualTo: cropType)
        .limit(20)
        .get();
    final tips = snapshot.docs
        .map((doc) => CropTipModel.fromFirestore(doc))
        .toList();
    tips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tips;
  }
}
