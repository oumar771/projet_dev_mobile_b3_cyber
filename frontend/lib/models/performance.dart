// Modèle pour les statistiques de performance

import 'package:hive/hive.dart';

part 'performance.g.dart';

@HiveType(typeId: 3)
class Performance {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int userId;

  @HiveField(2)
  final int routeId;

  @HiveField(3)
  final double distance; // en km

  @HiveField(4)
  final int duration; // en secondes

  @HiveField(5)
  final double avgSpeed; // km/h

  @HiveField(6)
  final double? maxSpeed; // km/h

  @HiveField(7)
  final int? calories;

  @HiveField(8)
  final DateTime completedAt;

  Performance({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.distance,
    required this.duration,
    required this.avgSpeed,
    this.maxSpeed,
    this.calories,
    required this.completedAt,
  });

  factory Performance.fromJson(Map<String, dynamic> json) {
    return Performance(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      routeId: json['routeId'] ?? 0,
      distance: (json['distance'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      avgSpeed: (json['avgSpeed'] ?? 0).toDouble(),
      maxSpeed: json['maxSpeed']?.toDouble(),
      calories: json['calories'],
      completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'routeId': routeId,
      'distance': distance,
      'duration': duration,
      'avgSpeed': avgSpeed,
      'maxSpeed': maxSpeed,
      'calories': calories,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  // Dur�e format�e (HH:MM:SS)
  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Pace (min/km)
  String get pace {
    if (distance == 0) return '-';
    final paceMinutes = duration / 60 / distance;
    final minutes = paceMinutes.floor();
    final seconds = ((paceMinutes - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')} min/km';
  }

  Performance copyWith({
    int? id,
    int? userId,
    int? routeId,
    double? distance,
    int? duration,
    double? avgSpeed,
    double? maxSpeed,
    int? calories,
    DateTime? completedAt,
  }) {
    return Performance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      routeId: routeId ?? this.routeId,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      avgSpeed: avgSpeed ?? this.avgSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      calories: calories ?? this.calories,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}