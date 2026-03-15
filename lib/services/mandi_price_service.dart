import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soilsocial/models/mandi_price_model.dart';

class MandiPriceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MandiPriceModel>> getLatestPrices() async {
    final snapshot = await _firestore
        .collection('mandiPrices')
        .limit(20)
        .get();
    final prices = snapshot.docs
        .map((doc) => MandiPriceModel.fromFirestore(doc))
        .toList();
    prices.sort((a, b) => b.date.compareTo(a.date));
    return prices;
  }

  Future<List<MandiPriceModel>> getPricesByCrop(String cropName) async {
    final snapshot = await _firestore
        .collection('mandiPrices')
        .where('cropName', isEqualTo: cropName)
        .limit(20)
        .get();
    final prices = snapshot.docs
        .map((doc) => MandiPriceModel.fromFirestore(doc))
        .toList();
    prices.sort((a, b) => b.date.compareTo(a.date));
    return prices;
  }
}
