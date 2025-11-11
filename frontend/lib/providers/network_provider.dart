import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/network_service.dart';

/// Provider global pour le service réseau
///
/// Utilise ChangeNotifierProvider pour que l'UI soit notifiée
/// automatiquement lors des changements d'état de connexion
final networkServiceProvider = ChangeNotifierProvider<NetworkService>((ref) {
  return NetworkService();
});

/// Provider pour vérifier rapidement si l'appareil est en ligne
final isOnlineProvider = Provider<bool>((ref) {
  final networkService = ref.watch(networkServiceProvider);
  return networkService.isOnline;
});