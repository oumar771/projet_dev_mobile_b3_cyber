import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service de gestion de la connectivité réseau
///
/// Surveille l'état de la connexion internet et notifie les écouteurs
/// lorsque l'état change (online/offline)
class NetworkService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  bool _hasCheckedInitialStatus = false;
  bool get hasCheckedInitialStatus => _hasCheckedInitialStatus;

  NetworkService() {
    _initConnectivity();
    _startListening();
  }

  /// Initialise et vérifie l'état de la connexion au démarrage
  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      _hasCheckedInitialStatus = true;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la connectivité: $e');
      _isOnline = false;
      _hasCheckedInitialStatus = true;
    }
  }

  /// Démarre l'écoute des changements de connectivité
  void _startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      },
      onError: (error) {
        debugPrint('Erreur dans le stream de connectivité: $error');
        _isOnline = false;
        notifyListeners();
      },
    );
  }

  /// Met à jour l'état de la connexion
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    // Considérer comme online si au moins une connexion est disponible
    _isOnline = results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);

    // Notifier uniquement si l'état a changé
    if (wasOnline != _isOnline) {
      debugPrint('État de connexion changé: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      notifyListeners();
    }
  }

  /// Vérifie manuellement l'état de la connexion
  Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return _isOnline;
    } catch (e) {
      debugPrint('Erreur lors de la vérification manuelle: $e');
      return false;
    }
  }

  /// Obtient le type de connexion actuel
  Future<String> getConnectionType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty || results.first == ConnectivityResult.none) {
        return 'Aucune connexion';
      }

      final types = results.map((result) {
        switch (result) {
          case ConnectivityResult.wifi:
            return 'WiFi';
          case ConnectivityResult.mobile:
            return 'Mobile';
          case ConnectivityResult.ethernet:
            return 'Ethernet';
          default:
            return 'Autre';
        }
      }).toList();

      return types.join(', ');
    } catch (e) {
      debugPrint('Erreur lors de la récupération du type de connexion: $e');
      return 'Inconnu';
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}