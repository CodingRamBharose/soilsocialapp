import 'package:flutter/material.dart';
import 'package:soilsocial/services/weather_service.dart';
import 'package:soilsocial/config/theme.dart';

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
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.wb_sunny, size: 40, color: AppTheme.primaryGreen),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.location,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(condition, style: TextStyle(color: Colors.grey[600])),
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
                  ),
                ),
                Text(
                  'Humidity: $humidity% · Wind: ${windSpeed}m/s',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
