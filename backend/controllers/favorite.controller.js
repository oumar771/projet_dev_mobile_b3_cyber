const db = require("../models");
const User = db.user;
const Route = db.route;

// --- Fonction pour AJOUTER un trajet aux favoris ---
exports.addFavorite = (req, res) => {
    // On récupère l'ID de l'utilisateur (grâce au token JWT)
    const userId = req.userId;
    // On récupère l'ID du trajet depuis l'URL (ex: /api/routes/1/favorite)
    const routeId = req.params.id;

    // On cherche d'abord le trajet en question
    Route.findByPk(routeId)
        .then(route => {
            if (!route) {
                return res.status(404).send({ message: "Trajet non trouvé!" });
            }
            // On cherche l'utilisateur
            User.findByPk(userId).then(user => {
                if (!user) {
                    return res.status(404).send({ message: "Utilisateur non trouvé!" });
                }

                // On utilise la magie de Sequelize pour lier les deux
                // grâce à la relation "favoriteRoutes" qu'on a définie dans index.js
                user.addFavoriteRoutes(route).then(() => {
                    res.send({ message: "Trajet ajouté aux favoris!" });
                });
            });
        })
        .catch(err => {
            res.status(500).send({ message: err.message });
        });
};

// --- Fonction pour RÉCUPÉRER tous les favoris d'un utilisateur ---
exports.getFavorites = (req, res) => {
    const userId = req.userId;

    User.findByPk(userId, {
        include: [{
            model: Route,
            as: "favoriteRoutes", // Utilise l'alias défini dans index.js
            through: { attributes: [] }, // Ne pas inclure les attributs de la table pivot
            include: [{
                model: User,
                as: "user",
                attributes: ["id", "username"] // Inclure l'auteur du trajet
            }]
        }]
    })
        .then(user => {
            if (!user) {
                return res.status(404).send({ message: "Utilisateur non trouvé!" });
            }
            // Retourner la liste des trajets favoris
            res.send(user.favoriteRoutes);
        })
        .catch(err => {
            res.status(500).send({ message: err.message });
        });
};

// --- Fonction pour SUPPRIMER un trajet des favoris ---
exports.removeFavorite = (req, res) => {
    const userId = req.userId;
    const routeId = req.params.id;

    // Chercher le trajet
    Route.findByPk(routeId)
        .then(route => {
            if (!route) {
                return res.status(404).send({ message: "Trajet non trouvé!" });
            }

            // Chercher l'utilisateur
            User.findByPk(userId).then(user => {
                if (!user) {
                    return res.status(404).send({ message: "Utilisateur non trouvé!" });
                }

                // Supprimer le trajet des favoris
                user.removeFavoriteRoutes(route).then(() => {
                    res.send({ message: "Trajet retiré des favoris!" });
                });
            });
        })
        .catch(err => {
            res.status(500).send({ message: err.message });
        });
};