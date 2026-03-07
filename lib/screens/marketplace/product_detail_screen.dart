import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/models/product_model.dart';
import 'package:soilsocial/services/product_service.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.translate('deleteProduct')),
        content: Text(l.translate('deleteProductConfirm')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l.translate('cancel'),
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
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
    final l = AppLocalizations.of(context);
    final currentUserId = context.read<AuthProvider>().firebaseUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.name ?? l.translate('marketplace')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.dividerColor, height: 1),
        ),
        actions: [
          if (_product != null && _product!.sellerId == currentUserId)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteProduct,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : _product == null
          ? Center(
              child: Text(
                l.translate('productNotFound'),
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            )
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
                      color: AppTheme.background,
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  // Category & Status pills
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            _product!.category == ProductCategory.food
                                ? l.translate('foodAndProduce')
                                : l.translate('equipment'),
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _product!.isAvailable
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            _product!.status.name.toUpperCase(),
                            style: TextStyle(
                              color: _product!.isAvailable
                                  ? AppTheme.primaryGreen
                                  : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Name & Price
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _product!.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _product!.formattedPrice,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        Text(
                          '${_product!.quantity} ${_product!.unit}',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Description section
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.translate('description'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _product!.description,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (_product!.condition != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                '${l.translate('condition')}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  _product!.condition!.name,
                                  style: const TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Location & time
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _product!.location,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.translateWithArgs('listedAgo', {
                            'time': timeago.format(_product!.createdAt),
                          }),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Seller info
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.translate('seller'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage:
                                  _product!.sellerProfilePicture != null
                                  ? NetworkImage(
                                      _product!.sellerProfilePicture!,
                                    )
                                  : null,
                              backgroundColor: AppTheme.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              child: _product!.sellerProfilePicture == null
                                  ? Text(
                                      _product!.sellerName.isNotEmpty
                                          ? _product!.sellerName[0]
                                                .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push(
                                  '/profile/${_product!.sellerId}',
                                ),
                                child: Text(
                                  _product!.sellerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            if (_product!.sellerId != currentUserId)
                              FilledButton(
                                onPressed: () => context.push(
                                  '/messages/${_product!.sellerId}',
                                  extra: {'name': _product!.sellerName},
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: Text(l.translate('contactSeller')),
                              ),
                          ],
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
