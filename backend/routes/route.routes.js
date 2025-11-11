// backend/routes/route.routes.js
const { authJwt } = require("../middleware");
const routeController = require("../controllers/route.controller");
const externalController = require("../controllers/external.controller");

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
     *   - name: Trajets
     *     description: Gestion des trajets (CRUD)
     *   - name: API Externes
     *     description: Routes pour météo et calcul d'itinéraire
     */

    // =========================
    // TRAJETS CRUD
    // =========================

    /**
     * @swagger
     * /api/routes:
     *   post:
     *     summary: Crée un nouveau trajet
     *     description: Permet à un utilisateur connecté d'enregistrer un trajet.
     *     tags:
     *       - Trajets
     *     security:
     *       - x-access-token: []
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               name:
     *                 type: string
     *               description:
     *                 type: string
     *               isPublic:
     *                 type: boolean
     *               waypoints:
     *                 type: array
     *                 items:
     *                   type: object
     *                   properties:
     *                     lat:
     *                       type: number
     *                     lon:
     *                       type: number
     *             required:
     *               - name
     *               - waypoints
     *     responses:
     *       "201":
     *         description: Trajet créé avec succès
     *       "400":
     *         description: Requête invalide
     *       "401":
     *         description: Non autorisé
     */
    app.post("/api/routes", [authJwt.verifyToken], routeController.createRoute);

    /**
     * @swagger
     * /api/routes:
     *   get:
     *     summary: Récupère tous les trajets publics
     *     description: Accessible sans authentification.
     *     tags:
     *       - Trajets
     *     responses:
     *       "200":
     *         description: Liste des trajets publics
     */
    app.get("/api/routes", routeController.getPublicRoutes);

    /**
     * @swagger
     * /api/routes/myroutes:
     *   get:
     *     summary: Récupère les trajets de l'utilisateur connecté
     *     tags:
     *       - Trajets
     *     security:
     *       - x-access-token: []
     *     responses:
     *       "200":
     *         description: Liste des trajets de l'utilisateur
     *       "401":
     *         description: Non autorisé
     */
    app.get("/api/routes/myroutes", [authJwt.verifyToken], routeController.getMyRoutes);

    /**
     * @swagger
     * /api/routes/{id}:
     *   get:
     *     summary: Récupère les détails d'un trajet spécifique
     *     tags:
     *       - Trajets
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema:
     *           type: integer
     *     responses:
     *       "200":
     *         description: Détails du trajet
     *       "404":
     *         description: Trajet non trouvé
     */
    app.get("/api/routes/:id", routeController.getRouteById);

    /**
     * @swagger
     * /api/routes/{id}:
     *   put:
     *     summary: Met à jour un trajet existant
     *     tags:
     *       - Trajets
     *     security:
     *       - x-access-token: []
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema:
     *           type: integer
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               name:
     *                 type: string
     *               description:
     *                 type: string
     *               isPublic:
     *                 type: boolean
     *               waypoints:
     *                 type: array
     *                 items:
     *                   type: object
     *                   properties:
     *                     lat:
     *                       type: number
     *                     lon:
     *                       type: number
     *     responses:
     *       "200":
     *         description: Trajet mis à jour
     *       "400":
     *         description: Requête invalide
     *       "401":
     *         description: Non autorisé
     *       "404":
     *         description: Trajet non trouvé
     */
    app.put("/api/routes/:id", [authJwt.verifyToken], routeController.updateRoute);

    /**
     * @swagger
     * /api/routes/{id}:
     *   delete:
     *     summary: Supprime un trajet existant
     *     tags:
     *       - Trajets
     *     security:
     *       - x-access-token: []
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema:
     *           type: integer
     *     responses:
     *       "200":
     *         description: Trajet supprimé
     *       "401":
     *         description: Non autorisé
     *       "404":
     *         description: Trajet non trouvé
     */
    app.delete("/api/routes/:id", [authJwt.verifyToken], routeController.deleteRoute);

    // =========================
    // ROUTES EXTERNES
    // =========================

    /**
     * @swagger
     * /api/external/weather:
     *   get:
     *     summary: Récupère la météo pour des coordonnées GPS
     *     tags:
     *       - API Externes
     *     security:
     *       - x-access-token: []
     *     parameters:
     *       - in: query
     *         name: lat
     *         required: true
     *         schema:
     *           type: number
     *       - in: query
     *         name: lon
     *         required: true
     *         schema:
     *           type: number
     *     responses:
     *       "200":
     *         description: Objet météo
     *       "400":
     *         description: Paramètres manquants
     *       "401":
     *         description: Non autorisé
     */
    app.get("/api/external/weather", [authJwt.verifyToken], externalController.getWeather);

    /**
     * @swagger
     * /api/external/plan-route:
     *   post:
     *     summary: Calcule un itinéraire à vélo
     *     tags:
     *       - API Externes
     *     security:
     *       - x-access-token: []
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               start:
     *                 type: array
     *                 items:
     *                   type: number
     *               end:
     *                 type: array
     *                 items:
     *                   type: number
     *     responses:
     *       "200":
     *         description: Itinéraire calculé
     *       "400":
     *         description: Paramètres manquants
     *       "401":
     *         description: Non autorisé
     */
    app.post("/api/external/plan-route", [authJwt.verifyToken], externalController.planRoute);
};
