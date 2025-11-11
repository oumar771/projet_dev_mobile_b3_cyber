import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

// Ceci est l'adaptateur pour le TypeId 1 (ou tout autre ID unique
// que vous avez défini pour LatLng dans votre modèle BikeRoute).
// Assurez-vous que l'ID ici (typeId: 1) correspond à celui que vous
// pourriez utiliser ailleurs.

class LatLngAdapter extends TypeAdapter<LatLng> {
  // L'ID doit être unique pour chaque @HiveType.
  // Si BikeRoute est 0, LatLng peut être 1.
  @override
  final int typeId = 1;

  @override
  LatLng read(BinaryReader reader) {
    // On lit les données dans le MÊME ORDRE qu'on les a écrites
    final lat = reader.readDouble();
    final lng = reader.readDouble();
    return LatLng(lat, lng);
  }

  @override
  void write(BinaryWriter writer, LatLng obj) {
    // On écrit les deux composantes de l'objet LatLng
    writer.writeDouble(obj.latitude);
    writer.writeDouble(obj.longitude);
  }
}