import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// Service de gestion de la localisation GPS
class LocationService {
  // V�rifier si les permissions de localisation sont accord�es
  Future<bool> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Obtenir la position actuelle
  Future<LatLng?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Erreur lors de la r�cup�ration de la position: $e');
      return null;
    }
  }

  // Obtenir un stream de position en temps r�el
  Stream<LatLng> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mise � jour tous les 10 m�tres
      ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }

  // Calculer la distance entre deux points (en m�tres)
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  // V�rifier si le service de localisation est activ�
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Ouvrir les param�tres de localisation
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
