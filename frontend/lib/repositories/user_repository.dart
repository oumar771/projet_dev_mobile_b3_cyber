import '../models/user.dart';
import '../services/api_service.dart';

// Repository pour g�rer les utilisateurs
class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  // R�cup�rer tous les utilisateurs visibles sur la carte
  Future<List<User>> getVisibleUsers() async {
    try {
      final response = await _apiService.getAuth<List<dynamic>>('/api/users/visible');
      final List<dynamic> data = response.data ?? [];
      return data.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // R�cup�rer un utilisateur par son ID
  Future<User> getUserById(int userId) async {
    try {
      final response = await _apiService.getAuth<Map<String, dynamic>>('/api/users/$userId');
      return User.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }

  // Mettre � jour la position de l'utilisateur
  Future<void> updateLocation(double lat, double lon) async {
    try {
      await _apiService.postAuth('/api/users/location', data: {
        'currentLat': lat,
        'currentLon': lon,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Mettre � jour la visibilit� sur la carte
  Future<void> updateMapVisibility(bool isVisible) async {
    try {
      await _apiService.postAuth('/api/users/visibility', data: {
        'isVisibleOnMap': isVisible,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Mettre � jour le profil
  Future<User> updateProfile({
    String? username,
    String? email,
  }) async {
    try {
      final response = await _apiService.postAuth<Map<String, dynamic>>(
        '/api/users/profile',
        data: {
          if (username != null) 'username': username,
          if (email != null) 'email': email,
        },
      );
      return User.fromJson(response.data!);
    } catch (e) {
      rethrow;
    }
  }
}
