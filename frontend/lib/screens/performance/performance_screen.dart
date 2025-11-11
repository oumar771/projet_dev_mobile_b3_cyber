import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../providers/network_provider.dart';
import '../../models/performance.dart';
import '../../widgets/performance/comparison_chart.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen> {
  List<Performance> _performances = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPerformances();
  }

  Future<void> _loadPerformances() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cacheService = ref.read(cacheServiceProvider);
      final performanceRepo = ref.read(performanceRepositoryProvider);
      final isOnline = ref.read(isOnlineProvider);

      // 1. Charger depuis le cache
      final cachedPerformances = await cacheService.loadPerformancesFromCache();
      if (cachedPerformances.isNotEmpty) {
        setState(() => _performances = cachedPerformances);
      }

      // 2. Si en ligne, rafraîchir depuis l'API
      if (isOnline) {
        try {
          final apiPerformances = await performanceRepo.getUserPerformances();
          await cacheService.cachePerformances(apiPerformances);
          setState(() => _performances = apiPerformances);
        } catch (e) {
          debugPrint('Erreur API performances: $e');
          // Si l'API échoue mais qu'on a du cache, on garde le cache
          if (_performances.isEmpty) {
            setState(() => _errorMessage = 'Erreur lors du chargement des performances: $e');
          }
        }
      } else {
        // Mode hors ligne
        if (_performances.isEmpty) {
          setState(() => _errorMessage = 'Mode hors ligne : aucune performance en cache');
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des performances: $e');
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPerformances,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.orange.shade700),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        onPressed: _loadPerformances,
                      ),
                    ],
                  ),
                )
              : _performances.isEmpty
                  ? const Center(
                      child: Text('Aucune performance enregistrée'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: ComparisonChart(performances: _performances),
                    ),
    );
  }
}
