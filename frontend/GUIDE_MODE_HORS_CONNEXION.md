# Guide Complet - Mode Hors Connexion avec Hive

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture du système](#architecture-du-système)
3. [Services créés](#services-créés)
4. [Migration vers les nouveaux services](#migration-vers-les-nouveaux-services)
5. [Utilisation des services](#utilisation-des-services)
6. [Configuration](#configuration)
7. [Bonnes pratiques](#bonnes-pratiques)
8. [Dépannage](#dépannage)

---

## 📖 Vue d'ensemble

Le système de stockage local a été entièrement revu et optimisé pour offrir:

### ✨ Nouvelles fonctionnalités

- **Cache amélioré** avec versioning et expiration personnalisable
- **Gestion des paramètres** utilisateur (SettingsService)
- **File d'attente offline améliorée** avec priorisation et backoff exponentiel
- **SplashScreen optimisé** avec chargement parallèle et UX améliorée
- **Écran de gestion du cache** pour visualiser et contrôler le stockage
- **Mode offline-first** complet

### 🎯 Objectifs atteints

✅ Fonctionnement 100% hors connexion après la première synchronisation
✅ Synchronisation intelligente au démarrage
✅ Gestion robuste des erreurs réseau
✅ Statistiques détaillées du cache
✅ Configuration flexible par l'utilisateur

---

## 🏗️ Architecture du système

```
┌─────────────────────────────────────────────────────────────┐
│                     APPLICATION FLUTTER                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │
│  │ SplashScreen   │  │   Providers    │  │    Screens    │ │
│  │   Enhanced     │  │   (Riverpod)   │  │               │ │
│  └────────┬───────┘  └────────┬───────┘  └───────┬───────┘ │
│           │                   │                   │          │
│           └───────────────────┴───────────────────┘          │
│                              │                               │
├──────────────────────────────┼───────────────────────────────┤
│                        SERVICES LAYER                        │
├──────────────────────────────┴───────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │        CacheServiceEnhanced (Gestion du cache)       │   │
│  │  • Versioning du cache                               │   │
│  │  • Expiration personnalisable                        │   │
│  │  • Statistiques détaillées                           │   │
│  │  • Gestion des erreurs robuste                       │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────┴───────────────────────────────┐   │
│  │       SettingsService (Gestion des préférences)      │   │
│  │  • Durée d'expiration du cache                       │   │
│  │  • Auto-sync / WiFi only                             │   │
│  │  • Mode économie de données                          │   │
│  │  • Notifications                                     │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────┴───────────────────────────────┐   │
│  │   OfflineQueueServiceEnhanced (File d'attente)       │   │
│  │  • Priorisation des opérations                       │   │
│  │  • Backoff exponentiel                               │   │
│  │  • Gestion des conflits                              │   │
│  │  • Historique des échecs                             │   │
│  └──────────────────────┬───────────────────────────────┘   │
│                         │                                    │
├─────────────────────────┼─────────────────────────────────── │
│                    STORAGE LAYER (Hive)                      │
├─────────────────────────┴────────────────────────────────────┤
│                                                               │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐│
│  │  Routes DB  │  │  User DB     │  │ Offline Queue DB    ││
│  │  (TypeId 0) │  │  (TypeId 2)  │  │ (Pending Ops)       ││
│  └─────────────┘  └──────────────┘  └─────────────────────┘│
│                                                               │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐│
│  │Performance │  │  Comments DB │  │  Settings DB         ││
│  │  (TypeId 3)│  │  (TypeId 4)  │  │                      ││
│  └─────────────┘  └──────────────┘  └─────────────────────┘│
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

---

## 🔧 Services créés

### 1. CacheServiceEnhanced

**Fichier**: `lib/services/cache_service_enhanced.dart`

#### Nouvelles fonctionnalités

- **Versioning**: Gestion automatique des migrations de cache
- **Expiration personnalisable**: Paramétrable par l'utilisateur
- **Méthodes enrichies**: `ignoreExpiration`, `forceRefresh`
- **Gestion granulaire**: Ajout/suppression de routes individuelles
- **Statistiques**: `getCacheStatistics()`, `getCacheInfo()`
- **Invalidation**: Force le rafraîchissement du cache

#### Exemple d'utilisation

```dart
// Initialisation
final cacheService = CacheServiceEnhanced();
await cacheService.init();

// Cache avec force refresh
await cacheService.cacheAllRoutes(routes, forceRefresh: true);

// Chargement en ignorant l'expiration (mode offline)
final routes = await cacheService.loadAllRoutesFromCache(ignoreExpiration: true);

// Ajout d'une route individuelle
await cacheService.addRouteToCache(route, isMyRoute: true);

// Statistiques
final stats = await cacheService.getCacheStatistics();
print('Total éléments: ${stats['size']['total']}');

// Invalidation pour forcer un refresh
await cacheService.invalidateAllCaches();
```

### 2. SettingsService

**Fichier**: `lib/services/settings_service.dart`

#### Paramètres disponibles

| Paramètre | Type | Défaut | Description |
|-----------|------|--------|-------------|
| `cacheExpirationHours` | int | 24 | Durée avant expiration du cache |
| `autoSync` | bool | true | Synchronisation automatique au démarrage |
| `syncOnWifiOnly` | bool | false | Synchroniser uniquement sur WiFi |
| `showPublicRoutes` | bool | true | Afficher les routes publiques sur la carte |
| `mapTileCacheEnabled` | bool | true | Activer le cache des tuiles de carte |
| `offlineModeEnabled` | bool | false | Forcer le mode hors connexion |
| `dataSaverMode` | bool | false | Mode économie de données |
| `notificationsEnabled` | bool | true | Activer les notifications |

#### Exemple d'utilisation

```dart
// Initialisation
final settingsService = SettingsService();
await settingsService.init();

// Lecture
int hours = settingsService.cacheExpirationHours;
bool autoSync = settingsService.autoSync;

// Modification
settingsService.cacheExpirationHours = 48;
settingsService.syncOnWifiOnly = true;

// Export/Import
String json = settingsService.exportToJson();
await settingsService.importFromJson(json);

// Afficher les paramètres
settingsService.printSettings();
```

### 3. OfflineQueueServiceEnhanced

**Fichier**: `lib/services/offline_queue_service_enhanced.dart`

#### Nouvelles fonctionnalités

- **Priorisation**: Critical > High > Normal > Low
- **Backoff exponentiel**: Délai intelligent entre les tentatives (5s, 10s, 20s, 40s...)
- **Statuts d'opération**: Pending, Syncing, Failed, Completed
- **Historique des échecs**: Séparation des opérations échouées
- **Retry intelligent**: Max 3 tentatives avec délai adaptatif
- **Statistiques détaillées**: Par type, par priorité

#### Types d'opérations et priorités

```dart
enum OperationType {
  createRoute,        // Priorité: Normal
  updateRoute,        // Priorité: Normal
  deleteRoute,        // Priorité: Normal
  createComment,      // Priorité: Low
  updatePerformance,  // Priorité: Critical
  toggleFavorite,     // Priorité: Normal
  updateUserLocation, // Priorité: High
  updateUserProfile,  // Priorité: High
}
```

#### Exemple d'utilisation

```dart
// Initialisation
final queueService = OfflineQueueServiceEnhanced();
await queueService.init();

// Ajout avec priorité automatique
await queueService.addOperationAuto(
  type: OperationType.updatePerformance,
  data: {'performanceId': 123, 'distance': 15.5},
);

// Ajout avec priorité manuelle
await queueService.addOperation(
  type: OperationType.createRoute,
  data: routeData,
  priority: OperationPriority.high,
);

// Synchronisation
await queueService.syncPendingOperations(
  onExecuteOperation: (operation) async {
    // Exécuter l'opération
    switch (operation.type) {
      case OperationType.createRoute:
        return await routeRepo.createRoute(operation.data);
      // ...
    }
  },
);

// Statistiques
final stats = queueService.getStatistics();
print('En attente: ${stats['totalPending']}');
print('Critiques: ${stats['criticalCount']}');

queueService.printSummary(); // Affiche un résumé complet
```

### 4. SplashScreenEnhanced

**Fichier**: `lib/screens/splash_screen_enhanced.dart`

#### Améliorations

- **Chargement parallèle**: Routes, utilisateur et performances en simultané
- **Animation fluide**: Logo avec fade-in
- **Messages détaillés**: Affichage de la progression claire
- **Gestion d'erreurs**: Affichage visuel des erreurs avec redirection
- **Logs détaillés**: Debug complet dans la console
- **Transition fluide**: Fade entre splash et écran suivant

#### Flux de démarrage

```
1. Initialisation des services (5%)
   ├─ CacheService.init()
   ├─ Vérification réseau
   └─ Initialisation des providers

2. Chargement du cache (15% → 30%)
   ├─ Chargement parallèle:
   │  ├─ Routes (publiques, personnelles, favoris)
   │  ├─ Utilisateur
   │  └─ Performances
   └─ Affichage instantané

3. Authentification (30% → 35%)
   ├─ Vérification du token
   └─ Chargement du profil

4. Synchronisation API (35% → 80%)
   ├─ Si EN LIGNE:
   │  ├─ Routes publiques
   │  ├─ Mes routes
   │  ├─ Favoris
   │  └─ Mise à jour du cache
   └─ Si HORS LIGNE:
       └─ Utilisation du cache uniquement

5. File d'attente (85% → 90%)
   └─ Chargement des opérations en attente

6. Finalisation (90% → 100%)
   ├─ Affichage des statistiques
   └─ Navigation vers HomeScreen ou LoginScreen
```

### 5. CacheSettingsScreen

**Fichier**: `lib/screens/settings/cache_settings_screen.dart`

#### Fonctionnalités

- **Statistiques en temps réel**: Taille du cache, file d'attente
- **Paramètres modifiables**: Expiration, auto-sync, WiFi only, etc.
- **Actions de maintenance**:
  - Vider le cache des routes uniquement
  - Forcer le rafraîchissement (invalider le cache)
  - Vider tout le cache
- **Pull-to-refresh**: Mise à jour des statistiques

---

## 🔄 Migration vers les nouveaux services

### Étape 1: Mise à jour des providers

**Fichier**: `lib/providers/service_providers.dart`

```dart
import '../services/cache_service_enhanced.dart';
import '../services/settings_service.dart';
import '../services/offline_queue_service_enhanced.dart';

// Remplacer CacheService par CacheServiceEnhanced
final cacheServiceProvider = Provider<CacheServiceEnhanced>((ref) {
  return CacheServiceEnhanced();
});

// Ajouter SettingsService
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

// Remplacer OfflineQueueService par OfflineQueueServiceEnhanced
final offlineQueueServiceProvider = ChangeNotifierProvider<OfflineQueueServiceEnhanced>((ref) {
  return OfflineQueueServiceEnhanced();
});
```

### Étape 2: Mise à jour de main.dart

```dart
import 'screens/splash_screen_enhanced.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive initialization (inchangé)
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
  }

  // Enregistrer les adapters (inchangé)
  Hive.registerAdapter(BikeRouteAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(PerformanceAdapter());
  Hive.registerAdapter(CommentAdapter());
  Hive.registerAdapter(LatLngAdapter());

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vélo Angers',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Utiliser le nouveau SplashScreen
      home: const SplashScreenEnhanced(),
    );
  }
}
```

### Étape 3: Ajout de l'écran de paramètres

Dans votre `ProfileScreen` ou menu de paramètres:

```dart
import '../screens/settings/cache_settings_screen.dart';

// Ajouter un bouton pour accéder aux paramètres de cache
ListTile(
  leading: const Icon(Icons.storage),
  title: const Text('Gestion du cache'),
  subtitle: const Text('Paramètres et statistiques'),
  trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CacheSettingsScreen(),
      ),
    );
  },
),
```

---

## 📚 Utilisation des services

### Scénario 1: Première utilisation (avec connexion)

```
Utilisateur installe l'app → Ouvre l'app
                              ↓
                      SplashScreen démarre
                              ↓
                    Pas de cache local
                              ↓
                  Vérification: NON authentifié
                              ↓
                    Navigation → LoginScreen
                              ↓
        Utilisateur se connecte avec succès
                              ↓
            Téléchargement des données depuis l'API
                              ↓
                Mise en cache automatique
                              ↓
                  Navigation → HomeScreen
                              ↓
                  APP PRÊTE (mode online)
```

### Scénario 2: Utilisation normale (avec connexion)

```
Utilisateur ouvre l'app (2ème fois+)
                ↓
        SplashScreen démarre
                ↓
  Chargement INSTANTANÉ du cache local
                ↓
        Affichage immédiat des données
                ↓
    Vérification: Authentifié (token valide)
                ↓
Synchronisation en arrière-plan avec l'API
                ↓
    Mise à jour du cache si nouvelles données
                ↓
            Navigation → HomeScreen
                ↓
    APP PRÊTE (données à jour)
```

### Scénario 3: Mode hors connexion

```
Utilisateur ouvre l'app SANS connexion
                ↓
        SplashScreen démarre
                ↓
  Chargement du cache local (ignoreExpiration: true)
                ↓
        Affichage des données en cache
                ↓
    Vérification réseau: OFFLINE détecté
                ↓
      Pas de tentative de sync API
                ↓
Chargement de la file d'attente offline
                ↓
            Navigation → HomeScreen
                ↓
    APP PRÊTE (mode offline)
                ↓
    Utilisateur effectue des actions
                ↓
Actions ajoutées à la file d'attente offline
                ↓
    [Connexion rétablie plus tard]
                ↓
Synchronisation automatique au prochain démarrage
```

### Scénario 4: Synchronisation de la file d'attente

```
App détecte le retour de la connexion
                ↓
    Vérification: File d'attente non vide
                ↓
        Tri par priorité:
        1. Opérations critiques
        2. Opérations haute priorité
        3. Opérations normales
        4. Opérations basse priorité
                ↓
    Tentative de synchronisation
                ↓
        ┌─── Succès ───┐     ┌─── Échec ───┐
        │              │     │             │
    Supprimé      Incrémenter       Max 3 tentatives?
    de la file      retry count              │
                                     ┌────────┴────────┐
                                     │                 │
                                   OUI               NON
                                     │                 │
                                Déplacé vers      Prochain
                                les échecs        essai avec
                                                  backoff
```

---

## ⚙️ Configuration

### Personnalisation des durées d'expiration

Dans `lib/services/cache_service_enhanced.dart`:

```dart
// Modifier les constantes selon vos besoins
const Duration routesCacheExpiration = Duration(hours: 24);
const Duration userCacheExpiration = Duration(hours: 12);
const Duration performancesCacheExpiration = Duration(hours: 6);
const Duration commentsCacheExpiration = Duration(minutes: 30);
```

Ou via SettingsService (recommandé):

```dart
final settingsService = ref.read(settingsServiceProvider);
settingsService.cacheExpirationHours = 48; // 2 jours
```

### Configuration de l'offline queue

Dans `lib/services/offline_queue_service_enhanced.dart`:

```dart
// Modifier les constantes selon vos besoins
static const int maxRetries = 3;
static const Duration initialRetryDelay = Duration(seconds: 5);
static const Duration maxRetryDelay = Duration(minutes: 5);
```

---

## 💡 Bonnes pratiques

### 1. Gestion du cache

```dart
// ✅ BON: Utiliser forceRefresh lors d'un pull-to-refresh
Future<void> _refreshData() async {
  final routes = await routeRepo.getAllRoutes();
  await cacheService.cacheAllRoutes(routes, forceRefresh: true);
}

// ❌ MAUVAIS: Ne pas ignorer l'expiration sans raison
final routes = await cacheService.loadAllRoutesFromCache(
  ignoreExpiration: true, // Uniquement si mode offline forcé
);
```

### 2. Gestion de la file d'attente

```dart
// ✅ BON: Utiliser la priorité automatique
await queueService.addOperationAuto(
  type: OperationType.updatePerformance,
  data: data,
);

// ✅ BON: Définir une priorité manuelle si nécessaire
await queueService.addOperation(
  type: OperationType.createRoute,
  data: data,
  priority: OperationPriority.critical, // Si vraiment important
);

// ❌ MAUVAIS: Mettre tout en priorité critique
await queueService.addOperation(
  type: OperationType.createComment, // Un commentaire n'est pas critique
  data: data,
  priority: OperationPriority.critical,
);
```

### 3. Vérification de la connexion

```dart
// ✅ BON: Vérifier avant les opérations critiques
final networkService = ref.read(networkServiceProvider);
if (networkService.isOnline) {
  // Opération en ligne
  await api.createRoute(route);
} else {
  // Ajouter à la file d'attente
  await queueService.addOperationAuto(
    type: OperationType.createRoute,
    data: route.toJson(),
  );
}
```

### 4. Gestion des erreurs

```dart
// ✅ BON: Gérer les erreurs de cache
try {
  await cacheService.cacheAllRoutes(routes);
} catch (e) {
  debugPrint('Erreur de mise en cache: $e');
  // L'app peut continuer sans cache
}

// ✅ BON: Fallback sur le cache en cas d'erreur API
try {
  final routes = await routeRepo.getAllRoutes();
  await cacheService.cacheAllRoutes(routes);
  return routes;
} catch (e) {
  debugPrint('API error, loading from cache: $e');
  return await cacheService.loadAllRoutesFromCache(ignoreExpiration: true);
}
```

---

## 🐛 Dépannage

### Problème: Le cache ne se charge pas

**Solution**:
```dart
// Vérifier l'initialisation
final cacheService = ref.read(cacheServiceProvider);
if (cacheService is CacheServiceEnhanced) {
  await cacheService.init();
}

// Vérifier les statistiques
final stats = await cacheService.getCacheStatistics();
debugPrint(stats.toString());
```

### Problème: Les opérations offline ne se synchronisent pas

**Solution**:
```dart
// Vérifier la file d'attente
final queueService = ref.read(offlineQueueServiceProvider);
queueService.printSummary();

// Forcer une synchronisation
await queueService.syncPendingOperations(
  onExecuteOperation: (operation) async {
    // Votre logique de synchronisation
    return true;
  },
);
```

### Problème: Le cache expire trop vite

**Solution**:
```dart
// Modifier via les paramètres
final settingsService = SettingsService();
await settingsService.init();
settingsService.cacheExpirationHours = 48; // 2 jours

// Ou invalider pour forcer un refresh
await cacheService.invalidateAllCaches();
```

### Problème: L'app est lente au démarrage

**Solutions**:
1. Vérifier la taille du cache:
```dart
final size = await cacheService.getCacheSize();
if (size['total']! > 1000) {
  // Nettoyer l'ancien cache
  await cacheService.clearAll();
}
```

2. Optimiser le chargement parallèle dans SplashScreen (déjà implémenté)

---

## 📊 Monitoring et statistiques

### Afficher les statistiques du cache

```dart
final cacheService = ref.read(cacheServiceProvider);
if (cacheService is CacheServiceEnhanced) {
  final stats = await cacheService.getCacheStatistics();

  print('Version du cache: ${stats['cacheVersion']}');
  print('Date d\'installation: ${stats['installDate']}');
  print('Total éléments: ${stats['size']['total']}');

  final allRoutesInfo = stats['caches']['allRoutes'];
  print('Âge du cache routes: ${allRoutesInfo['ageInHours']} heures');
  print('Expiré: ${allRoutesInfo['isExpired']}');
}
```

### Afficher les statistiques de la file d'attente

```dart
final queueService = ref.read(offlineQueueServiceProvider);
if (queueService is OfflineQueueServiceEnhanced) {
  queueService.printSummary();

  // Ou programmatiquement:
  final stats = queueService.getStatistics();
  print('Opérations en attente: ${stats['totalPending']}');
  print('Opérations critiques: ${stats['criticalCount']}');
  print('En cours de sync: ${stats['isSyncing']}');
}
```

---

## 🎓 Conclusion

Votre application dispose maintenant d'un système complet de gestion hors connexion avec:

✅ **Cache intelligent** avec expiration personnalisable
✅ **File d'attente robuste** avec priorisation
✅ **Paramètres utilisateur** flexibles
✅ **Interface de gestion** du cache
✅ **Logs détaillés** pour le débogage

L'application peut maintenant fonctionner entièrement hors connexion après la première synchronisation, tout en offrant une expérience utilisateur optimale.

Pour toute question ou problème, consultez les logs de debug ou l'écran de gestion du cache dans l'application.
