import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart'; // <-- AJOUTÉ
import 'package:path_provider/path_provider.dart'; // <-- AJOUTÉ

// --- Imports pour les adaptateurs Hive ---
// Assurez-vous que ces chemins sont corrects !
import 'models/route.dart'; // <-- AJOUTÉ (pour BikeRouteAdapter)
import 'models/user.dart'; // <-- AJOUTÉ (pour UserAdapter)
import 'models/performance.dart'; // <-- AJOUTÉ (pour PerformanceAdapter)
import 'models/comment.dart'; // <-- AJOUTÉ (pour CommentAdapter)
import 'adapters/latlng_adapter.dart'; // <-- AJOUTÉ (pour LatLngAdapter)

// --- Imports des écrans ---
import 'screens/splash_screen.dart'; // <-- MODIFIÉ (doit démarrer ici)

// REFACTORISÉ: main() doit être 'async' pour attendre Hive
void main() async {
  // 1. Assurer que les bindings natifs sont prêts (obligatoire)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialiser Hive selon la plateforme
  if (kIsWeb) {
    // Sur Web : Hive utilise IndexedDB du navigateur
    // Pas besoin de chemin, on initialise directement
    await Hive.initFlutter();
    debugPrint("HIVE: Initialisé pour le Web (IndexedDB)");
  } else {
    // Sur Mobile/Desktop : Hive utilise le système de fichiers
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    debugPrint("HIVE: Initialisé pour Mobile/Desktop (${appDocumentDir.path})");
  }

  // 3. Enregistrer les adaptateurs
  // Si vous ne le faites pas, Hive ne saura pas comment stocker vos objets.
  try {
    Hive.registerAdapter(BikeRouteAdapter());
    Hive.registerAdapter(LatLngAdapter());
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(PerformanceAdapter());
    Hive.registerAdapter(CommentAdapter());
    debugPrint("HIVE: Tous les adaptateurs enregistrés avec succès");
  } catch (e) {
    debugPrint("Attention: Erreur lors de l'enregistrement des adaptateurs Hive: $e");
    debugPrint("Remarque: C'est normal lors d'un 'Hot Reload'. Tentez un 'Hot Restart' (Touche R majuscule).");
  }

  // 4. Lancer l'application
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projet Vélo Angers',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,

      // MODIFIÉ: L'application DOIT commencer par le SplashScreen.
      // Le SplashScreen gérera la redirection (Login ou Home).
      home: const SplashScreen(),

      // (Les routes nommées ne sont plus nécessaires si 'home' est défini)
      // initialRoute: '/',
      // routes: { ... },
    );
  }
}