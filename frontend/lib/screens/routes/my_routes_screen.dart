import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/route.dart';
import '../../providers/route_providers.dart';
import '../../providers/service_providers.dart';
import '../routes/route_details_screen.dart'; // Pour la navigation

// REFACTORISÉ: Conversion en ConsumerStatefulWidget pour le TabController
class MyRoutesScreen extends ConsumerStatefulWidget {
  const MyRoutesScreen({super.key});

  @override
  _MyRoutesScreenState createState() => _MyRoutesScreenState();
}

class _MyRoutesScreenState extends ConsumerState<MyRoutesScreen>
    with SingleTickerProviderStateMixin { // Mixin requis pour le TabController
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialise le contrôleur pour 2 onglets
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper pour formater la distance (non modifié)
  String _formatDistance(double? distanceInMeters) {
    if (distanceInMeters == null) return "N/A";
    if (distanceInMeters < 1000) {
      return "${distanceInMeters.toStringAsFixed(0)} m";
    } else {
      return "${(distanceInMeters / 1000).toStringAsFixed(1)} km";
    }
  }

  @override
  // FIX 1: Suppression de 'WidgetRef ref'. 'ref' est déjà disponible
  // dans la classe ConsumerState.
  Widget build(BuildContext context) { 
    // On lit les deux providers (ref.watch fonctionne)
    final myRoutes = ref.watch(myRoutesProvider);
    final favoriteRoutes = ref.watch(favoriteRoutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes routes"),
        // AJOUT: La TabBar
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person_pin_circle), text: "Mes Créations"),
            Tab(icon: Icon(Icons.favorite), text: "Favoris"),
          ],
        ),
      ),
      // AJOUT: La TabBarView pour afficher le contenu de chaque onglet
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet 1: "Mes Créations"
          // FIX 1 (suite): 'ref' n'est plus passé en paramètre ici
          _buildMyRoutesList(context, myRoutes),
          
          // Onglet 2: "Favoris"
          // FIX 1 (suite): 'ref' n'est plus passé en paramètre ici
          _buildFavoritesList(context, favoriteRoutes),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------
  // WIDGET POUR L'ONGLET "MES CRÉATIONS" (avec suppression)
  // -----------------------------------------------------------------
  // FIX 1 (suite): Suppression de 'WidgetRef ref' des paramètres
  Widget _buildMyRoutesList(BuildContext context, List<BikeRoute> routes) {
    
    if (routes.isEmpty) {
      return const Center(
        child: Text(
          "Vous n'avez pas encore enregistré de route.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];

        return Dismissible(
          key: ValueKey(route.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),

          // --- Confirmation (NON MODIFIÉ) ---
          confirmDismiss: (direction) async {
            // ... (logique de confirmation identique)
            final result = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirmation'),
                  content: Text('Voulez-vous vraiment supprimer "${route.name}" ?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('ANNULER'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('SUPPRIMER', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );
            return result == true;
          },

          // --- onDismissed (NON MODIFIÉ) ---
          onDismissed: (direction) async {
            if (!context.mounted) return;
            try {
              // 1. Appeler l'API (ref.read fonctionne)
              await ref.read(routeRepositoryProvider).deleteRoute(route.id);
              // 2. Mettre à jour le StateProvider
              final newList = ref.read(myRoutesProvider).where((r) => r.id != route.id).toList();
              ref.read(myRoutesProvider.notifier).state = newList;
              
              // 3. Mettre à jour le cache
              // (Ceci causera l'erreur 2, voir ci-dessous)
              await ref.read(cacheServiceProvider).cacheMyRoutes(newList);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${route.name} a été supprimé."), backgroundColor: Colors.green),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Erreur lors de la suppression: ${e.toString()}"), backgroundColor: Colors.red),
              );
            }
          },

          // --- ListTile ---
          child: _buildRouteListTile(context, route),
        );
      },
    );
  }

  // -----------------------------------------------------------------
  // NOUVEAU WIDGET POUR L'ONGLET "FAVORIS"
  // -----------------------------------------------------------------
  // FIX 1 (suite): Suppression de 'WidgetRef ref' des paramètres
  Widget _buildFavoritesList(BuildContext context, List<BikeRoute> routes) {
    
    if (routes.isEmpty) {
      return const Center(
        child: Text(
          "Vous n'avez pas encore de favoris.\nAppuyez sur le cœur sur une route publique.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: routes.length,
      itemBuilder: (context, index) {
        final route = routes[index];
        return _buildRouteListTile(context, route);
      },
    );
  }


  // -----------------------------------------------------------------
  // WIDGET PARTAGÉ pour la ListTile
  // -----------------------------------------------------------------
  Widget _buildRouteListTile(BuildContext context, BikeRoute route) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: const Icon(Icons.route_outlined, color: Colors.blueAccent, size: 40),
        title: Text(route.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIX 3: route.description n'est pas nullable, on enlève '??'
            Text(route.description),
            const SizedBox(height: 4),
            Text(
              _formatDistance(route.distanceKm * 1000),
              style: const TextStyle(color: Colors.black54),
            )
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RouteDetailScreen(route: route),
            ),
          );
        },
      ),
    );
  }
}