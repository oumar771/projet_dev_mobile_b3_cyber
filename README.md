# Projet Mobile B3 Cyber - Application de Gestion avec Authentification JWT

Application full-stack composée d'un backend Express.js avec authentification JWT et d'un frontend Flutter mobile.

## Structure du Projet

```
projet_dev_mobile_b3_cyber/
├── backend/          # API REST Express.js avec JWT
└── frontend/         # Application mobile Flutter
```

## Backend - API REST

### Technologies
- Node.js + Express.js
- MySQL avec Sequelize ORM
- JWT pour l'authentification
- Bcrypt pour le hachage des mots de passe
- Swagger pour la documentation API

### Installation

```bash
cd backend
npm install
```

### Configuration

Créer un fichier `.env` dans le dossier backend :

```env
DB_HOST=localhost
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_NAME=your_db_name
JWT_SECRET=your_jwt_secret
```

### Démarrage

```bash
npm start
```

Le serveur démarre sur `http://localhost:3000`

### Routes API Disponibles

**Authentification :**
- `POST /api/auth/signup` - Créer un nouveau compte
- `POST /api/auth/signin` - Se connecter

**Routes protégées (nécessitent un token JWT) :**
- `GET /api/test/user` - Accessible par tous les utilisateurs authentifiés
- `GET /api/test/mod` - Accessible par les modérateurs
- `GET /api/test/admin` - Accessible par les administrateurs

## Frontend - Application Mobile Flutter

### Technologies
- Flutter / Dart
- Support multi-plateforme (Android, iOS, Web, Windows, macOS, Linux)
- Mode hors connexion avec synchronisation
- Authentification Google

### Prérequis

- Flutter SDK (dernière version stable)
- Dart SDK
- Android Studio / Xcode (pour émulateurs)

### Installation

```bash
cd frontend
flutter pub get
```

### Configuration

Voir les guides détaillés :
- [Configuration Google Auth](frontend/GOOGLE_AUTH_SETUP.md)
- [Guide Mode Hors Connexion](frontend/GUIDE_MODE_HORS_CONNEXION.md)

### Démarrage

```bash
flutter run
```

Pour un appareil spécifique :
```bash
flutter run -d <device_id>
```

## Développement

### Backend

**Tests :**
```bash
cd backend
npm test
```

**Linting :**
```bash
npm run lint
```

### Frontend

**Tests :**
```bash
cd frontend
flutter test
```

**Build Android :**
```bash
flutter build apk
```

**Build iOS :**
```bash
flutter build ios
```

## Fonctionnalités Principales

- Authentification JWT sécurisée
- Gestion des rôles utilisateurs (User, Moderator, Admin)
- CRUD complet avec protection par token
- Interface mobile responsive
- Mode hors connexion avec synchronisation automatique
- Support multi-plateforme

## Architecture

### Backend
- Architecture MVC (Model-View-Controller)
- Middleware d'authentification JWT
- Validation des données
- Gestion des erreurs centralisée

### Frontend
- Architecture propre avec séparation des couches
- State management
- Services de synchronisation
- Cache local pour mode hors connexion

## Sécurité

- Mots de passe hachés avec bcrypt
- Tokens JWT avec expiration
- Protection CORS configurée
- Validation des entrées utilisateur
- Protection contre les injections SQL (via Sequelize)

## Contribution

Ce projet est réalisé dans le cadre d'un travail académique B3 Cybersécurité.

## Licence

Projet académique - Tous droits réservés
