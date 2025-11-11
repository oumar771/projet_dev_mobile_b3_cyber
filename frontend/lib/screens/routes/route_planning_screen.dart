import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/service_providers.dart'; // Pour le routeRepositoryProvider
import '../../providers/route_providers.dart'; // Pour invalider
import '../../providers/network_provider.dart'; // Pour vérifier si online
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';

class RoutePlanningScreen extends ConsumerStatefulWidget {
  // --- NOUVEAU ---
  // On accepte le tracé calculé depuis l'écran de la carte
  final List<LatLng> waypoints;
  
  const RoutePlanningScreen({
    super.key, 
    required this.waypoints, // Requis
  });

  @override
  ConsumerState<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends ConsumerState<RoutePlanningScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = true;
  bool _isLoading = false;

  // --- MODIFIÉ ---
  // On n'a plus besoin de liste ici, on la récupère depuis 'widget.waypoints'
  // final List<LatLng> _waypoints = []; 

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createRoute() async {
    if (!_formKey.currentState!.validate()) return;
    
    // --- MODIFIÉ ---
    // On vérifie que les waypoints ont bien été passés
    if (widget.waypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Aucun tracé à sauvegarder.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final routeRepo = ref.read(routeRepositoryProvider);
      await routeRepo.createRoute(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        
        // --- MODIFIÉ ---
        // On utilise les waypoints passés au widget
        waypoints: widget.waypoints
            .map((point) => {'lat': point.latitude, 'lng': point.longitude})
            .toList(),
            
        isPublic: _isPublic,
      );

      // Rafraîchir TOUTES les listes de routes
      final cacheService = ref.read(cacheServiceProvider);
      final networkService = ref.read(networkServiceProvider);

      // Recharger depuis l'API si en ligne
      if (networkService.isOnline) {
        try {
          // Recharger les routes publiques
          final allRoutes = await routeRepo.getAllRoutes();
          ref.read(allRoutesProvider.notifier).state = allRoutes;
          await cacheService.cacheAllRoutes(allRoutes);

          // Recharger mes routes
          final myRoutes = await routeRepo.getMyRoutes();
          ref.read(myRoutesProvider.notifier).state = myRoutes;
          await cacheService.cacheMyRoutes(myRoutes);
        } catch (e) {
          debugPrint('Erreur lors du rafraîchissement: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Route créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // Revenir en arrière avec un signal indiquant qu'une route a été créée
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sauvegarder la route')), // Titre changé
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Nom de la route',
                controller: _nameController,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Description',
                controller: _descriptionController,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Requis' : null,
              ),
              const SizedBox(height: 16),

              // Carte pour la visibilité de la route
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isPublic ? Icons.public : Icons.lock,
                            color: _isPublic ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Visibilité de la route',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          _isPublic ? 'Route publique' : 'Route privée',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _isPublic
                              ? 'Visible par tous les utilisateurs dans la section "Routes Publiques"'
                              : 'Visible uniquement par vous dans "Mes Routes"',
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: _isPublic,
                        onChanged: (value) {
                          setState(() => _isPublic = value);
                        },
                        activeThumbColor: Colors.green,
                      ),
                      if (_isPublic)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Les autres cyclistes pourront voir, commenter et utiliser votre trajet',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // --- MODIFIÉ ---
              // On affiche un résumé du tracé
              Text(
                'Le tracé que vous allez sauvegarder contient ${widget.waypoints.length} points.',
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              
              const SizedBox(height: 24),
              CustomButton(
                text: 'Sauvegarder la route', // Texte changé
                onPressed: _createRoute,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
