import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart'; // <-- 1. AJOUTÉ
import 'package:latlong2/latlong.dart';

part 'route.g.dart'; // (Ceci est correct)

// 2. AJOUTÉ: Annotation pour la classe (ID 0)
@HiveType(typeId: 0)
class BikeRoute {
  // 3. AJOUTÉ: Annotations pour les champs
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final bool isPublic;

  @HiveField(4)
  final List<LatLng> waypoints;

  @HiveField(5)
  final int userId;

  @HiveField(6)
  final String? username;

  @HiveField(7)
  final DateTime? createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  BikeRoute({
    required this.id,
    required this.name,
    required this.description,
    this.isPublic = true,
    required this.waypoints,
    required this.userId,
    this.username,
    this.createdAt,
    this.updatedAt,
  });

  // --- Votre logique 'fromJson' (INCHANGÉE) ---
  factory BikeRoute.fromJson(Map<String, dynamic> json) {
    List<LatLng> parseWaypoints(dynamic waypointsData) {
      if (waypointsData == null) return [];

      List<dynamic> pointsList;
      if (waypointsData is String) {
        try {
          pointsList = jsonDecode(waypointsData) as List;
        } catch (e) {
          print("Erreur de décodage des waypoints: $e");
          pointsList = [];
        }
      } else if (waypointsData is List) {
        pointsList = waypointsData;
      } else {
        return [];
      }

      return pointsList.map((point) {
        if (point is Map<String, dynamic>) {
          double lat = (point['lat'] ?? point['latitude'] ?? 0.0).toDouble();
          double lng = (point['lng'] ?? point['lon'] ?? point['longitude'] ?? 0.0).toDouble();
          return LatLng(lat, lng);
        }
        return const LatLng(0, 0);
      }).toList();
    }

    return BikeRoute(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isPublic: json['isPublic'] ?? true,
      waypoints: parseWaypoints(json['waypoints']),
      userId: json['userId'] ?? 0,
      username: json['user']?['username'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // --- Votre logique 'toJson' (INCHANGÉE) ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isPublic': isPublic,
      'waypoints': waypoints.map((point) => {
        'lat': point.latitude,
        'lng': point.longitude,
      }).toList(),
      'userId': userId,
      'username': username,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // --- Votre logique 'distanceKm' (INCHANGÉE) ---
  double get distanceKm {
    if (waypoints.length < 2) return 0;
    const distance = Distance();
    double totalDistance = 0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      totalDistance += distance(waypoints[i], waypoints[i + 1]);
    }
    return totalDistance / 1000;
  }

  // --- Votre logique 'copyWith' (INCHANGÉE) ---
  BikeRoute copyWith({
    int? id,
    String? name,
    String? description,
    bool? isPublic,
    List<LatLng>? waypoints,
    int? userId,
    String? username,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BikeRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      waypoints: waypoints ?? this.waypoints,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}