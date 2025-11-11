import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart'; // <-- Ajouté si nécessaire
import 'package:latlong2/latlong.dart';

// État de la carte
class MapState {
  final LatLng center;
  final double zoom;
  final LatLng? userLocation;
  final bool isFollowingUser;
  final bool isLoadingLocation;

  MapState({
    required this.center,
    this.zoom = 13.0,
    this.userLocation,
    this.isFollowingUser = false,
    this.isLoadingLocation = false,
  });

  MapState copyWith({
    LatLng? center,
    double? zoom,
    LatLng? userLocation,
    bool clearUserLocation = false,
    bool? isFollowingUser,
    bool? isLoadingLocation,
  }) {
    return MapState(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      userLocation:
          clearUserLocation ? null : (userLocation ?? this.userLocation),
      isFollowingUser: isFollowingUser ?? this.isFollowingUser,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
    );
  }

  // Position par défaut: Angers, France
  static LatLng get defaultCenter => const LatLng(47.478419, -0.563166);

  // Vérifie si la position utilisateur est disponible
  bool get hasUserLocation => userLocation != null;
}

// Notifier pour gérer l'état de la carte
class MapNotifier extends StateNotifier<MapState> {
  MapNotifier()
      : super(MapState(
          center: MapState.defaultCenter,
        ));

  // Définir le centre de la carte
  void setCenter(LatLng newCenter) {
    state = state.copyWith(center: newCenter);
  }

  // Définir le niveau de zoom
  void setZoom(double newZoom) {
    // clamp retourne num, on caste en double pour éviter les warnings/erreurs
    final clampedZoom = newZoom.clamp(3.0, 18.0);
    state = state.copyWith(zoom: clampedZoom);
  }

  // Définir la position de l'utilisateur
  void setUserLocation(LatLng location) {
    final shouldCenter = state.isFollowingUser;
    state = state.copyWith(
      userLocation: location,
      isLoadingLocation: false,
    );

    if (shouldCenter) {
      state = state.copyWith(center: location);
    }
  }

  // Effacer la position de l'utilisateur
  void clearUserLocation() {
    state = state.copyWith(
      clearUserLocation: true,
      isFollowingUser: false,
    );
  }

  // Centrer la carte sur l'utilisateur
  void centerOnUser() {
    final location = state.userLocation;
    if (location != null) {
      state = state.copyWith(
        center: location,
        isFollowingUser: true,
      );
    }
  }

  // Activer/désactiver le suivi de l'utilisateur
  void toggleFollowUser() {
    final isFollowing = state.isFollowingUser;
    final location = state.userLocation;

    if (!isFollowing && location != null) {
      state = state.copyWith(
        isFollowingUser: true,
        center: location,
      );
    } else {
      state = state.copyWith(isFollowingUser: false);
    }
  }

  // Définir l'état de suivi
  void setFollowUser(bool follow) {
    final location = state.userLocation;

    if (follow && location != null) {
      state = state.copyWith(
        isFollowingUser: true,
        center: location,
      );
    } else {
      state = state.copyWith(isFollowingUser: follow);
    }
  }

  // Définir l'état de chargement de la localisation
  void setLoadingLocation(bool loading) {
    state = state.copyWith(isLoadingLocation: loading);
  }

  // Centrer sur une position avec un zoom spécifique
  void centerOn(LatLng position, {double? zoom}) {
    state = state.copyWith(
      center: position,
      zoom: zoom,
      isFollowingUser: false,
    );
  }

  // Réinitialiser la carte à la position par défaut
  void resetToDefault() {
    state = MapState(
      center: MapState.defaultCenter,
      zoom: 13.0,
    );
  }

  // Zoomer sur une zone (bounds)
  void fitBounds(LatLng southWest, LatLng northEast) {
    final centerLat = (southWest.latitude + northEast.latitude) / 2;
    final centerLng = (southWest.longitude + northEast.longitude) / 2;
    final center = LatLng(centerLat, centerLng);

    final distance = const Distance().as(
      LengthUnit.Kilometer,
      southWest,
      northEast,
    );

    double zoom = 13.0;
    if (distance > 100) {
      zoom = 8.0;
    } else if (distance > 50) {
      zoom = 10.0;
    } else if (distance > 20) {
      zoom = 11.0;
    } else if (distance > 10) {
      zoom = 12.0;
    } else if (distance > 5) {
      zoom = 13.0;
    } else {
      zoom = 14.0;
    }

    state = state.copyWith(
      center: center,
      zoom: zoom,
      isFollowingUser: false,
    );
  }
}

// Provider pour la carte
final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});

// Provider pour vérifier si on suit l'utilisateur
final isFollowingUserProvider = Provider<bool>((ref) {
  final mapState = ref.watch(mapProvider);
  return mapState.isFollowingUser;
});

// Provider pour obtenir la position de l'utilisateur
final userLocationProvider = Provider<LatLng?>((ref) {
  final mapState = ref.watch(mapProvider);
  return mapState.userLocation;
});
