import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductCategory { food, equipment }

enum ProductCondition { newItem, likeNew, good, fair, poor }

enum ProductStatus { available, sold, reserved }

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final ProductCategory category;
  final List<String> images;
  final String sellerId;
  final String sellerName;
  final String? sellerProfilePicture;
  final String location;
  final ProductCondition? condition;
  final int quantity;
  final String unit;
  final ProductStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.images = const [],
    required this.sellerId,
    required this.sellerName,
    this.sellerProfilePicture,
    required this.location,
    this.condition,
    this.quantity = 1,
    this.unit = 'piece',
    this.status = ProductStatus.available,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';

  bool get isAvailable => status == ProductStatus.available;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: ProductCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ProductCategory.food,
      ),
      images: List<String>.from(data['images'] ?? []),
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      sellerProfilePicture: data['sellerProfilePicture'],
      location: data['location'] ?? '',
      condition: data['condition'] != null
          ? ProductCondition.values.firstWhere(
              (e) => e.name == data['condition'],
              orElse: () => ProductCondition.good,
            )
          : null,
      quantity: data['quantity'] ?? 1,
      unit: data['unit'] ?? 'piece',
      status: ProductStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ProductStatus.available,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category.name,
      'images': images,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerProfilePicture': sellerProfilePicture,
      'location': location,
      'condition': condition?.name,
      'quantity': quantity,
      'unit': unit,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  static const List<String> unitOptions = [
    'kg',
    'quintal',
    'ton',
    'piece',
    'dozen',
    'bunch',
    'L',
    'kL',
    'bag',
    'sack',
  ];
}
