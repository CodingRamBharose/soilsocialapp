import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soilsocial/providers/auth_provider.dart';
import 'package:soilsocial/services/weather_service.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String? _location;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final user = context.read<AuthProvider>().userModel;
    _location = user?.location ?? 'Punjab';
    setState(() => _isLoading = true);
    try {
      _weatherData = await _weatherService.getWeather(_location!);
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
      onRefresh: _loadWeather,
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
