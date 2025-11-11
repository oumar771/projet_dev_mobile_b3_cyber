const { authJwt } = require("../middleware");
const controller = require("../controllers/comment.controller");

module.exports = function (app) {
    app.use(function (req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    });

    /**
     * @swagger
     * /api/routes/{id}/comment:
     *   post:
     *     summary: Ajoute un commentaire à un trajet
     *     description: Permet à un utilisateur connecté de poster un commentaire.
     *     tags:
     *       - Commentaires
     *     security:
     *       - x-access-token: []
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         description: ID du trajet à commenter.
     *         schema:
     *           type: integer
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               text:
     *                 type: string
     *                 example: "Super trajet, je recommande !"
     *     responses:
     *       "201":
     *         description: Commentaire créé avec succès.
     *       "400":
     *         description: Le commentaire ne peut pas être vide.
     *       "401":
     *         description: Non autorisé.
     *       "404":
     *         description: Trajet non trouvé.
     */
    app.post(
        "/api/routes/:id/comment",
        [authJwt.verifyToken],
        controller.addComment
    );

    /**
     * @swagger
     * /api/routes/{id}/comments:
     *   get:
     *     summary: Récupère les commentaires d'un trajet
     *     description: Renvoie une liste de tous les commentaires pour un trajet spécifique.
     *     tags:
     *       - Commentaires
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         description: ID du trajet dont on veut les commentaires.
     *         schema:
     *           type: integer
     *     responses:
     *       "200":
     *         description: Une liste de commentaires (peut être vide).
     */
    app.get("/api/routes/:id/comments", controller.getCommentsForRoute);
};
