// lib/models/user.dart

import 'package:hive/hive.dart';

part 'user.g.dart';

/// Modèle utilisateur
@HiveType(typeId: 2)
class User {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final List<String>? roles; // NOUVEAU - Les rôles de l'utilisateur

  @HiveField(4)
  final bool isVisibleOnMap;

  @HiveField(5)
  final double? currentLat;

  @HiveField(6)
  final double? currentLon;

  @HiveField(7)
  final bool showPerformances; // Afficher les performances publiquement

  User({
    required this.id,
    required this.username,
    required this.email,
    this.roles,
    this.isVisibleOnMap = false,
    this.currentLat,
    this.currentLon,
    this.showPerformances = true, // Par défaut, performances visibles
  });

  /// Créer un User depuis un JSON (API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      roles: json['roles'] != null
          ? List<String>.from(json['roles'])
          : null,
      isVisibleOnMap: json['isVisibleOnMap'] ?? false,
      currentLat: json['currentLat']?.toDouble(),
      currentLon: json['currentLon']?.toDouble(),
      showPerformances: json['showPerformances'] ?? true,
    );
  }

  /// Convertir un User en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'roles': roles,
      'isVisibleOnMap': isVisibleOnMap,
      'currentLat': currentLat,
      'currentLon': currentLon,
      'showPerformances': showPerformances,
    };
  }

  /// Créer une copie avec modifications
  User copyWith({
    int? id,
    String? username,
    String? email,
    List<String>? roles,
    bool? isVisibleOnMap,
    double? currentLat,
    double? currentLon,
    bool? showPerformances,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      isVisibleOnMap: isVisibleOnMap ?? this.isVisibleOnMap,
      currentLat: currentLat ?? this.currentLat,
      currentLon: currentLon ?? this.currentLon,
      showPerformances: showPerformances ?? this.showPerformances,
    );
  }

  /// Vérifier si l'utilisateur a un rôle spécifique
  bool hasRole(String role) {
    return roles?.contains(role) ?? false;
  }

  /// Getters pour vérifier les rôles rapidement
  bool get isAdmin => hasRole('ROLE_ADMIN');
  bool get isModerator => hasRole('ROLE_MODERATOR');
  bool get isUser => hasRole('ROLE_USER');

  /// Obtenir le nom du rôle principal (le premier de la liste)
  String get primaryRole {
    if (roles == null || roles!.isEmpty) return 'ROLE_USER';
    return roles!.first;
  }

  /// Obtenir le nom du rôle principal sans le préfixe ROLE_
  String get primaryRoleName {
    return primaryRole.replaceFirst('ROLE_', '');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, roles: $roles, isVisibleOnMap: $isVisibleOnMap, showPerformances: $showPerformances)';
  }
}