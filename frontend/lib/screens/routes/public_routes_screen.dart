import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/route_providers.dart';
import '../../providers/network_provider.dart';
import '../../widgets/network_status_indicator.dart';
import '../routes/route_details_screen.dart';

/// Écran des routes publiques partagées par la communauté
///
/// Affiche uniquement les routes publiques (isPublic = true)
/// Les utilisateurs peuvent consulter et lancer ces trajets
class PublicRoutesScreen extends ConsumerStatefulWidget {
  const PublicRoutesScreen({super.key});

  @override
  ConsumerState<PublicRoutesScreen> createState() => _PublicRoutesScreenState();
}

class _PublicRoutesScreenState extends ConsumerState<PublicRoutesScreen> {
  String _searchQuery = '';
  String _sortBy = 'recent'; // recent, popular, distance

  @override
  Widget build(BuildContext context) {
    final allRoutes = ref.watch(allRoutesProvider);
    final isOnline = ref.watch(isOnlineProvider);

    // Filtrer uniquement les routes publiques
    final publicRoutes = allRoutes.where((route) => route.isPublic).toList();

    // Appliquer la recherche
    var filteredRoutes = publicRoutes.where((route) {
      final query = _searchQuery.toLowerCase();
      return route.name.toLowerCase().contains(query) ||
          route.description.toLowerCase().contains(query) ||
          (route.username?.toLowerCase().contains(query) ?? false);
    }).toList();

    // Appliquer le tri
    switch (_sortBy) {
      case 'recent':
        filteredRoutes.sort((a, b) {
          if (a.createdAt == null || b.createdAt == null) return 0;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      case 'popular':
        // Pour l'instant, on trie par nom (à remplacer par nombre de likes/comments)
        filteredRoutes.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'distance':
        filteredRoutes.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
    }

    return Scaffold(
      body: Column(
        children: [
          const NetworkStatusIndicator(),

          // Header avec recherche et filtres
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Titre
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.explore,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Routes Publiques',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${publicRoutes.length} routes partagées',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Barre de recherche
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: TextField(
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher une route...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // Filtres
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        _buildFilterChip('Récentes', 'recent', Icons.access_time),
                        const SizedBox(width: 8),
                        _buildFilterChip('Populaires', 'popular', Icons.trending_up),
                        const SizedBox(width: 8),
                        _buildFilterChip('Distance', 'distance', Icons.straighten),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Liste des routes
          Expanded(
            child: filteredRoutes.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      // TODO: Rafraîchir les routes
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final route = filteredRoutes[index];
                        return _buildRouteCard(route);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.blue),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _sortBy = value);
        }
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.blue.shade700,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildRouteCard(route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RouteDetailScreen(route: route),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Entête avec avatar et auteur
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      route.username?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.username ?? 'Utilisateur',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (route.createdAt != null)
                          Text(
                            _formatDate(route.createdAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 16),

              // Nom de la route
              Text(
                route.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                route.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Statistiques
              Row(
                children: [
                  _buildStat(Icons.straighten, '${route.distanceKm.toStringAsFixed(1)} km'),
                  const SizedBox(width: 16),
                  _buildStat(Icons.location_on, '${route.waypoints.length} points'),
                  const Spacer(),

                  // Bouton Lancer - Navigation Google Maps
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (route.waypoints.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ce trajet n\'a pas de points de navigation'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      // Destination = dernier point du trajet
                      final destination = route.waypoints.last;
                      final lat = destination.latitude;
                      final lon = destination.longitude;

                      // URL Google Maps pour navigation vélo
                      final Uri googleMapsUrl = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=bicycling',
                      );

                      try {
                        if (await canLaunchUrl(googleMapsUrl)) {
                          await launchUrl(
                            googleMapsUrl,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          throw 'Impossible de lancer Google Maps';
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Lancer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Aucune route publique'
                : 'Aucune route trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Les cyclistes n\'ont pas encore partagé de routes'
                : 'Essayez une autre recherche',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}