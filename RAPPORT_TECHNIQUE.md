# Documentation Technique

# Application de Gestion de Parcours Vélo
## Projet B3 Cybersécurité - Développement Mobile

---

## 1. Introduction

Notre projet consiste en une application complète de gestion de parcours de vélo pour la ville d'Angers. L'application permet aux utilisateurs de planifier leurs trajets, de les partager avec la communauté, de les mettre en favoris et de suivre leurs performances.

Le système est composé de deux parties principales :
- **Un backend** sous forme d'API REST développée avec Node.js et Express
- **Un frontend** mobile développé avec Flutter, compatible Android, iOS, Web et Desktop

L'application nécessite une authentification sécurisée avec des tokens JWT (JSON Web Tokens). Elle propose également un mode hors connexion qui permet aux utilisateurs de continuer à utiliser l'app même sans connexion internet, avec une synchronisation automatique dès que le réseau revient.

Les principales fonctionnalités incluent :
- L'inscription et la connexion (avec support de Google Auth)
- La création et la consultation de parcours vélo
- Un système de commentaires et de favoris
- L'affichage de la météo en temps réel
- Des statistiques de performance
- Une gestion de rôles (utilisateurs, modérateurs, administrateurs)

Cette documentation présente l'architecture du projet, les différentes classes et composants, ainsi que les scénarios d'utilisation principaux.

---

## 2. Architecture Générale

Le projet suit une architecture de type **MVC (Modèle - Vue - Contrôleur)** pour le backend et une architecture **MVVM (Model-View-ViewModel)** pour le frontend Flutter.

### 2.1 Backend (API REST)

Le backend est structuré comme suit :

- **Modèles (Models)** : Gèrent les données et les relations entre les entités (User, Role, Route, Comment, Favorite)
- **Contrôleurs (Controllers)** : Contiennent la logique métier et traitent les requêtes HTTP
- **Routes** : Définissent les endpoints de l'API et les associent aux contrôleurs
- **Middlewares** : Gèrent l'authentification JWT et les vérifications de rôles

**Technologies utilisées :**
- Node.js + Express.js
- MySQL + Sequelize ORM
- JWT pour l'authentification
- Bcrypt pour le hachage des mots de passe
- Swagger pour la documentation API
- CORS pour autoriser les requêtes cross-origin

### 2.2 Frontend (Application Mobile Flutter)

Le frontend est organisé selon une architecture en couches :

- **Models** : Classes représentant les données (User, BikeRoute, Comment, Performance, Weather)
- **Providers** : Gestion de l'état global de l'application (Riverpod)
- **Services** : Communication avec le backend et gestion du cache local
- **Repositories** : Abstraction de la couche de données
- **Screens** : Interfaces utilisateur
- **Widgets** : Composants UI réutilisables

**Technologies utilisées :**
- Flutter / Dart
- Riverpod pour la gestion d'état
- Hive pour le stockage local
- HTTP pour les requêtes réseau
- Google Maps pour la cartographie
- Google Sign-In pour l'authentification OAuth

---

## 3. Diagramme de Classes (Backend)

Le backend repose sur 5 modèles principaux reliés entre eux :

### Relations entre les entités :

**User** (Utilisateur)
- id : Integer (Clé primaire)
- username : String
- email : String (unique)
- password : String (haché avec bcrypt)
- Méthodes : authentification, gestion du profil
- Relations :
  * Many-to-Many avec Role (via table user_roles)
  * One-to-Many avec Route (un utilisateur peut créer plusieurs parcours)
  * Many-to-Many avec Route via Favorite (favoris)
  * One-to-Many avec Comment (un utilisateur peut poster plusieurs commentaires)

**Role** (Rôle)
- id : Integer
- name : String ('user', 'moderator', 'admin')
- Relations :
  * Many-to-Many avec User

**Route** (Parcours vélo)
- id : Integer
- name : String
- description : String
- coordinates : Text (JSON des points GPS)
- distance : Float
- duration : Integer
- difficulty : String
- isPublic : Boolean
- userId : Integer (Foreign Key vers User)
- Relations :
  * Belongs-to User (créateur du parcours)
  * Many-to-Many avec User via Favorite
  * One-to-Many avec Comment

**Favorite** (Table pivot)
- id : Integer
- userId : Integer
- routeId : Integer
- createdAt : Date

**Comment** (Commentaire)
- id : Integer
- content : Text
- rating : Integer (1 à 5 étoiles)
- userId : Integer (Foreign Key vers User)
- routeId : Integer (Foreign Key vers Route)
- createdAt : Date
- updatedAt : Date

### Schéma des relations :

