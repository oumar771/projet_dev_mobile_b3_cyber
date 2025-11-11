// backend/routes/user.routes.js
const { authJwt } = require("../middleware");
const controller = require("../controllers/user.controller");

module.exports = function (app) {
    // CORS minimal si tu n'utilises pas le middleware 'cors'
    app.use(function (req, res, next) {
        res.header("Access-Control-Allow-Origin", "*");
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Authorization, Origin, Content-Type, Accept"
        );
        res.header("Access-Control-Allow-Methods", "GET,POST,PUT,PATCH,DELETE,OPTIONS");
        if (req.method === "OPTIONS") return res.sendStatus(204);
        next();
    });

    /**
     * @swagger
     * tags:
     *   - name: Test (Squelette)
     *     description: Endpoints de test pour vérifier l'authentification
     *   - name: Utilisateur
     *     description: Endpoints liés au profil et à la localisation utilisateur
     */

    /**
     * @swagger
     * /api/test/all:
     *   get:
     *     summary: Page de test publique
     *     tags:
     *       - Test (Squelette)
     *     responses:
     *       "200":
     *         description: Renvoie "Public Content."
     */
    app.get("/api/test/all", controller.allAccess);

    /**
     * @swagger
     * /api/test/user:
     *   get:
     *     summary: Page de test pour utilisateur connecté
     *     tags:
     *       - Test (Squelette)
     *     security:
     *       - x-access-token: []
     *     responses:
     *       "200":
     *         description: Renvoie "User Content."
     *       "401":
     *         description: Non autorisé (pas de token)
     */
    app.get("/api/test/user", [authJwt.verifyToken], controller.userBoard);

    /**
     * @swagger
     * /api/test/admin:
     *   get:
     *     summary: Page de test pour admin
     *     tags:
     *       - Test (Squelette)
     *     security:
     *       - x-access-token: []
     *     responses:
     *       "200":
     *         description: Renvoie "Admin Content."
     *       "403":
     *         description: Accès refusé (rôle insuffisant)
     */
    app.get(
        "/api/test/admin",
        [authJwt.verifyToken, authJwt.isAdmin],
        controller.adminBoard
    );

    /**
     * @swagger
     * /api/user/profile:
     *   put:
     *     summary: Mettre à jour le profil de l'utilisateur
     *     description: Permet à l'utilisateur de mettre à jour sa visibilité sur la carte.
     *     tags:
     *       - Utilisateur
     *     security:
     *       - x-access-token: []
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               isVisibleOnMap:
     *                 type: boolean
     *                 example: false
     *             required:
     *               - isVisibleOnMap
     *     responses:
     *       "200":
     *         description: Profil mis à jour avec succès.
     *       "400":
     *         description: Requête invalide.
     *       "401":
     *         description: Non autorisé.
     */
    app.put("/api/user/profile", [authJwt.verifyToken], controller.updateProfile);

    /**
     * @swagger
     * /api/user/location:
     *   post:
     *     summary: Mettre à jour la localisation de l'utilisateur
     *     description: Permet à l'app d'envoyer la position GPS de l'utilisateur.
     *     tags:
     *       - Utilisateur
     *     security:
     *       - x-access-token: []
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               lat:
     *                 type: number
     *                 format: float
     *                 example: 47.478
     *               lon:
     *                 type: number
     *                 format: float
     *                 example: -0.563
     *             required:
     *               - lat
     *               - lon
     *     responses:
     *       "200":
     *         description: Localisation mise à jour.
     *       "400":
     *         description: Requête invalide.
     *       "401":
     *         description: Non autorisé.
     */
    app.post("/api/user/location", [authJwt.verifyToken], controller.updateLocation);
};
