import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/route.dart';
import '../../models/performance.dart';
import '../../providers/service_providers.dart';
import '../../widgets/network_status_indicator.dart';

/// Écran pour afficher les performances d'un trajet spécifique
///
/// Affiche:
/// - Historique de toutes les performances sur ce trajet
/// - Statistiques comparées (meilleur temps, vitesse moyenne, etc.)
/// - Graphiques d'évolution
class RoutePerformanceScreen extends ConsumerStatefulWidget {
  final BikeRoute route;

  const RoutePerformanceScreen({super.key, required this.route});

  @override
  ConsumerState<RoutePerformanceScreen> createState() =>
      _RoutePerformanceScreenState();
}

class _RoutePerformanceScreenState
    extends ConsumerState<RoutePerformanceScreen> {
  List<Performance> _performances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformances();
  }

  Future<void> _loadPerformances() async {
    setState(() => _isLoading = true);

    try {
      final performanceRepo = ref.read(performanceRepositoryProvider);
      // Note: Cette méthode devra être ajoutée au PerformanceRepository
      // Pour l'instant, on utilise getUserPerformances et on filtre
      final allPerformances = await performanceRepo.getUserPerformances();
      final performances = allPerformances
          .where((p) => p.routeId == widget.route.id)
          .toList();

      setState(() {
        _performances = performances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Performances - ${widget.route.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPerformances,
          ),
        ],
      ),
      body: Column(
        children: [
          const NetworkStatusIndicator(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _performances.isEmpty
                    ? _buildEmptyState()
                    : _buildPerformancesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune performance enregistrée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complétez ce trajet pour enregistrer vos performances',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformancesList() {
    // Calculer les statistiques
    final bestTime = _performances
        .reduce((a, b) => a.duration < b.duration ? a : b)
        .duration;
    final avgSpeed = _performances
            .map((p) => p.avgSpeed)
            .reduce((a, b) => a + b) /
        _performances.length;
    final maxSpeed = _performances
        .map((p) => p.maxSpeed ?? 0)
        .reduce((a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: _loadPerformances,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistiques globales
            _buildStatsCard(bestTime, avgSpeed, maxSpeed),
            const SizedBox(height: 24),

            // Graphique d'évolution (simplifiée)
            if (_performances.length >= 2) _buildPerformanceProgress(),
            const SizedBox(height: 24),

            // Titre de l'historique
            Text(
              'Historique (${_performances.length} trajets)',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Liste des performances
            ..._performances.map((performance) =>
                _buildPerformanceCard(performance)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(int bestTime, double avgSpeed, double maxSpeed) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meilleures Performances',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.timer,
                  label: 'Meilleur temps',
                  value: _formatDuration(bestTime),
                ),
                _buildStatItem(
                  icon: Icons.speed,
                  label: 'Vitesse moy.',
                  value: '${avgSpeed.toStringAsFixed(1)} km/h',
                ),
                _buildStatItem(
                  icon: Icons.flash_on,
                  label: 'Vitesse max',
                  value: '${maxSpeed.toStringAsFixed(1)} km/h',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceProgress() {
    final firstSpeed = _performances.first.avgSpeed;
    final lastSpeed = _performances.last.avgSpeed;
    final improvement = lastSpeed - firstSpeed;
    final improvementPercent = (improvement / firstSpeed * 100);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution de vos performances',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Premier trajet',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${firstSpeed.toStringAsFixed(1)} km/h',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  improvement >= 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 40,
                  color: improvement >= 0 ? Colors.green : Colors.red,
                ),
                Column(
                  children: [
                    const Text(
                      'Dernier trajet',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lastSpeed.toStringAsFixed(1)} km/h',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: improvement >= 0
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    improvement >= 0
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: improvement >= 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${improvement >= 0 ? '+' : ''}${improvementPercent.toStringAsFixed(1)}% depuis le début',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: improvement >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(Performance performance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(performance.completedAt),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${performance.distance.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Statistiques
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPerformanceStat(
                  icon: Icons.timer_outlined,
                  label: 'Durée',
                  value: performance.formattedDuration,
                ),
                _buildPerformanceStat(
                  icon: Icons.speed,
                  label: 'Vitesse moy.',
                  value: '${performance.avgSpeed.toStringAsFixed(1)} km/h',
                ),
                if (performance.maxSpeed != null)
                  _buildPerformanceStat(
                    icon: Icons.flash_on,
                    label: 'Vitesse max',
                    value: '${performance.maxSpeed!.toStringAsFixed(1)} km/h',
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Calories
            if (performance.calories != null)
              Row(
                children: [
                  const Icon(Icons.local_fire_department,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${performance.calories} calories brûlées',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${secs.toString().padLeft(2, '0')}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Hier à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
