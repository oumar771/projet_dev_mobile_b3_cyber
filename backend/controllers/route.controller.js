const db = require("../models");
const Route = db.route;
const User = db.user;

// --- Créer un nouveau trajet ---
exports.createRoute = (req, res) => {
    const { name, description, isPublic, waypoints } = req.body;
    const userId = req.userId;

    if (!waypoints) {
        return res.status(400).send({ message: "Erreur! 'waypoints' est obligatoire." });
    }

    let waypointsStr = waypoints;
    if (typeof waypoints === 'object') {
        waypointsStr = JSON.stringify(waypoints);
    }

    Route.create({
        name,
        description,
        isPublic: isPublic || false,
        waypoints: waypointsStr,
        userId
    })
        .then(route => res.status(201).send(route))
        .catch(err => res.status(500).send({ message: err.message }));
};

// --- Récupérer tous les trajets publics ---
exports.getPublicRoutes = (req, res) => {
    Route.findAll({
        where: { isPublic: true },
        include: [
            {
                model: User,
                as: "user",
                attributes: ["id", "username"]
            }
        ],
        order: [['createdAt', 'DESC']]
    })
        .then(routes => res.status(200).send(routes))
        .catch(err => res.status(500).send({ message: err.message }));
};

// --- Récupérer les trajets de l'utilisateur connecté ---
exports.getMyRoutes = (req, res) => {
    const userId = req.userId;

    Route.findAll({
        where: { userId },
        order: [['createdAt', 'DESC']]
    })
        .then(routes => res.status(200).send(routes))
        .catch(err => res.status(500).send({ message: err.message }));
};

// --- Récupérer un trajet spécifique par ID ---
exports.getRouteById = (req, res) => {
    const id = req.params.id;

    Route.findByPk(id, {
        include: [
            {
                model: User,
                as: "user",
                attributes: ["id", "username"]
            }
        ]
    })
        .then(route => {
            if (!route) {
                return res.status(404).send({ message: "Trajet non trouvé" });
            }
            res.status(200).send(route);
        })
        .catch(err => res.status(500).send({ message: err.message }));
};

// --- Mettre à jour un trajet (optionnel, si nécessaire) ---
exports.updateRoute = (req, res) => {
    const id = req.params.id;
    const { name, description, isPublic, waypoints } = req.body;

    Route.findByPk(id)
        .then(route => {
            if (!route) {
                return res.status(404).send({ message: "Trajet non trouvé" });
            }

            // Vérifier que l'utilisateur est propriétaire du trajet
            if (route.userId !== req.userId) {
                return res.status(403).send({ message: "Non autorisé à modifier ce trajet" });
            }

            let waypointsStr = waypoints;
            if (waypoints && typeof waypoints === 'object') {
                waypointsStr = JSON.stringify(waypoints);
            }

            return route.update({
                name: name ?? route.name,
                description: description ?? route.description,
                isPublic: isPublic ?? route.isPublic,
                waypoints: waypointsStr ?? route.waypoints
            });
        })
        .then(updatedRoute => res.status(200).send(updatedRoute))
        .catch(err => res.status(500).send({ message: err.message }));
};

// --- Supprimer un trajet ---
exports.deleteRoute = (req, res) => {
    const id = req.params.id;

    Route.findByPk(id)
        .then(route => {
            if (!route) {
                return res.status(404).send({ message: "Trajet non trouvé" });
            }

            if (route.userId !== req.userId) {
                return res.status(403).send({ message: "Non autorisé à supprimer ce trajet" });
            }

            return route.destroy();
        })
        .then(() => res.status(200).send({ message: "Trajet supprimé avec succès" }))
        .catch(err => res.status(500).send({ message: err.message }));
};
