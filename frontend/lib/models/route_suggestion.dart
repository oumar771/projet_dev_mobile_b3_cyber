import 'package:latlong2/latlong.dart'; // <-- Utilise LatLng de flutter_map

/*
Ce modèle correspond à la structure JSON 
que votre backend renvoie maintenant :
{
    "type": "rapide",
    "distance": "1.8",
    "duree": 5,
    "trace": [ [-0.55, 47.47], ... ]
}
*/
class RouteSuggestion {
  final String type;      // "rapide" ou "securise"
  final String distance;  // "1.8" (en km)
  final int duree;      // 5 (en minutes)
  final List<LatLng> trace; // La liste des points pour dessiner la polyline

  RouteSuggestion({
    required this.type,
    required this.distance,
    required this.duree,
    required this.trace,
  });

  factory RouteSuggestion.fromJson(Map<String, dynamic> json) {
    
    // Conversion : [longitude, latitude] -> LatLng(latitude, longitude)
    var traceCoords = (json['trace'] as List)
        .map((coord) => LatLng(
              coord[1], // Index 1 = latitude
              coord[0]  // Index 0 = longitude
            ))
        .toList();

    return RouteSuggestion(
      type: json['type'] as String,
      distance: json['distance'] as String,
      duree: json['duree'] as int,
      trace: traceCoords,
    );
  }

  // Ajouté pour permettre la comparaison (pour les ChoiceChips)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteSuggestion &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          distance == other.distance &&
          duree == other.duree;

  @override
  int get hashCode => type.hashCode ^ distance.hashCode ^ duree.hashCode;
}