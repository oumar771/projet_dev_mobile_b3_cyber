# Organisation du Projet - GitHub Issues & Milestones

## Vue d'ensemble

Ce document présente l'organisation complète du projet sur GitHub avec une **répartition équitable** du travail entre **DEV1** et **DEV2**.

## Accès rapide

- **Issues** : https://github.com/oumar771/projet_dev_mobile_b3_cyber/issues
- **Milestones** : https://github.com/oumar771/projet_dev_mobile_b3_cyber/milestones
- **Project Board** : À créer manuellement sur GitHub (voir instructions ci-dessous)

## Milestones (Sprints)

| Sprint | Nom | Deadline | Description |
|--------|-----|----------|-------------|
| 1 | Backend Foundation | 2025-12-01 | API, authentification, base de données |
| 2 | Frontend Mobile | 2025-12-15 | Application mobile Flutter avec auth |
| 3 | Features Avancées | 2026-01-15 | Routes, commentaires, favoris, offline |
| 4 | Tests & Déploiement | 2026-02-01 | Tests, sécurité, documentation |

## Labels créés

- `backend` - Travail sur le backend Node.js/Express
- `frontend` - Travail sur le frontend Flutter
- `authentification` - Fonctionnalités d'authentification
- `database` - Base de données et modèles
- `api` - Routes et endpoints API
- `ui` - Interface utilisateur
- `offline-mode` - Mode hors connexion et synchronisation
- `tests` - Tests unitaires et d'intégration
- `documentation` - Documentation du code et guides
- `securite` - Sécurité et vulnérabilités

## Répartition des Issues

### Sprint 1 - Backend Foundation (5 issues)

| # | Issue | Assigné | Labels |
|---|-------|---------|--------|
| 1 | Configuration base de données MySQL et Sequelize | **DEV1** | backend, database |
| 2 | Créer les modèles Sequelize (User, Role, Route) | **DEV2** | backend, database |
| 3 | Implémenter l'authentification JWT | **DEV1** | backend, authentification, api |
| 4 | Système de gestion des rôles (RBAC) | **DEV2** | backend, authentification, securite |

**Total DEV1** : 2 issues | **Total DEV2** : 2 issues

---

### Sprint 2 - Frontend Mobile (4 issues)

| # | Issue | Assigné | Labels |
|---|-------|---------|--------|
| 11 | Configuration projet Flutter et dépendances | **DEV1** | frontend |
| 12 | Écrans d'authentification (Login/Register) | **DEV2** | frontend, ui, authentification |
| 13 | Service d'authentification et gestion des tokens | **DEV1** | frontend, authentification |
| 14 | Authentification Google | **DEV2** | frontend, authentification |

**Total DEV1** : 2 issues | **Total DEV2** : 2 issues

---

### Sprint 3 - Features Avancées (12 issues)

#### Backend (4 issues)

| # | Issue | Assigné | Labels |
|---|-------|---------|--------|
| 5 | CRUD Routes (Parcours utilisateur) | **DEV1** | backend, api |
| 6 | CRUD Commentaires | **DEV2** | backend, api |
| 7 | Système de favoris | **DEV1** | backend, api |
| 8 | Intégration API externes (météo, suggestions) | **DEV2** | backend, api |

#### Frontend (8 issues)

| # | Issue | Assigné | Labels |
|---|-------|---------|--------|
| 15 | Écran d'accueil avec carte interactive | **DEV1** | frontend, ui |
| 16 | Écran de planification de parcours | **DEV2** | frontend, ui |
| 17 | Liste des parcours (Mes parcours, Publics, Favoris) | **DEV1** | frontend, ui |
| 18 | Détails de parcours et commentaires | **DEV2** | frontend, ui |
| 19 | Mode hors connexion avec synchronisation | **DEV1** | frontend, offline-mode |
| 20 | Profil utilisateur et paramètres | **DEV2** | frontend, ui |
| 21 | Performances et analytics | **DEV1** | frontend, ui |
| 22 | Widget météo et localisation | **DEV2** | frontend |

**Total DEV1** : 6 issues | **Total DEV2** : 6 issues

---

### Sprint 4 - Tests & Déploiement (4 issues)

| # | Issue | Assigné | Labels |
|---|-------|---------|--------|
| 9 | Documentation API avec Swagger | **DEV1** | backend, documentation |
| 10 | Tests unitaires et d'intégration (Backend) | **DEV2** | backend, tests |
| 23 | Tests unitaires et widgets (Frontend) | **DEV1** | frontend, tests |
| 24 | Revue de sécurité et vulnérabilités | **DEV2** | backend, frontend, securite |
| 25 | Guide de déploiement et configuration | **DEV1** | documentation |

