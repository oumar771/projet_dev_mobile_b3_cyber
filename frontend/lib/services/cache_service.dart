import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import '../models/route.dart';
import '../models/user.dart';
import '../models/performance.dart';
import '../models/comment.dart';

// Constantes pour les noms des "Boîtes" Hive
const String allRoutesBoxName = 'all_routes_box';
const String myRoutesBoxName = 'my_routes_box';
const String favoriteRoutesBoxName = 'favorite_routes_box';
const String userBoxName = 'user_box';
const String performancesBoxName = 'performances_box';
const String commentsBoxName = 'comments_box';
const String cacheMetadataBoxName = 'cache_metadata_box';

// Durées d'expiration du cache
const Duration routesCacheExpiration = Duration(hours: 24);
const Duration userCacheExpiration = Duration(hours: 12);
const Duration performancesCacheExpiration = Duration(hours: 6);
const Duration commentsCacheExpiration = Duration(minutes: 30);

/// Service de gestion du cache avec Hive
///
/// Gère le stockage local de toutes les données avec expiration automatique
class CacheService {

  // ========== INITIALISATION ==========

  /// Initialise le service de cache
  /// Cette méthode est fournie pour compatibilité avec CacheServiceEnhanced
  Future<void> init() async {
    // Pas d'initialisation spéciale nécessaire pour la version de base
    // Les boîtes Hive sont ouvertes au besoin
  }

  // ========== ROUTES PUBLIQUES ==========

  /// Met en cache la liste des routes publiques
  Future<void> cacheAllRoutes(List<BikeRoute> routes) async {
    final box = await Hive.openBox<String>(allRoutesBoxName);
    await box.clear();
    for (var route in routes) {
      await box.put(route.id.toString(), jsonEncode(route.toJson()));
    }
    await _updateCacheMetadata(allRoutesBoxName);
  }

  /// Charge les routes publiques depuis le cache
  Future<List<BikeRoute>> loadAllRoutesFromCache() async {
    if (!await _isCacheValid(allRoutesBoxName, routesCacheExpiration)) {
      return [];
    }

    final box = await Hive.openBox<String>(allRoutesBoxName);
    final List<BikeRoute> routes = [];
    for (var jsonString in box.values) {
      try {
        final json = jsonDecode(jsonString);
        routes.add(BikeRoute.fromJson(json));
      } catch (e) {
        print('Erreur lors du décodage de la route: $e');
      }
    }
    return routes;
  }

  // ========== MES ROUTES ==========

  /// Met en cache la liste des routes de l'utilisateur
  Future<void> cacheMyRoutes(List<BikeRoute> routes) async {
    final box = await Hive.openBox<String>(myRoutesBoxName);
    await box.clear();
    for (var route in routes) {
      await box.put(route.id.toString(), jsonEncode(route.toJson()));
    }
    await _updateCacheMetadata(myRoutesBoxName);
  }

  /// Charge les routes de l'utilisateur depuis le cache
  Future<List<BikeRoute>> loadMyRoutesFromCache() async {
    if (!await _isCacheValid(myRoutesBoxName, routesCacheExpiration)) {
      return [];
    }

    final box = await Hive.openBox<String>(myRoutesBoxName);
    final List<BikeRoute> routes = [];
    for (var jsonString in box.values) {
      try {
        final json = jsonDecode(jsonString);
        routes.add(BikeRoute.fromJson(json));
      } catch (e) {
        print('Erreur lors du décodage de la route: $e');
      }
    }
    return routes;
  }

  // ========== ROUTES FAVORITES ==========

  /// Met en cache la liste des routes favorites
  Future<void> cacheFavoriteRoutes(List<BikeRoute> routes) async {
    final box = await Hive.openBox<String>(favoriteRoutesBoxName);
    await box.clear();
    for (var route in routes) {
      await box.put(route.id.toString(), jsonEncode(route.toJson()));
    }
    await _updateCacheMetadata(favoriteRoutesBoxName);
  }

