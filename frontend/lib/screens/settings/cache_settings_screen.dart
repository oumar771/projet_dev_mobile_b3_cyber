import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../providers/offline_queue_provider.dart';

/// Écran de gestion du cache et des paramètres hors connexion
class CacheSettingsScreen extends ConsumerStatefulWidget {
  const CacheSettingsScreen({super.key});

  @override
  ConsumerState<CacheSettingsScreen> createState() => _CacheSettingsScreenState();
}

class _CacheSettingsScreenState extends ConsumerState<CacheSettingsScreen> {
  bool _isLoading = true;
  Map<String, int>? _cacheSize;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final cacheService = ref.read(cacheServiceProvider);
      final size = await cacheService.getCacheSize();

      setState(() {
        _cacheSize = size;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le cache'),
        content: const Text(
          'Êtes-vous sûr de vouloir vider tout le cache ? '
          'L\'application devra re-télécharger les données lors de la prochaine synchronisation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vider'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final cacheService = ref.read(cacheServiceProvider);
        await cacheService.clearAll();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cache vidé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }

        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingOpsCount = ref.watch(pendingOperationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du cache'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Statistiques du cache
                  _buildCacheStatsCard(),
                  const SizedBox(height: 16),

                  // File d'attente offline
                  _buildQueueStatsCard(pendingOpsCount),
                  const SizedBox(height: 16),

                  // Actions
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildCacheStatsCard() {
    final allRoutes = _cacheSize?['allRoutes'] ?? 0;
    final myRoutes = _cacheSize?['myRoutes'] ?? 0;
    final favorites = _cacheSize?['favoriteRoutes'] ?? 0;
    final performances = _cacheSize?['performances'] ?? 0;
    final comments = _cacheSize?['comments'] ?? 0;
    final total = allRoutes + myRoutes + favorites + performances + comments;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                const Text(
                  'Statistiques du cache',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatItem('Routes publiques', allRoutes),
            _buildStatItem('Mes routes', myRoutes),
            _buildStatItem('Favoris', favorites),
            _buildStatItem('Performances', performances),
            _buildStatItem('Commentaires', comments),
            const Divider(height: 24),
            _buildStatItem('Total', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey.shade700,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isTotal ? Colors.blue.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTotal ? Colors.blue.shade700 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueStatsCard(int pendingCount) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                const Text(
                  'File d\'attente offline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatItem('Opérations en attente', pendingCount),

            if (pendingCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ces opérations seront synchronisées lors de la prochaine connexion',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cleaning_services, color: Colors.red.shade600),
                const SizedBox(width: 12),
                const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Vider tout le cache
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_forever, color: Colors.red.shade600),
              title: const Text('Vider tout le cache'),
              subtitle: const Text('Supprime toutes les données en cache'),
              onTap: _clearCache,
            ),

            // Rafraîchir les statistiques
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.refresh, color: Colors.blue.shade600),
              title: const Text('Rafraîchir'),
              subtitle: const Text('Recharger les statistiques du cache'),
              onTap: _loadData,
            ),
          ],
        ),
      ),
    );
  }
}
