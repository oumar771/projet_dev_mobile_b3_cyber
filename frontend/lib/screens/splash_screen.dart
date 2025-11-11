import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../providers/service_providers.dart';
import '../providers/route_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/network_provider.dart';
import '../providers/offline_queue_provider.dart';
import 'home/home_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _loadingMessage = 'Initialisation...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  void _updateProgress(String message, double progress) {
    if (mounted) {
      setState(() {
        _loadingMessage = message;
        _progress = progress;
      });
    }
  }

  /// Gère le chargement initial (Cache-first, API-sync)
  Future<void> _initApp() async {
    bool isAuthenticated = false;

    try {
      // 0. Initialiser les services
      _updateProgress('Initialisation des services...', 0.0);
      final cacheService = ref.read(cacheServiceProvider);
      final authService = ref.read(authServiceProvider);
      final routeRepo = ref.read(routeRepositoryProvider);
      final networkService = ref.read(networkServiceProvider);
      final offlineQueueService = ref.read(offlineQueueServiceProvider);

      // Attendre que la vérification initiale du réseau soit terminée
      while (!networkService.hasCheckedInitialStatus) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint("SPLASH: État réseau: ${networkService.isOnline ? 'ONLINE' : 'OFFLINE'}");

      // 1. CHARGEMENT DU CACHE (Instantané)
      _updateProgress('Chargement du cache local...', 0.1);
      debugPrint("SPLASH: 1/6 - Chargement du cache Hive...");

      try {
        // Routes publiques
        final cachedAllRoutes = await cacheService.loadAllRoutesFromCache();
        if (cachedAllRoutes.isNotEmpty) {
          ref.read(allRoutesProvider.notifier).state = cachedAllRoutes;
          debugPrint("SPLASH: ${cachedAllRoutes.length} routes publiques chargées du cache");
        }

        // Routes personnelles
        final cachedMyRoutes = await cacheService.loadMyRoutesFromCache();
        if (cachedMyRoutes.isNotEmpty) {
          ref.read(myRoutesProvider.notifier).state = cachedMyRoutes;
          debugPrint("SPLASH: ${cachedMyRoutes.length} routes personnelles chargées du cache");
        }

        // Routes favorites
        final cachedFavoriteRoutes = await cacheService.loadFavoriteRoutesFromCache();
        if (cachedFavoriteRoutes.isNotEmpty) {
          ref.read(favoriteRoutesProvider.notifier).state = cachedFavoriteRoutes;
          debugPrint("SPLASH: ${cachedFavoriteRoutes.length} routes favorites chargées du cache");
        }

        // Utilisateur (si en cache)
        final cachedUser = await cacheService.loadUserFromCache();
        if (cachedUser != null) {
          debugPrint("SPLASH: Utilisateur chargé du cache: ${cachedUser.username}");
        }

        // Performances (si en cache)
        final cachedPerformances = await cacheService.loadPerformancesFromCache();
        if (cachedPerformances.isNotEmpty) {
          debugPrint("SPLASH: ${cachedPerformances.length} performances chargées du cache");
        }

      } catch (e) {
        debugPrint("SPLASH: Erreur de lecture du cache Hive: $e");
      }

      // 2. VÉRIFICATION DE L'AUTHENTIFICATION
      _updateProgress('Vérification de l\'authentification...', 0.3);
      debugPrint("SPLASH: 2/6 - Vérification de l'authentification...");

      // Vérifier d'abord si un utilisateur existe dans l'état du provider (après login offline)
      final currentAuthState = ref.read(authProvider);
      if (currentAuthState.isAuthenticated) {
        isAuthenticated = true;
        debugPrint("SPLASH: Utilisateur déjà authentifié dans le state: ${currentAuthState.user?.username}");
      } else {
        // Sinon, vérifier le token dans FlutterSecureStorage
        isAuthenticated = await authService.isAuthenticated();
      }

      // 3. RECHARGEMENT DE L'UTILISATEUR (si nécessaire)
      if (isAuthenticated && !currentAuthState.isAuthenticated) {
        _updateProgress('Chargement du profil utilisateur...', 0.4);
        debugPrint("SPLASH: 3/6 - Rechargement de l'état utilisateur...");
        await ref.read(authProvider.notifier).loadUserFromStorage();
      }

      // 4. SYNCHRONISATION API (si en ligne)
      if (networkService.isOnline) {
        _updateProgress('Synchronisation avec le serveur...', 0.5);
        debugPrint("SPLASH: 4/6 - Tentative de synchronisation API...");

        try {
          // A. Routes publiques
          final apiAllRoutes = await routeRepo.getAllRoutes();
          ref.read(allRoutesProvider.notifier).state = apiAllRoutes;
          await cacheService.cacheAllRoutes(apiAllRoutes);
          debugPrint("SPLASH: ${apiAllRoutes.length} routes publiques synchronisées");

          // B. Routes utilisateur (si connecté)
          if (isAuthenticated) {
            _updateProgress('Synchronisation de vos routes...', 0.6);

            final apiMyRoutes = await routeRepo.getMyRoutes();
            ref.read(myRoutesProvider.notifier).state = apiMyRoutes;
            await cacheService.cacheMyRoutes(apiMyRoutes);
            debugPrint("SPLASH: ${apiMyRoutes.length} routes personnelles synchronisées");

            // C. Routes favorites
            _updateProgress('Synchronisation de vos favoris...', 0.7);
            final apiFavoriteRoutes = await routeRepo.getFavoriteRoutes();
            ref.read(favoriteRoutesProvider.notifier).state = apiFavoriteRoutes;
            await cacheService.cacheFavoriteRoutes(apiFavoriteRoutes);
            debugPrint("SPLASH: ${apiFavoriteRoutes.length} routes favorites synchronisées");

            // D. Mettre à jour le cache utilisateur si disponible
            final currentUser = ref.read(authProvider).user;
            if (currentUser != null) {
              await cacheService.cacheUser(currentUser);
            }
          }

          _updateProgress('Synchronisation terminée', 0.9);

        } on DioException catch (e) {
          debugPrint("SPLASH: Échec de la synchronisation API: ${e.message}");
          _updateProgress('Mode hors ligne activé', 0.8);
        }
      } else {
        _updateProgress('Mode hors ligne', 0.6);
        debugPrint("SPLASH: Mode hors ligne - Utilisation du cache local");
      }

      // 5. INITIALISER LA FILE D'ATTENTE OFFLINE
      _updateProgress('Vérification des opérations en attente...', 0.95);
      debugPrint("SPLASH: 5/6 - Initialisation de la file d'attente offline...");
      await offlineQueueService.init();

      if (offlineQueueService.hasPendingOperations) {
        debugPrint("SPLASH: ${offlineQueueService.pendingCount} opérations en attente");
      }

      // 6. NAVIGATION
      _updateProgress('Chargement terminé', 1.0);
      debugPrint("SPLASH: 6/6 - Navigation...");
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => isAuthenticated ? const HomeScreen() : const LoginScreen(),
          ),
        );
      }

    } catch (e, stackTrace) {
      debugPrint('SPLASH: Erreur critique de chargement: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pedal_bike,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),

              // Titre
              const Text(
                'Vélo Angers',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Votre compagnon cycliste',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),

              // Barre de progression
              SizedBox(
                width: 250,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loadingMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Indicateur de chargement
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}