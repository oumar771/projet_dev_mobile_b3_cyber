import 'package:flutter/foundation.dart';
import 'cache_service.dart';
import 'network_service.dart';
import 'offline_queue_service.dart';
import '../repositories/route_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/performance_repository.dart';
import '../repositories/comment_repository.dart';

/// Service de synchronisation entre local et serveur
///
/// Gère la synchronisation bidirectionnelle des données entre
/// le cache local (Hive) et le serveur backend
class SyncService extends ChangeNotifier {
  final CacheService _cacheService;
  final RouteRepository _routeRepo;
  final AuthRepository _authRepo;
  final PerformanceRepository _performanceRepo;
  final CommentRepository _commentRepo;
  final NetworkService _networkService;
  final OfflineQueueService _offlineQueueService;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  SyncService({
    required CacheService cacheService,
    required RouteRepository routeRepo,
    required AuthRepository authRepo,
    required PerformanceRepository performanceRepo,
    required CommentRepository commentRepo,
    required NetworkService networkService,
    required OfflineQueueService offlineQueueService,
  })  : _cacheService = cacheService,
        _routeRepo = routeRepo,
        _authRepo = authRepo,
        _performanceRepo = performanceRepo,
        _commentRepo = commentRepo,
        _networkService = networkService,
        _offlineQueueService = offlineQueueService {
    // Écouter les changements de connectivité pour synchroniser automatiquement
    _networkService.addListener(_onConnectivityChanged);
  }

  /// Appelé lorsque la connectivité change
  void _onConnectivityChanged() {
    if (_networkService.isOnline && !_isSyncing) {
      debugPrint('SYNC: Connexion détectée, synchronisation automatique...');
      syncAll(background: true);
    }
  }

