import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_queue_service.dart';

/// Provider global pour le service de file d'attente offline
final offlineQueueServiceProvider = ChangeNotifierProvider<OfflineQueueService>((ref) {
  final service = OfflineQueueService();
  service.init(); // Initialise et charge les opérations en attente
  return service;
});

/// Provider pour le nombre d'opérations en attente
final pendingOperationsCountProvider = Provider<int>((ref) {
  final queueService = ref.watch(offlineQueueServiceProvider);
  return queueService.pendingCount;
});

/// Provider pour vérifier si une synchronisation est en cours
final isSyncingProvider = Provider<bool>((ref) {
  final queueService = ref.watch(offlineQueueServiceProvider);
  return queueService.isSyncing;
});