  /// Charge les routes favorites depuis le cache
  Future<List<BikeRoute>> loadFavoriteRoutesFromCache() async {
    if (!await _isCacheValid(favoriteRoutesBoxName, routesCacheExpiration)) {
      return [];
    }

    final box = await Hive.openBox<String>(favoriteRoutesBoxName);
    final List<BikeRoute> routes = [];
    for (var jsonString in box.values) {
      try {
        final json = jsonDecode(jsonString);
        routes.add(BikeRoute.fromJson(json));
      } catch (e) {
        print('Erreur lors du décodage de la route: $e');
      }
    }
    return routes;
  }

  // ========== UTILISATEUR ==========

  /// Met en cache les informations de l'utilisateur
  Future<void> cacheUser(User user) async {
    final box = await Hive.openBox<String>(userBoxName);
    await box.clear();
    await box.put('current_user', jsonEncode(user.toJson()));
    await _updateCacheMetadata(userBoxName);
  }

  /// Charge l'utilisateur depuis le cache
  Future<User?> loadUserFromCache() async {
    if (!await _isCacheValid(userBoxName, userCacheExpiration)) {
      return null;
    }

    final box = await Hive.openBox<String>(userBoxName);
    final jsonString = box.get('current_user');
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString);
      return User.fromJson(json);
    } catch (e) {
      print('Erreur lors du décodage de l\'utilisateur: $e');
      return null;
    }
  }

  // ========== PERFORMANCES ==========

  /// Met en cache les performances de l'utilisateur
  Future<void> cachePerformances(List<Performance> performances) async {
    final box = await Hive.openBox<String>(performancesBoxName);
    await box.clear();
    for (var perf in performances) {
      await box.put(perf.id.toString(), jsonEncode(perf.toJson()));
    }
    await _updateCacheMetadata(performancesBoxName);
  }

  /// Charge les performances depuis le cache
  Future<List<Performance>> loadPerformancesFromCache() async {
    if (!await _isCacheValid(performancesBoxName, performancesCacheExpiration)) {
      return [];
    }

    final box = await Hive.openBox<String>(performancesBoxName);
    final List<Performance> performances = [];
    for (var jsonString in box.values) {
      try {
        final json = jsonDecode(jsonString);
        performances.add(Performance.fromJson(json));
      } catch (e) {
        print('Erreur lors du décodage de la performance: $e');
      }
    }
    return performances;
  }

  // ========== COMMENTAIRES ==========

  /// Met en cache les commentaires d'une route
  Future<void> cacheComments(int routeId, List<Comment> comments) async {
    final box = await Hive.openBox<String>(commentsBoxName);
    final key = 'route_$routeId';

    final commentsJson = comments.map((c) => c.toJson()).toList();
    await box.put(key, jsonEncode(commentsJson));
    await _updateCacheMetadata('$commentsBoxName.$key');
  }

  /// Charge les commentaires d'une route depuis le cache
  Future<List<Comment>> loadCommentsFromCache(int routeId) async {
    final key = 'route_$routeId';
    if (!await _isCacheValid('$commentsBoxName.$key', commentsCacheExpiration)) {
      return [];
    }

    final box = await Hive.openBox<String>(commentsBoxName);
    final jsonString = box.get(key);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors du décodage des commentaires: $e');
      return [];
    }
  }

  // ========== MÉTADONNÉES DE CACHE ==========

  /// Met à jour les métadonnées de cache (timestamp)
  Future<void> _updateCacheMetadata(String boxName) async {
    final metadataBox = await Hive.openBox<String>(cacheMetadataBoxName);
    final metadata = {
      'lastUpdate': DateTime.now().toIso8601String(),
      'boxName': boxName,
    };
    await metadataBox.put(boxName, jsonEncode(metadata));
  }

  /// Vérifie si le cache est encore valide
  Future<bool> _isCacheValid(String boxName, Duration expiration) async {
    final metadataBox = await Hive.openBox<String>(cacheMetadataBoxName);
    final metadataString = metadataBox.get(boxName);

    if (metadataString == null) return false;

    try {
      final metadata = jsonDecode(metadataString);
      final lastUpdate = DateTime.parse(metadata['lastUpdate']);
      final now = DateTime.now();

      return now.difference(lastUpdate) < expiration;
    } catch (e) {
      print('Erreur lors de la vérification du cache: $e');
      return false;
    }
  }

  /// Obtient la date de dernière mise à jour d'un cache
  Future<DateTime?> getLastCacheUpdate(String boxName) async {
    final metadataBox = await Hive.openBox<String>(cacheMetadataBoxName);
    final metadataString = metadataBox.get(boxName);

    if (metadataString == null) return null;

    try {
      final metadata = jsonDecode(metadataString);
      return DateTime.parse(metadata['lastUpdate']);
    } catch (e) {
      print('Erreur lors de la récupération de la date: $e');
      return null;
    }
  }

  // ========== UTILITAIRES ==========

  /// Vérifie si des données en cache existent
  Future<bool> hasCachedData() async {
    final allRoutesBox = await Hive.openBox<String>(allRoutesBoxName);
    final myRoutesBox = await Hive.openBox<String>(myRoutesBoxName);

    return allRoutesBox.isNotEmpty || myRoutesBox.isNotEmpty;
  }

  /// Vide toutes les boîtes de cache
  Future<void> clearAll() async {
    final allRoutesBox = await Hive.openBox<String>(allRoutesBoxName);
    final myRoutesBox = await Hive.openBox<String>(myRoutesBoxName);
    final favoriteRoutesBox = await Hive.openBox<String>(favoriteRoutesBoxName);
    final userBox = await Hive.openBox<String>(userBoxName);
    final performancesBox = await Hive.openBox<String>(performancesBoxName);
    final commentsBox = await Hive.openBox<String>(commentsBoxName);
    final metadataBox = await Hive.openBox<String>(cacheMetadataBoxName);

    await allRoutesBox.clear();
    await myRoutesBox.clear();
    await favoriteRoutesBox.clear();
    await userBox.clear();
    await performancesBox.clear();
    await commentsBox.clear();
    await metadataBox.clear();
  }

  /// Obtient la taille totale du cache en nombre d'éléments
  Future<Map<String, int>> getCacheSize() async {
    final allRoutesBox = await Hive.openBox<String>(allRoutesBoxName);
    final myRoutesBox = await Hive.openBox<String>(myRoutesBoxName);
    final favoriteRoutesBox = await Hive.openBox<String>(favoriteRoutesBoxName);
    final userBox = await Hive.openBox<String>(userBoxName);
    final performancesBox = await Hive.openBox<String>(performancesBoxName);
    final commentsBox = await Hive.openBox<String>(commentsBoxName);

    return {
      'allRoutes': allRoutesBox.length,
      'myRoutes': myRoutesBox.length,
      'favoriteRoutes': favoriteRoutesBox.length,
      'user': userBox.length,
      'performances': performancesBox.length,
      'comments': commentsBox.length,
      'total': allRoutesBox.length + myRoutesBox.length + favoriteRoutesBox.length +
              userBox.length + performancesBox.length + commentsBox.length,
    };
  }

  /// Obtient des statistiques détaillées sur le cache
  Future<Map<String, dynamic>> getCacheStatistics() async {
    final size = await getCacheSize();

    return {
      'size': size,
      'metadata': {
        'allRoutes': await getLastCacheUpdate(allRoutesBoxName),
        'myRoutes': await getLastCacheUpdate(myRoutesBoxName),
        'favoriteRoutes': await getLastCacheUpdate(favoriteRoutesBoxName),
        'user': await getLastCacheUpdate(userBoxName),
      },
    };
  }
}