  /// Synchroniser toutes les données
  ///
  /// [background] - Si true, synchronise en arrière-plan sans bloquer
  /// Returns true si la synchronisation a réussi
  Future<bool> syncAll({bool background = false}) async {
    if (_isSyncing) {
      debugPrint('SYNC: Synchronisation déjà en cours');
      return false;
    }

    if (!_networkService.isOnline) {
      debugPrint('SYNC: Pas de connexion internet, synchronisation annulée');
      return false;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      debugPrint('SYNC: Début de la synchronisation complète');

      // 1. Synchroniser les opérations en attente
      await syncPendingOperations();

      // 2. Synchroniser les routes
      await syncRoutes();

      // 3. Synchroniser l'utilisateur
      await syncUser();

      // 4. Synchroniser les performances
      await syncPerformances();

      _lastSyncTime = DateTime.now();
      debugPrint('SYNC: Synchronisation complète terminée avec succès');

      return true;
    } catch (e) {
      debugPrint('SYNC: Erreur de synchronisation: $e');
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Synchroniser les routes depuis le serveur vers le local
  Future<void> syncRoutes() async {
    try {
      debugPrint('SYNC: Synchronisation des routes...');

      // Récupérer toutes les routes publiques
      final publicRoutes = await _routeRepo.getAllRoutes();
      await _cacheService.cacheAllRoutes(publicRoutes);
      debugPrint('SYNC: ${publicRoutes.length} routes publiques synchronisées');

      // Récupérer les routes de l'utilisateur
      try {
        final myRoutes = await _routeRepo.getMyRoutes();
        await _cacheService.cacheMyRoutes(myRoutes);
        debugPrint('SYNC: ${myRoutes.length} routes personnelles synchronisées');
      } catch (e) {
        // Peut échouer si l'utilisateur n'est pas connecté
        debugPrint('SYNC: Impossible de synchroniser les routes personnelles: $e');
      }

      // Récupérer les routes favorites
      try {
        final favoriteRoutes = await _routeRepo.getFavoriteRoutes();
        await _cacheService.cacheFavoriteRoutes(favoriteRoutes);
        debugPrint('SYNC: ${favoriteRoutes.length} routes favorites synchronisées');
      } catch (e) {
        debugPrint('SYNC: Impossible de synchroniser les routes favorites: $e');
      }

    } catch (e) {
      debugPrint('SYNC: Erreur lors de la synchronisation des routes: $e');
      rethrow;
    }
  }

  /// Synchroniser les informations utilisateur
  Future<void> syncUser() async {
    try {
      debugPrint('SYNC: Synchronisation de l\'utilisateur...');
      final user = await _authRepo.getCurrentUser();
      await _cacheService.cacheUser(user);
      debugPrint('SYNC: Utilisateur synchronisé: ${user.username}');
    } catch (e) {
      debugPrint('SYNC: Erreur lors de la synchronisation utilisateur: $e');
      // Ne pas rethrow car l'utilisateur peut ne pas être connecté
    }
  }

  /// Synchroniser les performances
  Future<void> syncPerformances() async {
    try {
      debugPrint('SYNC: Synchronisation des performances...');
      final performances = await _performanceRepo.getUserPerformances();
      await _cacheService.cachePerformances(performances);
      debugPrint('SYNC: ${performances.length} performances synchronisées');
    } catch (e) {
      debugPrint('SYNC: Erreur lors de la synchronisation des performances: $e');
    }
  }

  /// Synchroniser les commentaires d'une route spécifique
  Future<void> syncCommentsForRoute(int routeId) async {
    try {
      debugPrint('SYNC: Synchronisation des commentaires pour la route $routeId...');
      final comments = await _commentRepo.getCommentsByRoute(routeId);
      await _cacheService.cacheComments(routeId, comments);
      debugPrint('SYNC: ${comments.length} commentaires synchronisés');
    } catch (e) {
      debugPrint('SYNC: Erreur lors de la synchronisation des commentaires: $e');
    }
  }

  /// Synchroniser les opérations en attente
  Future<int> syncPendingOperations() async {
    if (!_networkService.isOnline) {
      debugPrint('SYNC: Hors ligne, opérations en attente non synchronisées');
      return 0;
    }

    debugPrint('SYNC: Synchronisation des opérations en attente...');

    return await _offlineQueueService.syncPendingOperations(
      onExecuteOperation: _executeOperation,
    );
  }

  /// Exécute une opération en attente
  Future<bool> _executeOperation(PendingOperation operation) async {
    try {
      debugPrint('SYNC: Exécution de l\'opération ${operation.type}');

      switch (operation.type) {
        case OperationType.createRoute:
          // Créer la route sur le serveur
          final waypoints = (operation.data['waypoints'] as List)
              .map((w) => {
                'lat': (w['lat'] as num).toDouble(),
                'lng': (w['lng'] as num).toDouble(),
              })
              .cast<Map<String, double>>()
              .toList();

          await _routeRepo.createRoute(
            name: operation.data['name'],
            description: operation.data['description'],
            isPublic: operation.data['isPublic'],
            waypoints: waypoints,
          );
          debugPrint('SYNC: Route créée avec succès');
          return true;

        case OperationType.updateRoute:
          // Mettre à jour la route sur le serveur
          final routeId = operation.data['id'];
          await _routeRepo.updateRoute(
            routeId: routeId,
            name: operation.data['name'],
            description: operation.data['description'],
            isPublic: operation.data['isPublic'],
          );
          debugPrint('SYNC: Route mise à jour avec succès');
          return true;

        case OperationType.deleteRoute:
          // Supprimer la route sur le serveur
          await _routeRepo.deleteRoute(operation.data['id']);
          debugPrint('SYNC: Route supprimée avec succès');
          return true;

        case OperationType.createComment:
          // Créer le commentaire sur le serveur
          await _commentRepo.addComment(
            operation.data['routeId'],
            operation.data['text'],
          );
          debugPrint('SYNC: Commentaire créé avec succès');
          return true;

        case OperationType.toggleFavorite:
          // Basculer le favori sur le serveur
          if (operation.data['isFavorite']) {
            await _routeRepo.addToFavorites(operation.data['routeId']);
          } else {
            await _routeRepo.removeFromFavorites(operation.data['routeId']);
          }
          debugPrint('SYNC: Favori basculé avec succès');
          return true;

        default:
          debugPrint('SYNC: Type d\'opération non supporté: ${operation.type}');
          return false;
      }
    } catch (e) {
      debugPrint('SYNC: Erreur lors de l\'exécution de l\'opération: $e');
      return false;
    }
  }

  /// Obtenir les données depuis le cache local si disponibles
  Future<bool> loadFromCache() async {
    try {
      return await _cacheService.hasCachedData();
    } catch (e) {
      debugPrint('SYNC: Erreur lors du chargement du cache: $e');
      return false;
    }
  }

  /// Vider toutes les données lors de la déconnexion
  Future<void> clearAllData() async {
    debugPrint('SYNC: Suppression de toutes les données en cache...');
    await _cacheService.clearAll();
    await _offlineQueueService.clearAll();
    _lastSyncTime = null;
    notifyListeners();
  }

  /// Obtient le temps écoulé depuis la dernière synchronisation
  Duration? getTimeSinceLastSync() {
    if (_lastSyncTime == null) return null;
    return DateTime.now().difference(_lastSyncTime!);
  }

  /// Vérifie si une synchronisation est nécessaire
  bool needsSync({Duration threshold = const Duration(hours: 1)}) {
    final timeSinceLastSync = getTimeSinceLastSync();
    if (timeSinceLastSync == null) return true;
    return timeSinceLastSync > threshold;
  }

  @override
  void dispose() {
    _networkService.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}