import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

const String pendingOperationsBoxName = 'pending_operations_box';

/// Types d'opérations supportées
enum OperationType {
  createRoute,
  updateRoute,
  deleteRoute,
  createComment,
  updatePerformance,
  toggleFavorite,
  updateUserLocation,
}

/// Opération en attente de synchronisation
class PendingOperation {
  final String id;
  final OperationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;

  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      type: OperationType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.parse(json['createdAt']),
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

/// Service de gestion de la file d'attente des opérations offline
///
/// Gère les opérations qui ne peuvent pas être effectuées hors ligne
/// et les synchronise quand la connexion est rétablie
class OfflineQueueService extends ChangeNotifier {
  final List<PendingOperation> _pendingOperations = [];
  List<PendingOperation> get pendingOperations => List.unmodifiable(_pendingOperations);

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  int get pendingCount => _pendingOperations.length;
  bool get hasPendingOperations => _pendingOperations.isNotEmpty;

  /// Initialise le service et charge les opérations en attente
  Future<void> init() async {
    await _loadPendingOperations();
  }

  /// Ajoute une opération à la file d'attente
  Future<void> addOperation({
    required OperationType type,
    required Map<String, dynamic> data,
  }) async {
    final operation = PendingOperation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );

    _pendingOperations.add(operation);
    await _savePendingOperations();
    notifyListeners();

    debugPrint('Opération ajoutée à la file d\'attente: ${type.toString()}');
  }

  /// Charge les opérations en attente depuis Hive
  Future<void> _loadPendingOperations() async {
    try {
      final box = await Hive.openBox<String>(pendingOperationsBoxName);
      _pendingOperations.clear();

      for (var jsonString in box.values) {
        try {
          final json = jsonDecode(jsonString);
          _pendingOperations.add(PendingOperation.fromJson(json));
        } catch (e) {
          debugPrint('Erreur lors du décodage d\'une opération: $e');
        }
      }

      debugPrint('${_pendingOperations.length} opérations chargées de la file d\'attente');
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des opérations: $e');
    }
  }

  /// Sauvegarde les opérations en attente dans Hive
  Future<void> _savePendingOperations() async {
    try {
      final box = await Hive.openBox<String>(pendingOperationsBoxName);
      await box.clear();

      for (var operation in _pendingOperations) {
        await box.put(operation.id, jsonEncode(operation.toJson()));
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des opérations: $e');
    }
  }

  /// Supprime une opération de la file d'attente
  Future<void> removeOperation(String operationId) async {
    _pendingOperations.removeWhere((op) => op.id == operationId);
    await _savePendingOperations();
    notifyListeners();
  }

  /// Vide toute la file d'attente
  Future<void> clearAll() async {
    _pendingOperations.clear();
    final box = await Hive.openBox<String>(pendingOperationsBoxName);
    await box.clear();
    notifyListeners();
  }

  /// Synchronise toutes les opérations en attente
  ///
  /// Callback pour exécuter les opérations
  /// Returns: nombre d'opérations synchronisées avec succès
  Future<int> syncPendingOperations({
    required Future<bool> Function(PendingOperation) onExecuteOperation,
  }) async {
    if (_isSyncing) {
      debugPrint('Synchronisation déjà en cours...');
      return 0;
    }

    _isSyncing = true;
    notifyListeners();

    int successCount = 0;
    final operationsToRemove = <String>[];
    const maxRetries = 3;

    try {
      for (var operation in List.from(_pendingOperations)) {
        try {
          debugPrint('Tentative de synchronisation: ${operation.type.toString()}');

          final success = await onExecuteOperation(operation);

          if (success) {
            operationsToRemove.add(operation.id);
            successCount++;
            debugPrint('Opération synchronisée avec succès: ${operation.id}');
          } else {
            operation.retryCount++;
            if (operation.retryCount >= maxRetries) {
              debugPrint('Opération échouée après $maxRetries tentatives: ${operation.id}');
              operationsToRemove.add(operation.id);
            }
          }
        } catch (e) {
          debugPrint('Erreur lors de la synchronisation de ${operation.id}: $e');
          operation.retryCount++;
          if (operation.retryCount >= maxRetries) {
            operationsToRemove.add(operation.id);
          }
        }
      }

      // Supprimer les opérations réussies ou échouées définitivement
      for (var id in operationsToRemove) {
        await removeOperation(id);
      }

      debugPrint('Synchronisation terminée: $successCount/${ _pendingOperations.length + successCount} opérations réussies');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }

    return successCount;
  }

  /// Obtient le nombre d'opérations par type
  Map<OperationType, int> getOperationCountsByType() {
    final counts = <OperationType, int>{};
    for (var operation in _pendingOperations) {
      counts[operation.type] = (counts[operation.type] ?? 0) + 1;
    }
    return counts;
  }

  /// Obtient les opérations d'un type spécifique
  List<PendingOperation> getOperationsByType(OperationType type) {
    return _pendingOperations.where((op) => op.type == type).toList();
  }
}