# Configuration de l'authentification Google

## Problème résolu

L'erreur que vous rencontriez était due à :
1. **Client ID incorrect** : Vous utilisiez un secret client (`GOCSPX-...`) au lieu d'un Client ID
2. **Script manquant** : Le script Google Identity Services n'était pas chargé
3. **Méthode dépréciée** : Le code utilisait `signIn()` sans optimisation pour le web

## Étapes pour configurer Google Sign-In

### 1. Créer un projet Google Cloud

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Créez un nouveau projet ou sélectionnez un projet existant
3. Activez les APIs nécessaires :
   - Allez dans "APIs & Services" > "Library"
   - **IMPORTANT** : Recherchez et activez ces APIs :
     - **"People API"** (OBLIGATOIRE - permet de récupérer les infos utilisateur)
     - "Google+ API" ou "Google Identity" (optionnel)
   - Pour chaque API, cliquez sur "Enable"

### 2. Créer des identifiants OAuth 2.0

1. Allez dans "APIs & Services" > "Credentials"
2. Cliquez sur "Create Credentials" > "OAuth client ID"
3. Si demandé, configurez l'écran de consentement OAuth :
   - Type d'utilisateur : Externe
   - Remplissez les informations requises (nom de l'application, email de support, etc.)
   - Ajoutez les scopes : `email` et `profile`
   - Ajoutez des utilisateurs de test si nécessaire

### 3. Configurer le Client ID Web

1. Sélectionnez "Application web" comme type d'application
2. Donnez-lui un nom (par exemple : "Vélo Angers Web")
3. **Origines JavaScript autorisées** :
   - Pour le développement local :
     ```
     http://localhost
     http://localhost:3000
     http://localhost:8080
     ```
   - Pour la production :
     ```
     https://votre-domaine.com
     ```
4. **URI de redirection autorisées** :
   - Pour le développement local :
     ```
     http://localhost/auth/callback
     http://localhost:3000/auth/callback
     ```
   - Pour la production :
     ```
     https://votre-domaine.com/auth/callback
     ```
5. Cliquez sur "Créer"
6. **IMPORTANT** : Copiez le Client ID (il ressemble à : `123456789-abc123def456.apps.googleusercontent.com`)

### 4. Configurer le Client ID dans votre application

1. Ouvrez le fichier `web/index.html`
2. Remplacez `YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com` par votre vrai Client ID :
   ```html
   <meta name="google-signin-client_id" content="VOTRE_CLIENT_ID_ICI.apps.googleusercontent.com">
   ```

### 5. Tester l'authentification

1. Lancez votre application en mode web :
   ```bash
   flutter run -d chrome
   ```
   ou
   ```bash
   flutter run -d edge
   ```

2. Cliquez sur le bouton "Continuer avec Google"
3. Sélectionnez votre compte Google
4. Autorisez l'application à accéder à vos informations

## Format du Client ID

Le Client ID doit avoir ce format :
```
1234567890-abcdefghijklmnop.apps.googleusercontent.com
```

**NE PAS utiliser** :
- Le secret client (commence par `GOCSPX-`)
- L'ID du projet
- Un autre type d'identifiant

## Résolution des problèmes courants

### Erreur "People API has not been used" (ERREUR ACTUELLE)
- **Cause** : L'API People n'est pas activée dans votre projet Google Cloud
- **Solution RAPIDE** :
  1. Cliquez sur ce lien avec votre numéro de projet :
     ```
     https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=555355804039
     ```
  2. Cliquez sur le bouton **"Enable"** ou **"Activer"**
  3. Attendez 1-2 minutes que l'activation se propage
  4. Réessayez la connexion Google dans votre application

### Erreur "popup_closed"
- **Cause** : La popup de connexion a été fermée par l'utilisateur
- **Solution** : Réessayez la connexion

### Erreur "unauthorized_client"
- **Cause** : L'origine (localhost ou domaine) n'est pas autorisée
- **Solution** : Ajoutez votre origine dans les "Origines JavaScript autorisées" de Google Cloud Console

### Erreur "access_denied"
- **Cause** : L'utilisateur a refusé l'accès
- **Solution** : L'utilisateur doit accepter les permissions demandées

### Avertissement FedCM
- **Info** : Google migre vers FedCM (Federated Credential Management)
- **Solution** : Votre code est maintenant compatible avec FedCM

## Configuration pour Android (optionnel)

Si vous voulez aussi utiliser Google Sign-In sur Android :

1. Générez le SHA-1 de votre clé de signature :
   ```bash
   cd android
   ./gradlew signingReport
   ```

2. Dans Google Cloud Console, créez un autre OAuth client ID :
   - Type : Application Android
   - Package name : `com.example.frontend` (voir `android/app/build.gradle`)
   - SHA-1 : Collez le SHA-1 obtenu à l'étape 1

## Configuration pour iOS (optionnel)

1. Dans Google Cloud Console, créez un OAuth client ID :
   - Type : Application iOS
   - Bundle ID : `com.example.frontend` (voir `ios/Runner.xcodeproj`)

2. Téléchargez le fichier `GoogleService-Info.plist`

3. Ajoutez-le dans `ios/Runner/`

## Ressources

- [Documentation Google Sign-In pour Flutter](https://pub.dev/packages/google_sign_in)
- [Guide de migration FedCM](https://developers.google.com/identity/gsi/web/guides/fedcm-migration)
- [Console Google Cloud](https://console.cloud.google.com/)
