import '../models/performance.dart';
import '../services/api_service.dart';

// Repository pour les statistiques de performance
class PerformanceRepository {
  final ApiService _apiService;

  PerformanceRepository(this._apiService);

  // R�cup�rer toutes les performances d'un utilisateur
  Future<List<Performance>> getUserPerformances() async {
    try {
      final response = await _apiService.getAuth<List<dynamic>>('/api/performance');
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => Performance.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // R�cup�rer les performances pour une route sp�cifique
  Future<List<Performance>> getRoutePerformances(int routeId) async {
    try {
      final response = await _apiService.getAuth<List<dynamic>>(
        '/api/performance/route/$routeId',
      );
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => Performance.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Enregistrer une nouvelle performance
  Future<Performance> createPerformance({
    required int routeId,
    required double distance,
    required int duration,
    required double avgSpeed,
    double? maxSpeed,
    int? calories,
  }) async {
    try {
      final response = await _apiService.postAuth<Map<String, dynamic>>(
        '/api/performance',
        data: {
          'routeId': routeId,
          'distance': distance,
          'duration': duration,
          'avgSpeed': avgSpeed,
          if (maxSpeed != null) 'maxSpeed': maxSpeed,
          if (calories != null) 'calories': calories,
        },
      );
      return Performance.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }
}
