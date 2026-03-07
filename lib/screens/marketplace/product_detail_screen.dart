import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/product_model.dart';
import 'package:soilsocial/services/product_service.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _productService = ProductService();
  ProductModel? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      _product = await _productService.getProduct(widget.productId);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _productService.deleteProduct(widget.productId);
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.name ?? 'Product'),
        actions: [
          if (_product != null && _product!.sellerId == currentUserId)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteProduct,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
          ? const Center(child: Text('Product not found'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image gallery
                  if (_product!.images.isNotEmpty)
                    SizedBox(
                      height: 300,
                      child: PageView.builder(
                        itemCount: _product!.images.length,
                        itemBuilder: (context, index) => Image.network(
                          _product!.images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image, size: 64, color: Colors.grey),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                _product!.category == ProductCategory.food
                                    ? 'Food & Produce'
                                    : 'Equipment',
                              ),
                              backgroundColor: AppTheme.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(_product!.status.name.toUpperCase()),
                              backgroundColor: _product!.isAvailable
                                  ? Colors.green[50]
                                  : Colors.red[50],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _product!.name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _product!.formattedPrice,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        Text(
                          '${_product!.quantity} ${_product!.unit}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_product!.description),
                        if (_product!.condition != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Condition: ${_product!.condition!.name}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(_product!.location),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Listed ${timeago.format(_product!.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const Divider(height: 32),
                        // Seller info
                        const Text(
                          'Seller',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage:
                                _product!.sellerProfilePicture != null
                                ? NetworkImage(_product!.sellerProfilePicture!)
                                : null,
                            child: _product!.sellerProfilePicture == null
                                ? Text(
                                    _product!.sellerName.isNotEmpty
                                        ? _product!.sellerName[0].toUpperCase()
                                        : '?',
                                  )
                                : null,
                          ),
                          title: Text(_product!.sellerName),
                          trailing: _product!.sellerId != currentUserId
                              ? OutlinedButton(
                                  onPressed: () => context.push(
                                    '/messages/${_product!.sellerId}',
                                    extra: {'name': _product!.sellerName},
                                  ),
                                  child: const Text('Contact Seller'),
                                )
                              : null,
                          onTap: () =>
                              context.push('/profile/${_product!.sellerId}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