```
User ---<  user_roles  >--- Role
  |
  |-- (1:N) --> Route
  |
  |-- (N:M via Favorite) --> Route
  |
  |-- (1:N) --> Comment

Route -- (1:N) --> Comment
```

---

## 4. Cas d'Utilisation

L'application est utilisée par trois types d'acteurs :

### 4.1 Utilisateur (User)
- Créer un compte / Se connecter
- Consulter les parcours publics
- Créer ses propres parcours
- Ajouter des parcours en favoris
- Commenter et noter les parcours
- Voir ses statistiques de performance
- Utiliser l'app en mode hors connexion

### 4.2 Modérateur (Moderator)
- Toutes les fonctions d'un utilisateur
- Modérer les commentaires (supprimer les commentaires inappropriés)
- Gérer les parcours publics

### 4.3 Administrateur (Admin)
- Toutes les fonctions d'un modérateur
- Gérer les utilisateurs (consulter, supprimer)
- Accès aux statistiques globales
- Gestion des rôles

### 4.4 Diagramme de cas d'utilisation (textuel)

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│                Application Mobile                  │
│                                                     │
│  ┌───────────────────────────────────────────┐    │
│  │ S'inscrire / Se connecter                 │    │
│  │ (Google Auth disponible)                  │    │
│  └───────────────────────────────────────────┘    │
│                                                     │
│  ┌───────────────────────────────────────────┐    │
│  │ Consulter les parcours publics            │    │
│  │ - Liste avec filtres                      │    │
│  │ - Détails sur la carte                    │    │
│  │ - Météo en temps réel                     │    │
│  └───────────────────────────────────────────┘    │
│                                                     │
│  ┌───────────────────────────────────────────┐    │
│  │ Créer un nouveau parcours                 │    │
│  │ - Sélection des points sur la carte       │    │
│  │ - Ajout d'informations (nom, description) │    │
│  │ - Public ou privé                         │    │
│  └───────────────────────────────────────────┘    │
│                                                     │
│  ┌───────────────────────────────────────────┐    │
│  │ Gérer ses favoris                         │    │
│  │ - Ajouter / Retirer                       │    │
│  │ - Consulter la liste                      │    │
│  └───────────────────────────────────────────┘    │
│                                                     │
│  ┌───────────────────────────────────────────┐    │
│  │ Commenter et noter                        │    │
│  │ - Écrire un commentaire                   │    │
│  │ - Donner une note (1-5 étoiles)           │    │
│  └───────────────────────────────────────────┘    │
│                                                     │
│  ┌───────────────────────────────────────────┐    │
│  │ Mode hors connexion                       │    │
│  │ - Consultation en cache                   │    │
│  │ - Actions mises en queue                  │    │
│  │ - Synchronisation automatique             │    │
│  └───────────────────────────────────────────┘    │
│                                                     │
└─────────────────────────────────────────────────────┘
         │                           │
         ▼                           ▼
    Serveur API              Serveur Météo
    (Backend Express)        (API Externe)
```

---

## 5. Configuration de l'Environnement

Pour que le backend fonctionne correctement, il faut créer un fichier `.env` à la racine du dossier `backend/`.

**⚠️ Attention : Ce fichier ne doit JAMAIS être versionné sur Git !**

Il contient toutes les informations sensibles de l'application.

### Contenu du fichier `.env` :

```env
# Configuration de la base de données MySQL
DB_HOST=localhost
DB_PORT=3306
DB_USER=votre_utilisateur_mysql
DB_PASSWORD=votre_mot_de_passe_mysql
DB_NAME=projet_velo_angers

# Configuration JWT (JSON Web Tokens)
JWT_SECRET=votre_cle_secrete_tres_complexe_et_longue
JWT_EXPIRATION=86400

# Configuration du serveur
PORT=8080

# Configuration Google OAuth (optionnel)
GOOGLE_CLIENT_ID=votre_client_id_google.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=votre_client_secret_google

