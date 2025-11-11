// Modèle de commentaire

import 'package:hive/hive.dart';

part 'comment.g.dart';

@HiveType(typeId: 4)
class Comment {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final int userId;

  @HiveField(3)
  final int routeId;

  @HiveField(4)
  final String? username; // Nom de l'utilisateur qui a posté

  @HiveField(5)
  final DateTime? createdAt;

  Comment({
    required this.id,
    required this.text,
    required this.userId,
    required this.routeId,
    this.username,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      userId: json['userId'] ?? 0,
      routeId: json['routeId'] ?? 0,
      username: json['username'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'userId': userId,
      'routeId': routeId,
      'username': username,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  Comment copyWith({
    int? id,
    String? text,
    int? userId,
    int? routeId,
    String? username,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      text: text ?? this.text,
      userId: userId ?? this.userId,
      routeId: routeId ?? this.routeId,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}