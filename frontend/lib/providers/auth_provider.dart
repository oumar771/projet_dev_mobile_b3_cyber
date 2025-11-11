// lib/providers/auth_provider.dart — VERSION AVEC PERSISTANCE UTILISATEUR

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/user.dart';
import '../models/route.dart';
import '../services/cache_service.dart';
import 'service_providers.dart';
import 'network_provider.dart';

// ------------------------------------------------------------
// 🧩 ÉTAT D’AUTHENTIFICATION
// ------------------------------------------------------------
class AuthState {
  final bool isLoading;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    bool? isLoading,
    User? user,
    bool clearUser = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ------------------------------------------------------------
// 🚀 NOTIFIER : GESTION DE L’AUTHENTIFICATION
// ------------------------------------------------------------
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState());

  // 🔄 Rechargement utilisateur depuis le cache
  Future<void> loadUserFromStorage() async {
    print('ALoad: Rechargement de l’utilisateur depuis le stockage...');
    final authService = ref.read(authServiceProvider);
    try {
      final user = await authService.loadUserFromStorage();
      if (user != null) {
        state = state.copyWith(user: user);
        print('ALoad: Utilisateur ${user.username} rechargé !');
      } else {
        print('ALoad: Aucun utilisateur trouvé en cache.');
      }
    } catch (e) {
      print('ALoad: Erreur au rechargement de l’utilisateur: $e');
    }
  }

  // 🔐 Connexion (avec support offline)
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final authService = ref.read(authServiceProvider);
      final networkService = ref.read(networkServiceProvider);

      // Vérifier si on est en ligne
      final isOnline = networkService.isOnline;

      if (!isOnline) {
        // MODE OFFLINE : Vérifier si l'utilisateur existe en cache
        print('ALogin: Mode OFFLINE détecté - Tentative de connexion offline');

        // Essayer de charger depuis SharedPreferences d'abord
        User? cachedUser = await authService.loadUserFromStorage();

        // Si pas trouvé dans SharedPreferences, essayer Hive
        if (cachedUser == null) {
          print('ALogin: Pas d\'utilisateur dans SharedPreferences, essai depuis Hive...');
          final cacheService = ref.read(cacheServiceProvider);
          cachedUser = await cacheService.loadUserFromCache();
        }

        if (cachedUser != null && cachedUser.username == username) {
          // L'utilisateur existe en cache, on le connecte
          // Sauvegarder un token factice pour maintenir la session en mode offline
          final offlineToken = 'offline_token_${DateTime.now().millisecondsSinceEpoch}';
          await authService.saveSession(offlineToken, cachedUser);

          state = state.copyWith(isLoading: false, user: cachedUser, clearError: true);
          print('ALogin: Connexion offline réussie pour ${cachedUser.username}');
          return true;
        } else {
          // Aucun utilisateur en cache ou username différent
          throw Exception('Mode hors ligne : Impossible de vous connecter.\nConnectez-vous une première fois avec internet.');
        }
      }

      // MODE ONLINE : Connexion normale avec le serveur
      print('ALogin: Mode ONLINE - Connexion au serveur');
      final response = await authRepo.login(username, password);
      final token = response['accessToken'] as String?;
      if (token == null || token.isEmpty) throw Exception('Aucun token reçu');

      late User user;
      if (response['id'] != null && response['username'] != null) {
        user = User.fromJson(response);
      } else if (response['user'] != null) {
        user = User.fromJson(response['user']);
      } else {
        user = User(
          id: response['id'] ?? 0,
          username: username,
          email: response['email'] ?? '',
        );
      }

      // Sauvegarder la session (SharedPreferences + FlutterSecureStorage)
      await authService.saveSession(token, user);

      // Sauvegarder aussi dans Hive pour le mode offline
      final cacheService = ref.read(cacheServiceProvider);
      await cacheService.cacheUser(user);
      print('ALogin: Utilisateur sauvegardé dans Hive pour le mode offline');

      state = state.copyWith(isLoading: false, user: user, clearError: true);
      print('ALogin: Connexion réussie !');
      return true;
    } catch (e) {
      print('ALogin: Erreur lors du login: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // 🧾 Inscription
  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final authService = ref.read(authServiceProvider);

      final response = await authRepo.register(
        username: username,
        email: email,
        password: password,
      );

      final token = response['accessToken'] as String?;
      if (token == null || token.isEmpty) throw Exception('Aucun token reçu');

      late User user;
      if (response['id'] != null && response['username'] != null) {
        user = User.fromJson(response);
      } else if (response['user'] != null) {
        user = User.fromJson(response['user']);
      } else {
        user = User(
          id: response['id'] ?? 0,
          username: username,
          email: email,
        );
      }

      // Sauvegarder la session (SharedPreferences + FlutterSecureStorage)
      await authService.saveSession(token, user);

      // Sauvegarder aussi dans Hive pour le mode offline
      final cacheService = ref.read(cacheServiceProvider);
      await cacheService.cacheUser(user);
      print('ARegister: Utilisateur sauvegardé dans Hive pour le mode offline');

      state = state.copyWith(isLoading: false, user: user, clearError: true);
      print('ARegister: Inscription réussie !');
      return true;
    } catch (e) {
      print('ARegister: Erreur lors de l’inscription: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // 🚪 Déconnexion
  Future<void> logout() async {
    try {
      print('ALogout: Déconnexion...');
      final authService = ref.read(authServiceProvider);

      // Supprimer la session (token + utilisateur)
      await authService.deleteSession();

      // Nettoyer le cache Hive
      print('ALogout: Nettoyage du cache Hive...');
      final myRoutesBox = await Hive.openBox<BikeRoute>(myRoutesBoxName);
      await myRoutesBox.clear();

      final favRoutesBox = await Hive.openBox<BikeRoute>(favoriteRoutesBoxName);
      await favRoutesBox.clear();

      // Réinitialiser l’état
      state = const AuthState();
      print('ALogout: Déconnexion réussie.');
    } catch (e) {
      print('ALogout: Erreur lors de la déconnexion: $e');
      state = const AuthState();
    }
  }

  // 🔐 Connexion avec Google
  Future<bool> loginWithGoogle(String idToken, String email, String displayName) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final authService = ref.read(authServiceProvider);

      // Tentative de connexion Google avec le backend
      // Si le backend ne supporte pas encore Google Sign-In,
      // on crée une session locale temporaire
      try {
        // TODO: Implémenter l'endpoint backend pour Google Sign-In
        // final response = await authRepo.loginWithGoogle(idToken);
        // final token = response['accessToken'] as String?;

        // Pour l'instant, on crée une session locale
        // avec un token factice basé sur l'idToken Google
        final user = User(
          id: email.hashCode, // ID temporaire basé sur l'email
          username: displayName,
          email: email,
        );

        // Sauvegarder la session localement
        await authService.saveSession(idToken, user);

        // Sauvegarder aussi dans Hive pour le mode offline
        final cacheService = ref.read(cacheServiceProvider);
        await cacheService.cacheUser(user);
        print('ALoginGoogle: Utilisateur sauvegardé dans Hive pour le mode offline');

        state = state.copyWith(isLoading: false, user: user, clearError: true);
        print('ALoginGoogle: Connexion Google réussie pour $email');
        return true;
      } catch (e) {
        // Si l'appel backend échoue, on crée quand même une session locale
        print('ALoginGoogle: Backend non disponible, création session locale');

        final user = User(
          id: email.hashCode,
          username: displayName,
          email: email,
        );

        await authService.saveSession(idToken, user);

        // Sauvegarder aussi dans Hive pour le mode offline
        final cacheService = ref.read(cacheServiceProvider);
        await cacheService.cacheUser(user);

        state = state.copyWith(isLoading: false, user: user, clearError: true);
        return true;
      }
    } catch (e) {
      print('ALoginGoogle: Erreur lors de la connexion Google: $e');
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // Méthodes placeholder
  Future<void> refreshUser() async {/* Implémentation future */}
  void clearErrorMessage() {/* Implémentation future */}
}

// ------------------------------------------------------------
// 🔗 PROVIDERS GLOBAUX
// ------------------------------------------------------------
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});
