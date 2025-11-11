// Mod�le pour les favoris (relation user-route)
class Favorite {
  final int id;
  final int userId;
  final int routeId;
  final DateTime? createdAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.routeId,
    this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      routeId: json['routeId'] ?? 0,
      createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'routeId': routeId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
