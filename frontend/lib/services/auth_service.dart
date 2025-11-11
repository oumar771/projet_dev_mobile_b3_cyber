import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// Service d'authentification avec double stockage :
/// - Token dans FlutterSecureStorage (sécurisé)
/// - User dans SharedPreferences (simple et fiable)
class AuthService {
  final _storage = const FlutterSecureStorage();

  // Clés de stockage
  static const _tokenKey = 'user_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'user_username';
  static const _emailKey = 'user_email';
  static const _rolesKey = 'user_roles';
  static const _isVisibleOnMapKey = 'user_is_visible_on_map';
  static const _currentLatKey = 'user_current_lat';
  static const _currentLonKey = 'user_current_lon';
  static const _showPerformancesKey = 'user_show_performances';

  /// Sauvegarde la session complète (token + user)
  Future<void> saveSession(String token, User user) async {
    print('═══════════════════════════════════════════════════');
    print('AuthService: 🔐 DÉBUT SAUVEGARDE SESSION');
    print('AuthService: Username = ${user.username}');
    print('AuthService: Email = ${user.email}');
    print('AuthService: ID = ${user.id}');

    try {
      // 1. Sauvegarder le token dans FlutterSecureStorage
      await _storage.write(key: _tokenKey, value: token);
      print('AuthService: ✅ Token sauvegardé dans FlutterSecureStorage');

      // 2. Sauvegarder l'utilisateur dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(_userIdKey, user.id);
      await prefs.setString(_usernameKey, user.username);
      await prefs.setString(_emailKey, user.email);

      // Sauvegarder les rôles (liste de strings)
      if (user.roles != null && user.roles!.isNotEmpty) {
        await prefs.setStringList(_rolesKey, user.roles!);
      } else {
        await prefs.remove(_rolesKey);
      }

      await prefs.setBool(_isVisibleOnMapKey, user.isVisibleOnMap);
      await prefs.setBool(_showPerformancesKey, user.showPerformances);

      // Sauvegarder les coordonnées (peuvent être null)
      if (user.currentLat != null) {
        await prefs.setDouble(_currentLatKey, user.currentLat!);
      } else {
        await prefs.remove(_currentLatKey);
      }

      if (user.currentLon != null) {
        await prefs.setDouble(_currentLonKey, user.currentLon!);
      } else {
        await prefs.remove(_currentLonKey);
      }

      print('AuthService: ✅ Utilisateur sauvegardé dans SharedPreferences');

      // Vérification : relire immédiatement pour confirmer
      final savedUsername = prefs.getString(_usernameKey);
      final savedId = prefs.getInt(_userIdKey);
      print('AuthService: 🔍 VÉRIFICATION: username=$savedUsername, id=$savedId');

      print('AuthService: ✅ SESSION SAUVEGARDÉE AVEC SUCCÈS');
      print('═══════════════════════════════════════════════════');
    } catch (e) {
      print('AuthService: ❌ ERREUR lors de la sauvegarde: $e');
      print('═══════════════════════════════════════════════════');
      rethrow;
    }
  }

  /// Charge l'utilisateur depuis SharedPreferences
  Future<User?> loadUserFromStorage() async {
    print('═══════════════════════════════════════════════════');
    print('AuthService: 🔍 DÉBUT CHARGEMENT UTILISATEUR');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Vérifier si les données essentielles existent
      final id = prefs.getInt(_userIdKey);
      final username = prefs.getString(_usernameKey);
      final email = prefs.getString(_emailKey);

      print('AuthService: ID trouvé = $id');
      print('AuthService: Username trouvé = $username');
      print('AuthService: Email trouvé = $email');

      if (id == null || username == null || email == null) {
        print('AuthService: ❌ Données utilisateur incomplètes ou absentes');
        print('═══════════════════════════════════════════════════');
        return null;
      }

      // Charger toutes les données
      final roles = prefs.getStringList(_rolesKey);
      final isVisibleOnMap = prefs.getBool(_isVisibleOnMapKey) ?? false;
      final showPerformances = prefs.getBool(_showPerformancesKey) ?? true;
      final currentLat = prefs.getDouble(_currentLatKey);
      final currentLon = prefs.getDouble(_currentLonKey);

      final user = User(
        id: id,
        username: username,
        email: email,
        roles: roles,
        isVisibleOnMap: isVisibleOnMap,
        showPerformances: showPerformances,
        currentLat: currentLat,
        currentLon: currentLon,
      );

      print('AuthService: ✅ UTILISATEUR CHARGÉ AVEC SUCCÈS');
      print('AuthService: User = ${user.username} (${user.email})');
      print('═══════════════════════════════════════════════════');

      return user;
    } catch (e) {
      print('AuthService: ❌ ERREUR lors du chargement: $e');
      print('═══════════════════════════════════════════════════');
      return null;
    }
  }

  /// Supprime toute la session (token + user)
  Future<void> deleteSession() async {
    print('AuthService: 🗑️ Suppression de la session');

    try {
      // Supprimer le token
      await _storage.delete(key: _tokenKey);

      // Supprimer l'utilisateur de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_rolesKey);
      await prefs.remove(_isVisibleOnMapKey);
      await prefs.remove(_currentLatKey);
      await prefs.remove(_currentLonKey);
      await prefs.remove(_showPerformancesKey);

      print('AuthService: ✅ Session supprimée avec succès');
    } catch (e) {
      print('AuthService: ❌ Erreur lors de la suppression: $e');
    }
  }

  /// Vérifie si un token existe
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Récupère le token (pour ApiService)
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
}
