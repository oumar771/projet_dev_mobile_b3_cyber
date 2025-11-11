const db = require("../models");
const Comment = db.comment;
const Route = db.route;
const User = db.user; 

// --- Fonction pour AJOUTER un commentaire à un trajet ---
exports.addComment = (req, res) => {
    // On récupère l'ID de l'utilisateur (grâce au token JWT)
    const userId = req.userId;
    // On récupère l'ID du trajet depuis l'URL (ex: /api/routes/1/comment)
    const routeId = req.params.id;
    // On récupère le texte du commentaire depuis le body
    const { text } = req.body;

    // On vérifie que le texte n'est pas vide
    if (!text) {
        return res.status(400).send({ message: "Erreur! Le commentaire ne peut pas être vide." });
    }

    // On vérifie d'abord que le trajet existe
    Route.findByPk(routeId)
        .then(route => {
            if (!route) {
                return res.status(404).send({ message: "Trajet non trouvé!" });
            }

            // Si le trajet existe, on crée le commentaire en le liant
            Comment.create({
                text: text,
                routeId: route.id, // On lie au trajet
                userId: userId     // On lie à l'utilisateur
            })
                .then(comment => {
                    // Succès ! On renvoie le commentaire créé.
                    res.status(201).send(comment);
                })
                .catch(err => {
                    res.status(500).send({ message: err.message });
                });
        })
        .catch(err => {
            res.status(500).send({ message: err.message });
        });
};
// --- (Nous ajouterons la liste des commentaires plus tard) --


// --- Fonction pour RÉCUPÉRER tous les commentaires d'un trajet ---
exports.getCommentsForRoute = (req, res) => {
    // On récupère l'ID du trajet depuis l'URL
    const routeId = req.params.id;

    // On cherche tous les commentaires qui ont ce routeId
    Comment.findAll({
        where: { routeId: routeId },
        include: [
            {
                model: db.user, // On inclut les infos de l'auteur
                as: "user",
                attributes: ["id", "username"] // On ne renvoie que l'ID et le nom de l'auteur
            }
        ],
        order: [['createdAt', 'DESC']] // On trie par date, du plus récent au plus ancien
    })
        .then(comments => {
            // Succès ! On renvoie la liste des commentaires.
            res.status(200).send(comments);
        })
        .catch(err => {
            res.status(500).send({ message: err.message });
        });
};