**Total DEV1** : 3 issues | **Total DEV2** : 2 issues

---

## Répartition Globale

| Développeur | Total Issues | Backend | Frontend | Documentation | Tests | Sécurité |
|-------------|--------------|---------|----------|---------------|-------|----------|
| **DEV1** | **13 issues** | 5 | 6 | 2 | 1 | 0 |
| **DEV2** | **12 issues** | 5 | 5 | 0 | 1 | 1 |

La répartition est **équilibrée** avec une différence d'une seule issue entre les deux développeurs.

## Comment créer le Project Board sur GitHub

Comme le CLI GitHub nécessite des permissions supplémentaires, vous devez créer le project board manuellement :

### Étapes :

1. Allez sur https://github.com/oumar771/projet_dev_mobile_b3_cyber
2. Cliquez sur l'onglet **"Projects"**
3. Cliquez sur **"New project"**
4. Choisissez le template **"Board"**
5. Nommez-le : **"Projet Dev Mobile B3 Cyber"**
6. Créez les colonnes suivantes :
   - **📋 Backlog** (To Do)
   - **🏗️ In Progress**
   - **👀 Review**
   - **✅ Done**

### Ajouter les issues au board :

1. Une fois le board créé, cliquez sur **"Add items"**
2. Sélectionnez toutes les 25 issues
3. Placez-les dans la colonne **"Backlog"**
4. Organisez-les par milestone (Sprint 1, 2, 3, 4)

## Workflow recommandé

### Pour chaque développeur :

1. **Prendre une issue** de votre liste (DEV1 ou DEV2)
2. **Assigner l'issue** à vous-même sur GitHub
3. **Créer une branche** : `git checkout -b feature/issue-X-nom-feature`
4. **Travailler sur la feature**
5. **Commiter régulièrement** avec des messages clairs
6. **Push la branche** : `git push origin feature/issue-X-nom-feature`
7. **Créer une Pull Request** sur GitHub
8. **Review du partenaire** (DEV1 ⟷ DEV2)
9. **Merge après validation**
10. **Fermer l'issue** et passer à la suivante

### Exemple de commandes Git :

```bash
# Prendre une issue (ex: issue #5)
git checkout -b feature/issue-5-crud-routes

# Travailler sur le code...
git add .
git commit -m "feat: Ajout des routes CRUD pour les parcours (#5)"

# Pousser la branche
git push origin feature/issue-5-crud-routes

# Sur GitHub : créer une PR et assigner l'autre dev pour review
```

## Communication

### Conventions de commit :

- `feat:` Nouvelle fonctionnalité
- `fix:` Correction de bug
- `refactor:` Refactorisation
- `test:` Ajout de tests
- `docs:` Documentation
- `style:` Formatage du code

Toujours référencer l'issue : `feat: Ajout auth JWT (#3)`

### Stand-ups quotidiens (recommandé) :

- Qu'est-ce que j'ai fait hier ?
- Qu'est-ce que je vais faire aujourd'hui ?
- Y a-t-il des blocages ?

## Suivi de l'avancement

### Sur GitHub :

- **Issues** : Voir l'état (Open/Closed)
- **Milestones** : Progression en % par sprint
- **Project Board** : Vue Kanban de l'avancement
- **Pull Requests** : Code en review

### Commandes utiles :

```bash
# Voir les issues assignées à vous
gh issue list --assignee @me

# Voir les issues d'un milestone
gh issue list --milestone "Sprint 1 - Backend Foundation"

# Voir les issues par label
gh issue list --label backend
```

## Checklist avant de considérer une issue "Done"

- [ ] Code fonctionnel et testé localement
- [ ] Tests unitaires écrits (si applicable)
- [ ] Code commenté si nécessaire
- [ ] Documentation mise à jour
- [ ] Pull Request créée et mergée
- [ ] Issue fermée sur GitHub
- [ ] Project Board mis à jour

## Ressources

- [Guide Git Flow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)
- [Writing Good Commit Messages](https://chris.beams.io/posts/git-commit/)
- [GitHub Issues Best Practices](https://github.com/wearehive/project-guidelines#git)

---

**Dernière mise à jour** : 2025-11-12
**Créé par** : Claude Code
