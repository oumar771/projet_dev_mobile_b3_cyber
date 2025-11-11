// lib/repositories/auth_repository.dart

import 'package:dio/dio.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// Repository pour gérer toutes les opérations d'authentification
class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  /// Connexion avec username et password
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('🔐 AuthRepository: Tentative de connexion');
      print('👤 Username: $username');
      
      final response = await _apiService.login(username, password);
      
      print('✅ AuthRepository: Réponse reçue');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 Data: ${response.data}');
      
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Réponse invalide du serveur');
      }
    } on DioException catch (e) {
      print('❌ AuthRepository DioException');
      print('❌ Type: ${e.type}');
      print('❌ Message: ${e.message}');
      print('❌ Response Data: ${e.response?.data}');
      print('❌ Response Status: ${e.response?.statusCode}');
      
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Le serveur met trop de temps à répondre. Vérifiez qu\'il est démarré sur le port 8080.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Impossible de se connecter au serveur. Vérifiez que:\n1. Le serveur tourne sur http://172.20.10.3:8080\n2. Votre téléphone est sur le même réseau WiFi\n3. Le firewall autorise la connexion');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Identifiants incorrects');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Route non trouvée. L\'URL /api/auth/signin existe-t-elle ?');
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      } else {
        throw Exception('Erreur réseau: ${e.message}');
      }
    } catch (e) {
      print('❌ AuthRepository Exception générale: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Inscription avec username, email et password
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      print('📝 AuthRepository: Tentative d\'inscription');
      print('👤 Username: $username');
      print('📧 Email: $email');
      
      final response = await _apiService.dio.post(
        '/api/auth/signup',
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );
      
      print('✅ AuthRepository: Inscription réussie');
      print('📦 Data: ${response.data}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Réponse invalide du serveur');
      }
    } on DioException catch (e) {
      print('❌ AuthRepository DioException lors de l\'inscription');
      print('❌ Type: ${e.type}');
      print('❌ Message: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Délai de connexion dépassé');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Impossible de se connecter au serveur');
      } else if (e.response?.statusCode == 409 || e.response?.statusCode == 400) {
        final errorMsg = e.response?.data['message'] ?? 'Cet email ou username existe déjà';
        throw Exception(errorMsg);
      } else if (e.response?.data != null && e.response?.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      } else {
        throw Exception('Erreur réseau: ${e.message}');
      }
    } catch (e) {
      print('❌ AuthRepository Exception: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  /// Récupérer les informations de l'utilisateur actuel
  /// IMPORTANT: Cette méthode crée un User à partir de la réponse de login
  /// car votre backend vélo ne semble pas avoir de route /api/auth/me
  Future<User> getCurrentUser() async {
    try {
      print('👤 AuthRepository: Récupération de l\'utilisateur actuel');
      
      // OPTION 1: Si votre backend a une route pour récupérer l'utilisateur
      try {
        final response = await _apiService.getAuth<Map<String, dynamic>>(
          '/api/auth/me',
          queryParameters: {},
        );
        
        if (response.statusCode == 200 && response.data != null) {
          print('✅ Utilisateur récupéré depuis /api/auth/me');
          return User.fromJson(response.data!);
        }
      } catch (e) {
        print('⚠️ Route /api/auth/me non disponible, utilisation des données de login');
      }
      
      // OPTION 2: Si pas de route /api/auth/me, on crée un User basique
      // Vous devrez sauvegarder les infos lors du login
      throw Exception('Impossible de récupérer l\'utilisateur. La route /api/auth/me n\'existe pas dans votre backend.');
      
    } on DioException catch (e) {
      print('❌ AuthRepository DioException: ${e.type}');
      print('❌ Message: ${e.message}');
      
      if (e.response?.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Route /api/auth/me non trouvée. Cette route n\'existe pas dans votre backend.');
      } else {
        throw Exception('Erreur: ${e.message}');
      }
    } catch (e) {
      print('❌ AuthRepository Exception: $e');
      rethrow;
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<User> updateProfile({
    String? username,
    String? email,
    double? currentLat,
    double? currentLon,
    bool? isVisibleOnMap,
  }) async {
    try {
      print('✏️ AuthRepository: Mise à jour du profil');
      
      final data = <String, dynamic>{};
      if (username != null) data['username'] = username;
      if (email != null) data['email'] = email;
      if (currentLat != null) data['currentLat'] = currentLat;
      if (currentLon != null) data['currentLon'] = currentLon;
      if (isVisibleOnMap != null) data['isVisibleOnMap'] = isVisibleOnMap;
      
      final response = await _apiService.putAuth<Map<String, dynamic>>(
        '/api/user/profile',
        data: data,
      );
      
      print('✅ AuthRepository: Profil mis à jour');
      
      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data!);
      } else {
        throw Exception('Échec de la mise à jour du profil');
      }
    } on DioException catch (e) {
      print('❌ AuthRepository DioException: ${e.message}');
      throw Exception('Erreur lors de la mise à jour: ${e.message}');
    }
  }

  /// Vérifier si le token est valide
  Future<bool> verifyToken() async {
    try {
      final response = await _apiService.getAuth<Map<String, dynamic>>(
        '/api/auth/verify',
        queryParameters: {},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}