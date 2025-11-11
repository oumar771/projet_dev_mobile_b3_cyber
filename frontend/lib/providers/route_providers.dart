import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'service_providers.dart';
import '../models/route.dart';
import '../models/route_suggestion.dart';

// REFACTORISÉ: Passage en StateProvider pour le cache
// Ce provider contiendra la liste des routes publiques chargées depuis Hive au démarrage.
// Il sera ensuite mis à jour par la synchronisation API (via le SplashScreen).
final allRoutesProvider = StateProvider<List<BikeRoute>>((ref) {
  // La valeur initiale est une liste vide.
  // Le CacheService/SplashScreen la remplira.
  return [];
});

// REFACTORISÉ: Passage en StateProvider pour le cache
final myRoutesProvider = StateProvider<List<BikeRoute>>((ref) {
  return [];
});

// REFACTORISÉ: Passage en StateProvider pour le cache (par cohérence)
// Même si l'API (GET /api/routes/favorites) est buggée (404),
// nous préparons le provider pour le cache.
final favoriteRoutesProvider = StateProvider<List<BikeRoute>>((ref) {
  return [];
});


// NON MODIFIÉ: Récupération d'une route spécifique (pour l'instant)
// Ce provider fetchera toujours la route. On pourrait l'optimiser plus tard
// pour qu'il lise d'abord depuis les StateProviders ci-dessus.
final routeByIdProvider = FutureProvider.family<BikeRoute, int>((ref, routeId) async {
  final routeRepo = ref.watch(routeRepositoryProvider);
  return await routeRepo.getRouteById(routeId);
});

// NON MODIFIÉ: Gestion de la route sélectionnée sur la carte
class SelectedRouteNotifier extends StateNotifier<BikeRoute?> {
  SelectedRouteNotifier() : super(null);

  void selectRoute(BikeRoute route) {
    state = route;
  }

  void clearSelection() {
    state = null;
  }
}

final selectedRouteProvider = StateNotifierProvider<SelectedRouteNotifier, BikeRoute?>((ref) {
  return SelectedRouteNotifier();
});

// NON MODIFIÉ: Paramètres pour la planification
final routePlanParamsProvider = StateProvider<Map<String, LatLng>?>((ref) {
  return null;
});

// NON MODIFIÉ: Ce provider est pour la planification A->B dynamique (OpenRouteService).
// Il n'est pas destiné à être mis en cache au démarrage.
final routeSuggestionsProvider = FutureProvider<List<RouteSuggestion>>((ref) async {
  final params = ref.watch(routePlanParamsProvider);

  if (params == null || params['start'] == null || params['end'] == null) {
    return [];
  }

  final repository = ref.watch(externalApiRepositoryProvider);

  return repository.planRoute(
    start: params['start']!,
    end: params['end']!,
  );
});

// NON MODIFIÉ: Suggestion de route A->B sélectionnée
final selectedRouteSuggestionProvider = StateProvider<RouteSuggestion?>((ref) {
  return null;
});

// NOUVEAUX PROVIDERS POUR LE FILTRAGE PUBLIC/PRIVÉ

/// Provider pour récupérer uniquement les trajets publics
final publicRoutesOnlyProvider = Provider<List<BikeRoute>>((ref) {
  final allRoutes = ref.watch(allRoutesProvider);
  return allRoutes.where((route) => route.isPublic).toList();
});

/// Provider pour récupérer uniquement les trajets privés de l'utilisateur
final privateRoutesOnlyProvider = Provider<List<BikeRoute>>((ref) {
  final myRoutes = ref.watch(myRoutesProvider);
  return myRoutes.where((route) => !route.isPublic).toList();
});

/// Provider pour contrôler l'affichage des trajets publics sur la carte
/// Par défaut, les trajets publics ne sont PAS affichés sur la carte principale
final showPublicRoutesOnMapProvider = StateProvider<bool>((ref) {
  return false; // Désactivé par défaut
});

/// Provider pour contrôler l'affichage de MES trajets sur la carte
/// Par défaut, MES trajets ne sont PAS affichés sur la carte principale
final showMyRoutesOnMapProvider = StateProvider<bool>((ref) {
  return false; // Désactivé par défaut
});