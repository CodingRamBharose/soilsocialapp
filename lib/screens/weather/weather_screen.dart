import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/services/weather_service.dart';
import 'package:soilsocial/services/mandi_price_service.dart';
import 'package:soilsocial/services/crop_tip_service.dart';
import 'package:soilsocial/models/mandi_price_model.dart';
import 'package:soilsocial/models/crop_tip_model.dart';
import 'package:soilsocial/widgets/mandi_price_card.dart';
import 'package:soilsocial/widgets/crop_tip_card.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  final MandiPriceService _mandiService = MandiPriceService();
  final CropTipService _tipService = CropTipService();
  Map<String, dynamic>? _weatherData;
  List<MandiPriceModel> _mandiPrices = [];
  List<CropTipModel> _cropTips = [];
  bool _isLoading = true;
  String? _location;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final user = context.read<AuthProvider>().userModel;
    _location = user?.location ?? 'Punjab';
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _weatherService.getWeather(_location!),
        _mandiService.getLatestPrices(),
        _tipService.getLatestTips(),
      ]);
      _weatherData = results[0] as Map<String, dynamic>?;
      _mandiPrices = results[1] as List<MandiPriceModel>;
      _cropTips = results[2] as List<CropTipModel>;
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }

    if (_weatherData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              l.translate('weather'),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final main = _weatherData!['main'] as Map<String, dynamic>?;
    final weather =
        (_weatherData!['weather'] as List?)?.firstOrNull
            as Map<String, dynamic>?;
    final wind = _weatherData!['wind'] as Map<String, dynamic>?;

    final temp = main?['temp']?.toStringAsFixed(0) ?? '--';
    final feelsLike = main?['feels_like']?.toStringAsFixed(0) ?? '--';
    final tempMin = main?['temp_min']?.toStringAsFixed(0) ?? '--';
    final tempMax = main?['temp_max']?.toStringAsFixed(0) ?? '--';
    final humidity = main?['humidity']?.toString() ?? '--';
    final pressure = main?['pressure']?.toString() ?? '--';
    final condition = weather?['main'] ?? 'Unknown';
    final description = weather?['description'] ?? '';
    final windSpeed = wind?['speed']?.toStringAsFixed(1) ?? '--';

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Hero weather card
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.wb_sunny, size: 64, color: AppTheme.primaryGreen),
                  const SizedBox(height: 12),
                  Text(
                    _location ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$temp°C',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Text(
                    '$condition · Feels like $feelsLike°C',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'H: $tempMax°C  L: $tempMin°C',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Detail cards
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _DetailCard(
                      icon: Icons.water_drop,
                      label: l.translate('humidity'),
                      value: '$humidity%',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DetailCard(
                      icon: Icons.air,
                      label: l.translate('wind'),
                      value: '${windSpeed}m/s',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DetailCard(
                      icon: Icons.speed,
                      label: 'Pressure',
                      value: '${pressure}hPa',
                    ),
                  ),
                ],
              ),
            ),
            // Mandi Prices section
            if (_mandiPrices.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.store, size: 20, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      l.translate('mandiPrices'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: _mandiPrices.length,
                  itemBuilder: (context, index) =>
                      MandiPriceCard(price: _mandiPrices[index]),
                ),
              ),
            ],
            // Crop Advisory section
            if (_cropTips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.eco, size: 20, color: AppTheme.primaryGreen),
                    const SizedBox(width: 8),
                    Text(
                      l.translate('cropAdvisory'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                height: 260,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: _cropTips.length,
                  itemBuilder: (context, index) =>
                      CropTipCard(tip: _cropTips[index]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
