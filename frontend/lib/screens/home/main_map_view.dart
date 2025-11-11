import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/route_suggestion.dart';
import '../../providers/route_providers.dart';
import '../../providers/map_provider.dart';
import '../../providers/service_providers.dart';
import '../../widgets/weather_display.dart';
import '../routes/route_details_screen.dart';
import '../routes/route_planning_screen.dart';

class MainMapView extends ConsumerStatefulWidget {
  const MainMapView({super.key});

  @override
  ConsumerState<MainMapView> createState() => _MainMapViewState();
}

class _MainMapViewState extends ConsumerState<MainMapView> {
  final MapController _mapController = MapController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  bool _isSearchExpanded = false; // Pour replier/déplier la recherche

  // ... (Aucun changement dans _triggerRouteCalculation)
  Future<void> _triggerRouteCalculation() async {
    FocusScope.of(context).unfocus();

    if (_startController.text.isEmpty || _endController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un départ et une arrivée.')),
      );
      return;
    }

    ref.read(routePlanParamsProvider.notifier).state = null;
    ref.read(selectedRouteSuggestionProvider.notifier).state = null;

    try {
      final externalRepo = ref.read(externalApiRepositoryProvider);

      final startLatLng = await externalRepo.geocodeAddress(_startController.text.trim());
      if (startLatLng == null) throw Exception('Adresse de départ introuvable.');

      final endLatLng = await externalRepo.geocodeAddress(_endController.text.trim());
      if (endLatLng == null) throw Exception('Adresse d\'arrivée introuvable.');

      ref.read(routePlanParamsProvider.notifier).state = {
        'start': startLatLng,
        'end': endLatLng,
      };

      _mapController.move(startLatLng, 15.0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  // ... (Aucun changement dans _launchNavigation)
  Future<void> _launchNavigation(RouteSuggestion suggestion) async {
    final LatLng destination = suggestion.trace.last;
    final double lat = destination.latitude;
    final double lon = destination.longitude;

    // NOTE: L'URL de navigation Google Maps semble incorrecte
    // Une URL fonctionnelle ressemblerait à : 'google.navigation:q=$lat,$lon&mode=b' (vélo)
    // ou 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=bicycling'
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=bicycling'
    );
    // Ancienne URL: 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=bicycling'

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Impossible de lancer $googleMapsUrl';
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: Impossible de lancer Google Maps. $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);

    // MODIFICATION IMPORTANTE:
    // Aucune route n'est affichée par défaut
    // L'utilisateur doit activer les toggles pour voir soit ses routes, soit les routes publiques
    final myRoutes = ref.watch(myRoutesProvider);
    final showMyRoutes = ref.watch(showMyRoutesOnMapProvider);
    final showPublicRoutes = ref.watch(showPublicRoutesOnMapProvider);
    final publicRoutes = ref.watch(publicRoutesOnlyProvider);

    // Combiner les routes à afficher selon les deux toggles
    final routesToDisplay = [
      if (showMyRoutes) ...myRoutes,
      if (showPublicRoutes) ...publicRoutes,
    ];

    // NON MODIFIÉ: suggestionsAsync est toujours un FutureProvider dynamique (planification A->B).
    final suggestionsAsync = ref.watch(routeSuggestionsProvider);
    final selectedSuggestion = ref.watch(selectedRouteSuggestionProvider);
    final params = ref.watch(routePlanParamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des routes'),
        actions: [
          // Toggle pour afficher/masquer MES trajets
          Tooltip(
            message: showMyRoutes
                ? 'Masquer mes trajets'
                : 'Afficher mes trajets',
            child: IconButton(
              icon: Icon(
                showMyRoutes ? Icons.visibility : Icons.visibility_off,
                color: showMyRoutes ? Colors.blue : null,
              ),
              onPressed: () {
                ref.read(showMyRoutesOnMapProvider.notifier).state =
                    !showMyRoutes;
              },
            ),
          ),
          // Toggle pour afficher/masquer les trajets publics
          Tooltip(
            message: showPublicRoutes
                ? 'Masquer les trajets publics'
                : 'Afficher les trajets publics',
            child: IconButton(
              icon: Icon(
                showPublicRoutes ? Icons.visibility : Icons.visibility_off,
                color: showPublicRoutes ? Colors.green : null,
              ),
              onPressed: () {
                ref.read(showPublicRoutesOnMapProvider.notifier).state =
                    !showPublicRoutes;
              },
            ),
          ),
          // Bouton de localisation amélioré
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Ma position',
            onPressed: () async {
              try {
                final locationService = ref.read(locationServiceProvider);
                final position = await locationService.getCurrentPosition();

                if (position != null) {
                  // Mettre à jour la position dans le provider
                  ref.read(mapProvider.notifier).setUserLocation(position);
                  // Centrer sur l'utilisateur avec animation
                  _mapController.move(position, 16.0);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📍 Position détectée !'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Impossible de récupérer votre position'),
                        backgroundColor: Colors.orange,
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
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // REFACTORISÉ: Suppression du 'routesAsync.when()'
          // La carte est maintenant le premier élément du Stack.
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapState.center,
              initialZoom: mapState.zoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.frontend',
              ),
              PolylineLayer(
                polylines: [
                  // On utilise 'routesToDisplay' qui contient uniquement les routes à afficher
                  ...routesToDisplay.map((route) {
                    // Couleur différente pour les trajets publics vs privés
                    final color = route.isPublic
                        ? Colors.green.withValues(alpha: 0.7)
                        : Colors.blue.withValues(alpha: 0.8);
                    return Polyline(
                      points: route.waypoints,
                      strokeWidth: 4.0,
                      color: color,
                    );
                  }),
                  if (selectedSuggestion != null)
                    Polyline(
                      points: selectedSuggestion.trace,
                      strokeWidth: 6.0,
                      color: Colors.purple,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // On utilise 'routesToDisplay' pour les marqueurs aussi
                  ...routesToDisplay.expand((route) {
                    if (route.waypoints.isEmpty) return <Marker>[];
                    // Couleur du marqueur selon le type de trajet
                    final markerColor = route.isPublic ? Colors.green : Colors.red;
                    return [
                      Marker(
                        point: route.waypoints.first,
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RouteDetailScreen(route: route),
                              ),
                            );
                          },
                          child: Icon(Icons.location_on, color: markerColor, size: 40),
                        ),
                      ),
                    ];
                  }),
                  if (params?['start'] != null)
                    Marker(
                      point: params!['start']!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.flag, color: Colors.green, size: 40),
                    ),
                  if (params?['end'] != null)
                    Marker(
                      point: params!['end']!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.flag, color: Colors.red, size: 40),
                    ),
                  // NOUVEAU: Marqueur de position utilisateur
                  if (mapState.userLocation != null)
                    Marker(
                      point: mapState.userLocation!,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withValues(alpha: 0.3),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // MODIFIÉ: Barre de recherche repliable
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Card(
                margin: const EdgeInsets.all(8.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header cliquable pour replier/déplier
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isSearchExpanded = !_isSearchExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade700, Colors.blue.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.white),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Rechercher un itinéraire',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              _isSearchExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Contenu repliable
                    if (_isSearchExpanded)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _startController,
                              decoration: InputDecoration(
                                labelText: 'Départ',
                                hintText: 'ex: Place du Ralliement',
                                prefixIcon: const Icon(Icons.trip_origin),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _endController,
                              decoration: InputDecoration(
                                labelText: 'Arrivée',
                                hintText: 'ex: Gare d\'Angers',
                                prefixIcon: const Icon(Icons.location_on),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.directions_bike),
                              label: const Text('Calculer l\'itinéraire'),
                              onPressed: suggestionsAsync.isLoading
                                  ? null
                                  : _triggerRouteCalculation,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                            if (suggestionsAsync.isLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 12.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // NOUVEAU: Widget météo compact en haut à droite
          Positioned(
            top: 8,
            right: 8,
            child: Consumer(
              builder: (context, ref, _) {
                final weatherAsync = ref.watch(currentWeatherProvider);
                return weatherAsync.when(
                  data: (weather) {
                    if (weather == null) return const SizedBox.shrink();
                    return WeatherDisplay(weather: weather, compact: true);
                  },
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
          ),

          // NON MODIFIÉ: (suggestions de planification)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: suggestionsAsync.when(
              data: (suggestions) {
                if (suggestions.isEmpty) return const SizedBox.shrink();

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (ref.read(selectedRouteSuggestionProvider) == null && suggestions.isNotEmpty) {
                    ref.read(selectedRouteSuggestionProvider.notifier).state = suggestions.first;
                  }
                });

                return RouteChoiceChips(suggestions: suggestions);
              },
              loading: () => const SizedBox.shrink(),
              error: (e, stack) => Card(
                color: Colors.red[100],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Erreur: $e", style: TextStyle(color: Colors.red[900])),
                ),
              ),
            ),
          ),
        ],
      ),
      // NON MODIFIÉ (Floating Action Buttons)
      floatingActionButton: selectedSuggestion != null
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'fab_save',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoutePlanningScreen(
                    waypoints: selectedSuggestion.trace,
                  ),
                ),
              );
            },
            tooltip: 'Sauvegarder le tracé',
            child: const Icon(Icons.save),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'fab_navigate',
            onPressed: () {
              _launchNavigation(selectedSuggestion);
            },
            icon: const Icon(Icons.navigation),
            label: const Text("Démarrer"),
            backgroundColor: Colors.green,
          ),
        ],
      )
          : null,
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }
}

// ... (Aucun changement dans RouteChoiceChips)
class RouteChoiceChips extends ConsumerWidget {
  const RouteChoiceChips({required this.suggestions, super.key});

  final List<RouteSuggestion> suggestions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedRouteSuggestionProvider);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          alignment: WrapAlignment.center,
          children: suggestions.map((route) {
            final bool isSelected = selected == route;

            return ChoiceChip(
              label: Text("${route.type.toUpperCase()} (${route.duree} min - ${route.distance} km)"),
              selected: isSelected,
              onSelected: (bool wasSelected) {
                ref.read(selectedRouteSuggestionProvider.notifier).state = route;
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.purple,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              avatar: Icon(
                route.type == 'rapide' ? Icons.flash_on : Icons.shield,
                color: isSelected ? Colors.white : Colors.black54,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}