# API Météo (ex: OpenWeatherMap)
WEATHER_API_KEY=votre_cle_api_meteo
```

### Variables importantes :

- **DB_HOST, DB_USER, DB_PASSWORD, DB_NAME** : Informations de connexion à la base de données MySQL
- **JWT_SECRET** : Clé secrète pour signer les tokens JWT. Elle doit être longue et complexe pour la sécurité.
- **JWT_EXPIRATION** : Durée de validité d'un token en secondes (86400 = 24 heures)
- **PORT** : Port sur lequel le serveur écoute (par défaut 8080)

---

## 6. Scénarios Dynamiques

### 6.1 Scénario : Inscription et Connexion d'un Utilisateur

**Description :**
Un nouvel utilisateur souhaite créer un compte sur l'application.

**Déroulement :**

1. L'utilisateur ouvre l'application mobile
2. Il clique sur "S'inscrire"
3. Il remplit le formulaire (username, email, password)
4. L'app Flutter envoie une requête `POST /api/auth/signup` au backend
5. Le backend vérifie :
   - Que l'email n'existe pas déjà dans la base de données
   - Que le nom d'utilisateur est unique
6. Si OK, le backend :
   - Hache le mot de passe avec bcrypt
   - Crée l'utilisateur dans la table `users`
   - Assigne le rôle "user" par défaut
   - Renvoie une confirmation
7. L'utilisateur peut maintenant se connecter avec ses identifiants
8. Lors de la connexion (`POST /api/auth/signin`) :
   - Le backend vérifie l'email et le mot de passe
   - Si correct, il génère un token JWT signé
   - Le token est renvoyé à l'application
9. L'application stocke le token localement (Hive)
10. À chaque requête suivante, le token est envoyé dans le header `x-access-token`

**Diagramme de séquence (textuel) :**

```
Utilisateur  →  [App Flutter]  →  [Backend API]  →  [MySQL]

1. Clic "S'inscrire"
2. Saisie formulaire
3. POST /api/auth/signup (username, email, password)
                    →    Vérification email unique
                                    →    SELECT * FROM users WHERE email=?
                                    ←    Résultat vide (OK)
                    →    Hachage du password (bcrypt)
                    →    Création utilisateur
                                    →    INSERT INTO users (...)
                                    →    INSERT INTO user_roles (userId, roleId=1)
                                    ←    User créé
                    ←    {success: true, message: "User registered"}
←   Message de confirmation

4. Clic "Se connecter"
5. POST /api/auth/signin (email, password)
                    →    Recherche utilisateur
                                    →    SELECT * FROM users WHERE email=?
                                    ←    User trouvé
                    →    Vérification mot de passe (bcrypt.compare)
                    →    Génération token JWT
                    ←    {accessToken: "eyJhbGc...", user: {...}}
←   Stockage token local (Hive)
←   Redirection vers écran d'accueil
```

### 6.2 Scénario : Création d'un Parcours

**Description :**
Un utilisateur connecté crée un nouveau parcours vélo.

**Déroulement :**

1. L'utilisateur clique sur "Créer un parcours"
2. Il ouvre l'écran de planification avec une carte interactive
3. Il clique sur plusieurs points pour définir le trajet
4. Il remplit les informations :
   - Nom du parcours
   - Description
   - Difficulté (facile, moyen, difficile)
   - Public ou privé
5. Il clique sur "Enregistrer"
6. L'app envoie `POST /api/routes` avec :
   - Le token JWT dans le header
   - Les données du parcours en JSON
7. Le backend :
   - Vérifie le token JWT (middleware authJwt)
   - Extrait l'ID utilisateur du token
   - Calcule la distance et la durée estimée
   - Enregistre le parcours en base
8. Le parcours est créé et visible dans "Mes parcours"

**Cas particulier (mode hors connexion) :**
- Si l'utilisateur n'a pas de connexion internet :
  1. Le parcours est enregistré en local (Hive)
  2. Il est ajouté à la queue de synchronisation
  3. Quand la connexion revient, l'app détecte le changement
  4. La queue est vidée automatiquement : le parcours est envoyé au serveur
  5. Une fois synchronisé, le flag "en attente de sync" est retiré

### 6.3 Scénario : Livraison (Consultation) d'un Parcours Public

**Description :**
Un utilisateur consulte un parcours créé par un autre utilisateur.

**Déroulement :**

1. L'utilisateur ouvre l'onglet "Parcours publics"
2. L'app envoie `GET /api/routes/public`
3. Le backend retourne la liste des parcours publics avec leurs détails
4. L'utilisateur clique sur un parcours qui l'intéresse
5. L'écran de détails s'ouvre avec :
   - La carte interactive montrant le trajet
   - Les informations (distance, durée, difficulté)
   - Les commentaires et notes
   - La météo du point de départ (API externe)
6. L'utilisateur peut :
   - Ajouter le parcours en favoris (`POST /api/favorites`)
   - Poster un commentaire (`POST /api/comments`)
   - Voir le profil du créateur

**Diagramme de séquence simplifié :**

```
[App]  →  GET /api/routes/public
         ←  [{route1}, {route2}, ...]

[App]  →  GET /api/routes/:id
         ←  {route details + comments}

[App]  →  GET /api/external/weather?lat=...&lon=...
         ←  {temp: 15, condition: "Ensoleillé"}
