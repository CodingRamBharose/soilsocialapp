import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soilsocial/models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ProductModel>> getProducts({
    ProductCategory? category,
    String? search,
    int limit = 20,
    DocumentSnapshot? lastDoc,
  }) async {
    Query query = _firestore.collection('products');

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }
    query = query.limit(limit);

    final snapshot = await query.get();
    var products = snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .toList();

    // Sort client-side to avoid composite index requirement
    products.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (search != null && search.isNotEmpty) {
      final lowerSearch = search.toLowerCase();
      products = products
          .where(
            (p) =>
                p.name.toLowerCase().contains(lowerSearch) ||
                p.description.toLowerCase().contains(lowerSearch),
          )
          .toList();
    }

    return products;
  }

  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (!doc.exists) return null;
    return ProductModel.fromFirestore(doc);
  }

  Future<String> createProduct(ProductModel product) async {
    final docRef = await _firestore.collection('products').add(product.toMap());
    return docRef.id;
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _firestore.collection('products').doc(productId).update(data);
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final snapshot = await _firestore.collection('products').get();
    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .where(
          (product) =>
              product.name.toLowerCase().contains(lowerQuery) ||
              product.description.toLowerCase().contains(lowerQuery) ||
              product.location.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }
}
