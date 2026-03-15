import 'package:cloud_firestore/cloud_firestore.dart';

class MandiPriceModel {
  final String id;
  final String cropName;
  final String market;
  final double minPrice;
  final double maxPrice;
  final String unit;
  final DateTime date;
  final double? previousPrice;

  MandiPriceModel({
    required this.id,
    required this.cropName,
    required this.market,
    required this.minPrice,
    required this.maxPrice,
    this.unit = 'quintal',
    DateTime? date,
    this.previousPrice,
  }) : date = date ?? DateTime.now();

  factory MandiPriceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MandiPriceModel(
      id: doc.id,
      cropName: data['cropName'] ?? '',
      market: data['market'] ?? '',
      minPrice: (data['minPrice'] ?? 0).toDouble(),
      maxPrice: (data['maxPrice'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'quintal',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      previousPrice: (data['previousPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropName': cropName,
      'market': market,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'unit': unit,
      'date': Timestamp.fromDate(date),
      'previousPrice': previousPrice,
    };
  }

  double get avgPrice => (minPrice + maxPrice) / 2;

  double? get priceChange {
    if (previousPrice == null || previousPrice == 0) return null;
    return avgPrice - previousPrice!;
  }

  bool? get isUp {
    final change = priceChange;
    if (change == null) return null;
    return change > 0;
  }
}
