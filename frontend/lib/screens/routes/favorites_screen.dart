import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/route_providers.dart';
import '../../widgets/route/route_card.dart';
import 'route_details_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // REFACTORISÉ: On lit directement la liste (StateProvider)
    final routes = ref.watch(favoriteRoutesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Routes favorites')),
      // REFACTORISÉ: Suppression du .when()
      body: routes.isEmpty
          ? const Center(
              child: Text(
                'Aucune route favorite.\n(Note: L\'API GET /api/routes/favorites est en 404)',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: routes.length,
              itemBuilder: (context, index) {
                final route = routes[index];
                return RouteCard(
                  route: route,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RouteDetailScreen(route: route),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}