```

### 6.4 Scénario : Modération par un Admin

**Description :**
Un administrateur supprime un commentaire inapproprié.

**Déroulement :**

1. L'admin se connecte avec son compte admin
2. Il consulte un parcours et voit un commentaire signalé
3. Il clique sur "Supprimer le commentaire"
4. L'app envoie `DELETE /api/comments/:id` avec le token admin
5. Le middleware authJwt vérifie :
   - Que le token est valide
   - Que l'utilisateur a le rôle "admin" ou "moderator"
6. Si OK, le commentaire est supprimé de la base
7. La liste des commentaires est rafraîchie

**Vérification des rôles (middleware) :**

Le middleware `isAdmin` ou `isModerator` vérifie les rôles dans la table `user_roles` avant d'autoriser l'action.

---

## 7. Description des Principales Classes

### 7.1 Backend

#### **SiteController** (auth.controller.js, route.controller.js, etc.)

Les contrôleurs contiennent la logique métier. Ils reçoivent les requêtes HTTP, interagissent avec les modèles, et renvoient les réponses.

**Exemples de méthodes :**
- `signup(req, res)` : Inscription d'un nouvel utilisateur
- `signin(req, res)` : Connexion et génération du token JWT
- `createRoute(req, res)` : Création d'un nouveau parcours
- `getAllRoutes(req, res)` : Récupération de tous les parcours
- `addFavorite(req, res)` : Ajout d'un favori
- `postComment(req, res)` : Ajout d'un commentaire

#### **Models** (user.model.js, route.model.js, etc.)

Les modèles définissent la structure des tables et les relations.

**User** :
- Attributs : id, username, email, password
- Méthodes Sequelize : `findOne()`, `create()`, etc.
- Relations : `belongsToMany(Role)`, `hasMany(Route)`

**Route** :
- Attributs : id, name, description, coordinates, distance, duration, difficulty, isPublic, userId
- Relations : `belongsTo(User)`, `hasMany(Comment)`, `belongsToMany(User via Favorite)`

#### **Middlewares** (authJwt.js, verifySignUp.js)

Les middlewares interceptent les requêtes avant qu'elles n'atteignent les contrôleurs.

**authJwt.js** :
- `verifyToken(req, res, next)` : Vérifie la validité du token JWT
- `isAdmin(req, res, next)` : Vérifie que l'utilisateur a le rôle "admin"
- `isModerator(req, res, next)` : Vérifie le rôle "moderator"

**verifySignUp.js** :
- `checkDuplicateUsernameOrEmail(req, res, next)` : Vérifie que l'email et le username sont uniques
- `checkRolesExisted(req, res, next)` : Vérifie que les rôles demandés existent

### 7.2 Frontend

#### **Models** (route.dart, user.dart, comment.dart)

Les classes Dart représentent les données reçues de l'API.

**BikeRoute** :
```dart
class BikeRoute {
  final int id;
  final String name;
  final String description;
  final List<LatLng> coordinates;
  final double distance;
  final int duration;
  final String difficulty;
  final bool isPublic;
  final int userId;
}
```

#### **Services** (api_service.dart, auth_service.dart, cache_service.dart)

Les services gèrent la communication avec le backend et le stockage local.

**AuthService** :
- `signup(username, email, password)` : Appelle l'API d'inscription
- `signin(email, password)` : Appelle l'API de connexion
- `logout()` : Supprime le token local
- `getStoredToken()` : Récupère le token depuis Hive

**CacheService** :
- `cacheRoute(route)` : Enregistre un parcours en local
- `getCachedRoutes()` : Récupère les parcours en cache
- `clearCache()` : Vide le cache

**OfflineQueueService** :
- `addToQueue(action)` : Ajoute une action à la file d'attente
- `processQueue()` : Exécute toutes les actions en attente quand le réseau revient

#### **Providers** (auth_provider.dart, route_provider.dart)

Les providers gèrent l'état global de l'application avec Riverpod.

**AuthProvider** :
- Garde en mémoire l'utilisateur connecté
- Notifie les widgets quand l'état d'authentification change

**RouteProvider** :
- Garde la liste des parcours
- Met à jour automatiquement l'UI quand un parcours est ajouté/supprimé

#### **Screens** (login_screen.dart, home_screen.dart, route_planning_screen.dart)

Les écrans représentent les différentes pages de l'application.

**LoginScreen** : Page de connexion avec formulaire
**HomeScreen** : Page d'accueil avec carte interactive
**RoutePlanningScreen** : Page de création de parcours
**RouteDetailsScreen** : Page de détails d'un parcours avec commentaires

---

## 8. Gestion des Données et Fichiers

### 8.1 Backend

Le backend utilise une base de données MySQL gérée avec Sequelize ORM.

**Tables principales :**
- `users` : Informations des utilisateurs
- `roles` : Liste des rôles (user, moderator, admin)
- `user_roles` : Table pivot pour la relation Many-to-Many
- `routes` : Parcours vélo
- `favorites` : Table pivot pour les favoris
- `comments` : Commentaires sur les parcours

**Synchronisation :**
Au démarrage de l'application (`app.js`), Sequelize synchronise automatiquement les modèles avec la base de données :
```javascript
db.sequelize.sync().then(() => {
    console.log('Database synced.');
});
```

### 8.2 Frontend

Le frontend utilise Hive comme base de données locale NoSQL.

**Boxes Hive :**
- `routes` : Cache des parcours consultés
- `favorites` : Liste des favoris
- `offlineQueue` : Actions en attente de synchronisation
- `user` : Informations de l'utilisateur connecté

**Avantages de Hive :**
- Très rapide (lecture/écriture en mémoire)
- Compatible avec toutes les plateformes (mobile, web, desktop)
- Pas besoin de SQL, on manipule directement des objets Dart
- Chiffrement possible pour les données sensibles

---

## 9. Règles de Gestion

### 9.1 Authentification et Sécurité

- **Un utilisateur doit être authentifié** pour créer, modifier ou supprimer des parcours
- **Les mots de passe sont hachés** avec bcrypt avant d'être stockés (jamais en clair)
- **Les tokens JWT expirent** après 24 heures (configurable dans `.env`)
- **Les tokens sont vérifiés** à chaque requête protégée par le middleware `verifyToken`
- **Les opérations sensibles** (suppression, modération) nécessitent le rôle admin/moderator

### 9.2 Parcours

- **Un parcours ne peut être modifié** que par son créateur ou par un admin
- **Un parcours privé** n'est visible que par son créateur
- **Un parcours public** est visible par tous les utilisateurs
- **La distance et la durée** sont calculées automatiquement à partir des coordonnées GPS

### 9.3 Commentaires

- **Un utilisateur peut commenter** uniquement s'il est connecté
- **Un commentaire peut être modifié** uniquement par son auteur dans les 15 minutes suivant sa création
- **Un admin ou moderator** peut supprimer n'importe quel commentaire
- **La note est obligatoire** (1 à 5 étoiles) lors de l'ajout d'un commentaire

### 9.4 Mode Hors Connexion

- **Les actions sont mises en queue** quand il n'y a pas de réseau
- **La synchronisation est automatique** dès que le réseau revient
- **Les conflits sont gérés** : la version du serveur a priorité sur la version locale
- **Un indicateur visuel** montre l'état de la connexion (connecté / hors ligne / synchronisation en cours)

---

## 10. Conclusion

Ce projet nous a permis de mettre en pratique plusieurs concepts importants du développement d'applications modernes :

### Ce que nous avons appris :

**Côté Backend :**
- La création d'une API REST sécurisée avec Express.js
- L'utilisation de Sequelize pour gérer une base de données relationnelle
- L'implémentation de l'authentification JWT
- La gestion des rôles et des permissions (RBAC)
- La documentation automatique avec Swagger

**Côté Frontend :**
- Le développement d'une application Flutter cross-platform
- La gestion d'état avec Riverpod
- Le stockage local avec Hive
- La gestion du mode hors connexion avec synchronisation
- L'intégration de cartes interactives

**Architecture et Bonnes Pratiques :**
- Séparation des responsabilités (MVC, MVVM)
- Code modulaire et réutilisable
- Gestion des erreurs et des cas limites
- Sécurité des données (hachage, tokens, CORS)

### Améliorations possibles :

- Ajouter un système de notifications push
- Implémenter un chat entre utilisateurs
- Ajouter des challenges et des badges
- Intégrer un système de tracking GPS en temps réel pendant le trajet
- Ajouter des statistiques plus détaillées (calories brûlées, dénivelé, etc.)
- Mettre en place un système de recommandations de parcours basé sur l'IA

### Difficultés rencontrées :

- La gestion du mode hors connexion et des conflits de synchronisation
- L'optimisation des performances avec de nombreux parcours sur la carte
- La compatibilité cross-platform (surtout pour la géolocalisation)
- La gestion des permissions (caméra, localisation) sur différents OS

Ce projet nous a vraiment fait progresser en développement full-stack et nous avons maintenant une bonne base pour créer des applications complètes et professionnelles.

---

**Projet réalisé dans le cadre du cursus B3 Cybersécurité**
**Année 2025 - Groupe Oumar & Binôme**

