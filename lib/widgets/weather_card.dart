import 'package:flutter/material.dart';
import 'package:soilsocial/services/weather_service.dart';
import 'package:soilsocial/config/theme.dart';
import 'package:soilsocial/l10n/app_localizations.dart';

class WeatherCard extends StatefulWidget {
  final String location;
  const WeatherCard({super.key, required this.location});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final data = await _weatherService.getWeather(widget.location);
    if (mounted) {
      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.cardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_weatherData == null) {
      return const SizedBox.shrink();
    }

    final main = _weatherData!['main'] as Map<String, dynamic>?;
    final weather =
        (_weatherData!['weather'] as List?)?.firstOrNull
            as Map<String, dynamic>?;
    final wind = _weatherData!['wind'] as Map<String, dynamic>?;

    final temp = main?['temp']?.toStringAsFixed(0) ?? '--';
    final humidity = main?['humidity']?.toString() ?? '--';
    final condition = weather?['main'] ?? 'Unknown';
    final windSpeed = wind?['speed']?.toStringAsFixed(1) ?? '--';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny, size: 40, color: AppTheme.primaryGreen),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.location,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  condition,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$temp°C',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
              Text(
                '${l.translate('humidity')}: $humidity% · ${l.translate('wind')}: ${windSpeed}m/s',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
