import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // Users should replace this with their own OpenWeather API key
  static const String _apiKey = 'c993a83d8c72db1c5fe86abc5bc341a1';
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>?> getWeather(String location) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?q=${Uri.encodeComponent(location)}&appid=$_apiKey&units=metric',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
