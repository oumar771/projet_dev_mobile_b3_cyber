import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../services/location_service.dart';
import '../services/cache_service.dart';
import '../services/sync_service.dart';

import '../repositories/auth_repository.dart';
import '../repositories/route_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/comment_repository.dart';
import '../repositories/external_api_repository.dart';
import '../repositories/performance_repository.dart';

import '../models/weather.dart';

import 'network_provider.dart';
import 'offline_queue_provider.dart';

// === CLIENT HTTP ===
final dioProvider = Provider<Dio>((ref) => Dio());

// === SERVICES ===

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  final authService = ref.watch(authServiceProvider);
  return ApiService(dio, authService);
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

// === REPOSITORIES ===

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthRepository(apiService);
});

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RouteRepository(apiService);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserRepository(apiService);
});

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CommentRepository(apiService);
});

final externalApiRepositoryProvider = Provider<ExternalApiRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final dio = ref.watch(dioProvider);
  return ExternalApiRepository(apiService, dio);
});

final performanceRepositoryProvider = Provider<PerformanceRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PerformanceRepository(apiService);
});

// === SYNC SERVICE ===

final syncServiceProvider = ChangeNotifierProvider<SyncService>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);
  final routeRepo = ref.watch(routeRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final performanceRepo = ref.watch(performanceRepositoryProvider);
  final commentRepo = ref.watch(commentRepositoryProvider);
  final networkService = ref.watch(networkServiceProvider);
  final offlineQueueService = ref.watch(offlineQueueServiceProvider);

  return SyncService(
    cacheService: cacheService,
    routeRepo: routeRepo,
    authRepo: authRepo,
    performanceRepo: performanceRepo,
    commentRepo: commentRepo,
    networkService: networkService,
    offlineQueueService: offlineQueueService,
  );
});

// === WEATHER PROVIDER ===

/// Provider pour récupérer la météo actuelle basée sur la position de l'utilisateur
final currentWeatherProvider = FutureProvider<Weather?>((ref) async {
  try {
    final locationService = ref.watch(locationServiceProvider);
    final externalRepo = ref.watch(externalApiRepositoryProvider);

    // Récupérer la position actuelle
    final position = await locationService.getCurrentPosition();
    if (position == null) return null;

    // Récupérer la météo
    final weather = await externalRepo.getWeather(position);
    return weather;
  } catch (e) {
    return null;
  }
});

/// Provider pour récupérer la météo d'une position spécifique
final weatherAtPositionProvider = FutureProvider.family<Weather?, LatLng>((ref, position) async {
  try {
    final externalRepo = ref.watch(externalApiRepositoryProvider);
    final weather = await externalRepo.getWeather(position);
    return weather;
  } catch (e) {
    return null;
  }
});