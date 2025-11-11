import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../models/weather.dart';
import '../models/route_suggestion.dart';
import '../services/api_service.dart';

class ExternalApiRepository {
  final ApiService _apiService;
  final Dio _dio;

  ExternalApiRepository(this._apiService, this._dio);

  Future<LatLng?> geocodeAddress(String address) async {
    final url =
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1&countrycodes=fr';

    try {
      final response = await _dio.get(url, options: Options(headers: {
        'User-Agent': 'VeloAngersApp/1.0'
      }));

      if (response.statusCode == 200 && (response.data as List).isNotEmpty) {
        final data = response.data[0];
        final lat = double.parse(data['lat']);
        final lon = double.parse(data['lon']);
        return LatLng(lat, lon);
      }
      return null;
    } catch (e) {
      print("Erreur de geocodage Nominatim: $e");
      return null;
    }
  }

  Future<List<RouteSuggestion>> planRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    try {
      final startCoords = [start.longitude, start.latitude];
      final endCoords = [end.longitude, end.latitude];

      final response = await _apiService.postAuth<List<dynamic>>(
        '/api/external/plan-route',
        data: {
          'start': startCoords,
          'end': endCoords,
        },
      );

      final List<dynamic> jsonList = response.data!;

      if (jsonList.isEmpty) {
        throw Exception("Aucun itineraire n'a pu etre calcule.");
      }

      final List<RouteSuggestion> suggestions = jsonList
          .map((json) => RouteSuggestion.fromJson(json as Map<String, dynamic>))
          .toList();

      return suggestions;

    } catch (e) {
      print("Erreur planRoute: $e");
      rethrow;
    }
  }

  Future<Weather> getWeather(LatLng position) async {
    try {
      final response = await _apiService.getAuth<Map<String, dynamic>>(
        '/api/external/weather',
        queryParameters: {
          'lat': position.latitude,
          'lon': position.longitude,
        }
      );
      return Weather.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }
}
