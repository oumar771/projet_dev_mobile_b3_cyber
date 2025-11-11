import '../models/route.dart';
import '../services/api_service.dart';

// Repository pour gérer les routes cyclables
class RouteRepository {
  final ApiService _apiService;

  RouteRepository(this._apiService);

  // Récupérer toutes les routes publiques
  Future<List<BikeRoute>> getAllRoutes() async {
    try {
      final response = await _apiService.getAuth<List<dynamic>>('/api/routes');
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => BikeRoute.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les routes de l'utilisateur connecté
  Future<List<BikeRoute>> getMyRoutes() async {
    try {
      final response = await _apiService.getAuth<List<dynamic>>('/api/routes/myroutes');
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => BikeRoute.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer une route par son ID
  Future<BikeRoute> getRouteById(int routeId) async {
    try {
      final response = await _apiService.getAuth<Map<String, dynamic>>('/api/routes/$routeId');
      return BikeRoute.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  // Créer une nouvelle route
  Future<BikeRoute> createRoute({
    required String name,
    required String description,
    required List<Map<String, double>> waypoints,
    bool isPublic = true,
  }) async {
    try {
      final response = await _apiService.postAuth<Map<String, dynamic>>(
        '/api/routes',
        data: {
          'name': name,
          'description': description,
          'waypoints': waypoints,
          'isPublic': isPublic,
        },
      );
      return BikeRoute.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour une route
  Future<BikeRoute> updateRoute({
    required int routeId,
    String? name,
    String? description,
    List<Map<String, double>>? waypoints,
    bool? isPublic,
  }) async {
    try {
      final response = await _apiService.putAuth<Map<String, dynamic>>(
        '/api/routes/$routeId',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (waypoints != null) 'waypoints': waypoints,
          if (isPublic != null) 'isPublic': isPublic,
        },
      );
      return BikeRoute.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer une route
  Future<void> deleteRoute(int routeId) async {
    try {
      await _apiService.deleteAuth('/api/routes/$routeId');
    } catch (e) {
      rethrow;
    }
  }

  // --- SECTION DES FAVORIS ---

  // Récupérer les routes favorites
  Future<List<BikeRoute>> getFavoriteRoutes() async {
    try {
      final response = await _apiService.getAuth<List<dynamic>>('/api/routes/favorites');
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => BikeRoute.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Ajouter une route aux favoris
  Future<void> addToFavorites(int routeId) async {
    try {
      await _apiService.postAuth('/api/routes/$routeId/favorite', data: {});
    } catch (e) {
      rethrow;
    }
  }

  // Retirer une route des favoris
  Future<void> removeFromFavorites(int routeId) async {
    try {
      await _apiService.deleteAuth('/api/routes/$routeId/favorite');
    } catch (e) {
      rethrow;
    }
  }
}