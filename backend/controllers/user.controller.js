exports.allAccess = (req, res) => {
    res.status(200).send("Public Content.");
};
exports.userBoard = (req, res) => {
    res.status(200).send("User Content.");
};
exports.adminBoard = (req, res) => {
    res.status(200).send("Admin Content.");
};
exports.moderatorBoard = (req, res) => {
    res.status(200).send("Moderator Content.");
};

// --- DÉBUT DE NOS AJOUTS POUR L'APPLICATION VÉLO ---

// Met à jour le profil de l'utilisateur (ex: sa visibilité)
exports.updateProfile = (req, res) => {
    const db = require("../models");
    const User = db.user;

    // On récupère l'ID de l'utilisateur (grâce au token JWT)
    const userId = req.userId;

    User.update(
        {
            // On met à jour uniquement les champs envoyés dans la requête
            isVisibleOnMap: req.body.isVisibleOnMap
        },
        {
            where: { id: userId } // Pour l'utilisateur connecté
        }
    ).then(num => {
        if (num == 1) {
            res.send({ message: "Profil mis à jour avec succès." });
        } else {
            res.status(404).send({ message: `Impossible de mettre à jour le profil.` });
        }
    }).catch(err => {
        res.status(500).send({ message: err.message });
    });
};

// Met à jour la localisation GPS de l'utilisateur
exports.updateLocation = (req, res) => {
    const db = require("../models");
    const User = db.user;
    const userId = req.userId;

    User.update(
        {
            currentLat: req.body.lat, // On récupère "lat" du body
            currentLon: req.body.lon  // On récupère "lon" du body
        },
        {
            where: { id: userId }
        }
    ).then(num => {
        if (num == 1) {
            res.send({ message: "Localisation mise à jour." });
        } else {
            res.status(404).send({ message: `Impossible de mettre à jour la localisation.` });
        }
    }).catch(err => {
        res.status(500).send({ message: err.message });
    });
};
