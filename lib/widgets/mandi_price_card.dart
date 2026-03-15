import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soilsocial/models/mandi_price_model.dart';
import 'package:soilsocial/config/theme.dart';

class MandiPriceCard extends StatelessWidget {
  final MandiPriceModel price;

  const MandiPriceCard({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    final isUp = price.isUp;
    final change = price.priceChange;

    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.grass, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  price.cropName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${price.minPrice.toStringAsFixed(0)} - ₹${price.maxPrice.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          Text(
            '/${price.unit}',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          if (change != null && isUp != null)
            Row(
              children: [
                Icon(
                  isUp ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isUp ? AppTheme.primaryGreen : AppTheme.errorRed,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isUp ? '+' : ''}₹${change.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isUp ? AppTheme.primaryGreen : AppTheme.errorRed,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.store,
                size: 12,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  price.market,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            DateFormat('MMM d').format(price.date),
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
