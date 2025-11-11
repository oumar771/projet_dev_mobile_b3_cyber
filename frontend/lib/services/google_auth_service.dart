import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service d'authentification Google
///
/// Gère la connexion et déconnexion avec Google Sign-In
class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Configuration pour le web avec FedCM
    signInOption: kIsWeb ? SignInOption.standard : SignInOption.standard,
  );

  /// Connexion avec Google
  ///
  /// Sur le web, utilise signInSilently() en priorité puis signIn() en fallback
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      debugPrint('GOOGLE_AUTH: Tentative de connexion...');

      // D'abord, essayer de se connecter silencieusement
      GoogleSignInAccount? account = await _googleSignIn.signInSilently(
        suppressErrors: true,
      );

      // Si aucun compte connecté, lancer la connexion interactive
      if (account == null) {
        debugPrint('GOOGLE_AUTH: Aucune session active, lancement de la connexion interactive...');
        account = await _googleSignIn.signIn();
      }

      if (account != null) {
        debugPrint('GOOGLE_AUTH: Connexion réussie pour ${account.email}');
        debugPrint('GOOGLE_AUTH: Nom: ${account.displayName}');
        debugPrint('GOOGLE_AUTH: Photo: ${account.photoUrl}');
      } else {
        debugPrint('GOOGLE_AUTH: Connexion annulée par l\'utilisateur');
      }

      return account;
    } catch (error) {
      debugPrint('GOOGLE_AUTH: Erreur lors de la connexion: $error');
      rethrow; // Relancer l'erreur pour qu'elle soit gérée par l'appelant
    }
  }

  /// Obtenir l'utilisateur actuellement connecté
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Obtenir le token d'authentification Google
  Future<String?> getIdToken() async {
    try {
      final GoogleSignInAccount? account = _googleSignIn.currentUser;
      if (account == null) {
        debugPrint('GOOGLE_AUTH: Aucun utilisateur connecté');
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      // Sur le web, on peut avoir seulement accessToken
      // Dans ce cas, on utilise l'accessToken comme idToken
      if (auth.idToken != null) {
        debugPrint('GOOGLE_AUTH: idToken obtenu');
        return auth.idToken;
      } else if (auth.accessToken != null) {
        debugPrint('GOOGLE_AUTH: Utilisation de l\'accessToken (pas d\'idToken disponible sur web)');
        return auth.accessToken;
      } else {
        debugPrint('GOOGLE_AUTH: Aucun token disponible');
        return null;
      }
    } catch (error) {
      debugPrint('GOOGLE_AUTH: Erreur lors de la récupération du token: $error');
      return null;
    }
  }

  /// Obtenir le token d'accès Google
  Future<String?> getAccessToken() async {
    try {
      final GoogleSignInAccount? account = _googleSignIn.currentUser;
      if (account == null) return null;

      final GoogleSignInAuthentication auth = await account.authentication;
      return auth.accessToken;
    } catch (error) {
      debugPrint('GOOGLE_AUTH: Erreur lors de la récupération du token d\'accès: $error');
      return null;
    }
  }

  /// Déconnexion de Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('GOOGLE_AUTH: Déconnexion réussie');
    } catch (error) {
      debugPrint('GOOGLE_AUTH: Erreur lors de la déconnexion: $error');
    }
  }

  /// Vérifier si un utilisateur est connecté
  bool isSignedIn() {
    return _googleSignIn.currentUser != null;
  }

  /// Déconnexion complète (y compris du compte Google)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      debugPrint('GOOGLE_AUTH: Déconnexion complète réussie');
    } catch (error) {
      debugPrint('GOOGLE_AUTH: Erreur lors de la déconnexion complète: $error');
    }
  }

  /// Stream pour écouter les changements de connexion
  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;
}
