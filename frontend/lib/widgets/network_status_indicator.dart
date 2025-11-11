import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/network_provider.dart';
import '../providers/offline_queue_provider.dart';

/// Widget indicateur de l'état de connexion réseau
///
/// Affiche une bannière en haut de l'écran lorsque l'appareil est hors ligne
/// ou lorsqu'il y a des opérations en attente de synchronisation
class NetworkStatusIndicator extends ConsumerWidget {
  const NetworkStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingCount = ref.watch(pendingOperationsCountProvider);
    final isSyncing = ref.watch(isSyncingProvider);

    // Ne rien afficher si tout est OK
    if (isOnline && pendingCount == 0 && !isSyncing) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    IconData icon;
    String message;

    if (isSyncing) {
      backgroundColor = Colors.orange.shade700;
      icon = Icons.sync;
      message = 'Synchronisation en cours...';
    } else if (!isOnline) {
      backgroundColor = Colors.red.shade700;
      icon = Icons.cloud_off;
      message = pendingCount > 0
          ? 'Hors ligne - $pendingCount opération(s) en attente'
          : 'Mode hors ligne';
    } else if (pendingCount > 0) {
      backgroundColor = Colors.amber.shade700;
      icon = Icons.sync_problem;
      message = '$pendingCount opération(s) en attente de synchronisation';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isSyncing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Badge de statut réseau compact (pour AppBar)
class NetworkStatusBadge extends ConsumerWidget {
  const NetworkStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingCount = ref.watch(pendingOperationsCountProvider);

    if (isOnline && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? Colors.amber : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.sync_problem : Icons.cloud_off,
            color: Colors.white,
            size: 16,
          ),
          if (pendingCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '$pendingCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bouton de synchronisation manuelle
class SyncButton extends ConsumerWidget {
  final VoidCallback? onSync;

  const SyncButton({super.key, this.onSync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    final pendingCount = ref.watch(pendingOperationsCountProvider);

    if (!isOnline || pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: isSyncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
      onPressed: isSyncing ? null : onSync,
      tooltip: 'Synchroniser maintenant',
    );
  }
}

/// Dialog d'information sur le mode offline
class OfflineModeDialog extends StatelessWidget {
  const OfflineModeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.red),
          SizedBox(width: 8),
          Text('Mode hors ligne'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vous êtes actuellement hors ligne.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('Vous pouvez :'),
          SizedBox(height: 8),
          Text('✓ Consulter les routes en cache'),
          Text('✓ Voir vos routes personnelles'),
          Text('✓ Naviguer sur la carte'),
          SizedBox(height: 16),
          Text('Les fonctionnalités suivantes nécessitent une connexion :'),
          SizedBox(height: 8),
          Text('✗ Créer ou modifier des routes'),
          Text('✗ Ajouter des commentaires'),
          Text('✗ Mettre à jour vos performances'),
          SizedBox(height: 16),
          Text(
            'Les modifications seront synchronisées automatiquement lorsque vous serez de nouveau en ligne.',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Compris'),
        ),
      ],
    );
  }

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const OfflineModeDialog(),
    );
  }
}