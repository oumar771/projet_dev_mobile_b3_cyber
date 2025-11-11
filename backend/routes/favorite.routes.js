const { authJwt } = require("../middleware");
const controller = require("../controllers/favorite.controller");

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
     * /api/routes/favorites:
     *   get:
     *     summary: Récupère tous les trajets favoris de l'utilisateur connecté
     *     description: Retourne la liste de tous les trajets mis en favoris par l'utilisateur.
     *     tags:
     *       - Favoris
     *     security:
     *       - x-access-token: []
     *     responses:
     *       "200":
     *         description: Liste des trajets favoris
     *       "401":
     *         description: Non autorisé.
     *       "404":
     *         description: Utilisateur non trouvé !
     */
    app.get(
        "/api/routes/favorites",
        [authJwt.verifyToken],
        controller.getFavorites
    );

    /**
     * @swagger
     * /api/routes/{id}/favorite:
     *   post:
     *     summary: Ajoute un trajet aux favoris
     *     description: Permet à l'utilisateur connecté de mettre un trajet en favori.
     *     tags:
     *       - Favoris
     *     security:
     *       - x-access-token: []
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         description: ID du trajet à mettre en favori.
     *         schema:
     *           type: integer
     *     responses:
     *       "200":
     *         description: Trajet ajouté aux favoris !
     *       "401":
     *         description: Non autorisé.
     *       "404":
     *         description: Trajet non trouvé !
     */
    app.post(
        "/api/routes/:id/favorite",
        [authJwt.verifyToken],
        controller.addFavorite
    );

    /**
     * @swagger
     * /api/routes/{id}/favorite:
     *   delete:
     *     summary: Retire un trajet des favoris
     *     description: Permet à l'utilisateur connecté de retirer un trajet de ses favoris.
     *     tags:
     *       - Favoris
     *     security:
     *       - x-access-token: []
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         description: ID du trajet à retirer des favoris.
     *         schema:
     *           type: integer
     *     responses:
     *       "200":
     *         description: Trajet retiré des favoris !
     *       "401":
     *         description: Non autorisé.
     *       "404":
     *         description: Trajet non trouvé !
     */
    app.delete(
        "/api/routes/:id/favorite",
        [authJwt.verifyToken],
        controller.removeFavorite
    );
};