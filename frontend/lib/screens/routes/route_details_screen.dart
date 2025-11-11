import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/route.dart';
import '../../models/comment.dart';
import '../../providers/service_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/network_provider.dart';
import '../../providers/offline_queue_provider.dart';
import '../../providers/route_providers.dart';
import '../../services/offline_queue_service.dart';
import '../../widgets/network_status_indicator.dart';

/// Écran de détail d'une route
///
/// Affiche:
/// - La carte avec le tracé
/// - Les informations de la route
/// - Les commentaires
/// - La possibilité de commenter
class RouteDetailScreen extends ConsumerStatefulWidget {
  final BikeRoute route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  final _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);

    try {
      final cacheService = ref.read(cacheServiceProvider);
      final commentRepo = ref.read(commentRepositoryProvider);
      final isOnline = ref.read(isOnlineProvider);

      // 1. Charger depuis le cache
      final cachedComments = await cacheService.loadCommentsFromCache(widget.route.id);
      if (cachedComments.isNotEmpty) {
        setState(() => _comments = cachedComments);
      }

      // 2. Si en ligne, rafraîchir depuis l'API
      if (isOnline) {
        final apiComments = await commentRepo.getCommentsByRoute(widget.route.id);
        await cacheService.cacheComments(widget.route.id, apiComments);
        setState(() => _comments = apiComments);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des commentaires: $e');
    } finally {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPostingComment = true);

    try {
      final isOnline = ref.read(isOnlineProvider);
      final commentRepo = ref.read(commentRepositoryProvider);
      final offlineQueue = ref.read(offlineQueueServiceProvider);

      if (isOnline) {
        // En ligne : poster directement
        await commentRepo.addComment(widget.route.id, text);
        _commentController.clear();
        await _loadComments(); // Recharger les commentaires

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commentaire ajouté !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Hors ligne : ajouter à la file d'attente
        await offlineQueue.addOperation(
          type: OperationType.createComment,
          data: {
            'routeId': widget.route.id,
            'text': text,
          },
        );

        _commentController.clear();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commentaire enregistré. Il sera posté lors de la prochaine connexion.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isPostingComment = false);
    }
  }

  /// Toggle le statut favori de la route
  Future<void> _toggleFavorite() async {
    try {
      final routeRepo = ref.read(routeRepositoryProvider);
      final cacheService = ref.read(cacheServiceProvider);
      final isOnline = ref.read(isOnlineProvider);
      final favoriteRoutes = ref.read(favoriteRoutesProvider);

      // Vérifier si la route est déjà dans les favoris
      final isFavorite = favoriteRoutes.any((r) => r.id == widget.route.id);

      if (!isOnline) {
        // Mode hors ligne : ajouter à la file d'attente
        final offlineQueue = ref.read(offlineQueueServiceProvider);
        await offlineQueue.addOperation(
          type: OperationType.toggleFavorite,
          data: {'routeId': widget.route.id, 'isFavorite': !isFavorite},
        );

        // Mettre à jour localement
        if (isFavorite) {
          ref.read(favoriteRoutesProvider.notifier).state =
              favoriteRoutes.where((r) => r.id != widget.route.id).toList();
          await cacheService.cacheFavoriteRoutes(ref.read(favoriteRoutesProvider));
        } else {
          final updatedFavorites = [...favoriteRoutes, widget.route];
          ref.read(favoriteRoutesProvider.notifier).state = updatedFavorites;
          await cacheService.cacheFavoriteRoutes(updatedFavorites);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFavorite
                  ? 'Retiré des favoris (sera synchronisé)'
                  : 'Ajouté aux favoris (sera synchronisé)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Mode en ligne : appel API direct
        if (isFavorite) {
          await routeRepo.removeFromFavorites(widget.route.id);
          ref.read(favoriteRoutesProvider.notifier).state =
              favoriteRoutes.where((r) => r.id != widget.route.id).toList();
        } else {
          await routeRepo.addToFavorites(widget.route.id);
          ref.read(favoriteRoutesProvider.notifier).state = [...favoriteRoutes, widget.route];
        }

        // Mettre à jour le cache
        await cacheService.cacheFavoriteRoutes(ref.read(favoriteRoutesProvider));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFavorite ? 'Retiré des favoris' : 'Ajouté aux favoris'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur toggle favori: $e');
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

  /// Toggle le statut public/privé de la route (uniquement pour le créateur)
  Future<void> _togglePublicStatus() async {
    try {
      final routeRepo = ref.read(routeRepositoryProvider);
      final cacheService = ref.read(cacheServiceProvider);
      final isOnline = ref.read(isOnlineProvider);
      final newStatus = !widget.route.isPublic;

      if (!isOnline) {
        // Mode hors ligne : ajouter à la file d'attente
        final offlineQueue = ref.read(offlineQueueServiceProvider);
        await offlineQueue.addOperation(
          type: OperationType.updateRoute,
          data: {
            'routeId': widget.route.id,
            'isPublic': newStatus,
          },
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus
                  ? 'Route mise en public (sera synchronisée)'
                  : 'Route mise en privé (sera synchronisée)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Mode en ligne : appel API direct
        await routeRepo.updateRoute(
          routeId: widget.route.id,
          isPublic: newStatus,
        );

        // Recharger les routes pour mettre à jour l'affichage
        final allRoutes = await routeRepo.getAllRoutes();
        ref.read(allRoutesProvider.notifier).state = allRoutes;
        await cacheService.cacheAllRoutes(allRoutes);

        final myRoutes = await routeRepo.getMyRoutes();
        ref.read(myRoutesProvider.notifier).state = myRoutes;
        await cacheService.cacheMyRoutes(myRoutes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus
                  ? 'Route mise en public avec succès'
                  : 'Route mise en privé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          // Revenir en arrière pour voir le changement
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Erreur toggle public/privé: $e');
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

  /// Lance Google Maps avec la navigation vers le point de départ du trajet
  Future<void> _launchGoogleMaps() async {
    try {
      // Récupérer le premier point du trajet (point de départ)
      if (widget.route.waypoints.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun point de départ disponible pour ce trajet'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final startPoint = widget.route.waypoints.first;
      final lat = startPoint.latitude;
      final lng = startPoint.longitude;

      // URL Google Maps pour la navigation
      // Format: google.navigation:q=latitude,longitude
      final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=b'); // mode=b pour vélo

      // URL alternative si Google Maps n'est pas installé
      final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=bicycling');

      // Essayer d'ouvrir Google Maps
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else if (await canLaunchUrl(webUrl)) {
        // Fallback vers la version web
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du lancement de Google Maps: $e');
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isAuthenticated;

    return Scaffold(
      body: Column(
        children: [
          const NetworkStatusIndicator(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                // AppBar avec retour et actions
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.route.name,
                      style: const TextStyle(
                        shadows: [
                          Shadow(offset: Offset(0, 1), blurRadius: 3, color: Colors.black45),
                        ],
                      ),
                    ),
                    background: _buildMap(),
                  ),
                  actions: [
                    // Bouton favori
                    Consumer(
                      builder: (context, ref, _) {
                        final favoriteRoutes = ref.watch(favoriteRoutesProvider);
                        final isFavorite = favoriteRoutes.any((r) => r.id == widget.route.id);

                        return IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : null,
                          ),
                          onPressed: _toggleFavorite,
                        );
                      },
                    ),
                    // TODO: Bouton partager
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        // TODO: Partager la route
                      },
                    ),
                  ],
                ),

                // Informations de la route
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Auteur
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                widget.route.username?.substring(0, 1).toUpperCase() ?? 'U',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.route.username ?? 'Utilisateur',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                if (widget.route.createdAt != null)
                                  Text(
                                    'Créée le ${_formatDate(widget.route.createdAt!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          widget.route.description,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade800,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Statistiques
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCard(
                              Icons.straighten,
                              '${widget.route.distanceKm.toStringAsFixed(1)} km',
                              'Distance',
                              Colors.blue,
                            ),
                            _buildStatCard(
                              Icons.location_on,
                              '${widget.route.waypoints.length}',
                              'Points',
                              Colors.orange,
                            ),
                            _buildStatCard(
                              Icons.speed,
                              '~${(widget.route.distanceKm * 4).toStringAsFixed(0)} min',
                              'Durée estimée',
                              Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Bouton pour changer le statut public/privé (uniquement pour le créateur)
                        Consumer(
                          builder: (context, ref, _) {
                            final authState = ref.watch(authProvider);
                            final isCreator = authState.user?.id == widget.route.userId;

                            if (!isCreator) return const SizedBox.shrink();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: _togglePublicStatus,
                                  icon: Icon(
                                    widget.route.isPublic ? Icons.lock_open : Icons.lock,
                                    size: 24,
                                  ),
                                  label: Text(
                                    widget.route.isPublic
                                        ? 'Mettre en privé'
                                        : 'Mettre en public',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: widget.route.isPublic ? Colors.orange : Colors.green,
                                    side: BorderSide(
                                      color: widget.route.isPublic ? Colors.orange : Colors.green,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Bouton Lancer le trajet
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _launchGoogleMaps,
                            icon: const Icon(Icons.navigation, size: 24),
                            label: const Text(
                              'Lancer le trajet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const Divider(height: 40),

                        // Section Commentaires
                        Row(
                          children: [
                            const Icon(Icons.comment, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Commentaires (${_comments.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Formulaire de commentaire (si connecté)
                        if (isAuthenticated) ...[
                          TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Partagez votre expérience...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              suffixIcon: _isPostingComment
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.send),
                                      onPressed: _postComment,
                                    ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Connectez-vous pour laisser un commentaire',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Liste des commentaires
                        if (_isLoadingComments)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_comments.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Aucun commentaire pour le moment',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._comments.map((comment) => _buildCommentCard(comment)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (widget.route.waypoints.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(child: Text('Pas de tracé disponible')),
      );
    }

    return FlutterMap(
      options: MapOptions(
        initialCenter: widget.route.waypoints.first,
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.frontend',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: widget.route.waypoints,
              color: Colors.blue,
              strokeWidth: 4,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            // Départ
            Marker(
              point: widget.route.waypoints.first,
              child: const Icon(
                Icons.location_on,
                color: Colors.green,
                size: 40,
              ),
            ),
            // Arrivée
            Marker(
              point: widget.route.waypoints.last,
              child: const Icon(
                Icons.flag,
                color: Colors.red,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Comment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    comment.username?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.username ?? 'Utilisateur',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (comment.createdAt != null)
                        Text(
                          _formatDate(comment.createdAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}