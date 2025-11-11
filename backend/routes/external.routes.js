const { authJwt } = require("../middleware");
const controller = require("../controllers/external.controller");

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
     * /api/external/weather:
     *   get:
     *     summary: Récupère la météo pour des coordonnées GPS
     *     description: Appelle l'API OpenWeatherMap. Nécessite d'être authentifié.
     *     tags:
     *       - API Externes
     *     security:
     *       - x-access-token: []
     *     parameters:
     *       - in: query
     *         name: lat
     *         required: true
     *         description: "Latitude (ex: 47.47)"
     *         schema:
     *           type: number
     *       - in: query
     *         name: lon
     *         required: true
     *         description: "Longitude (ex: -0.55)"
     *         schema:
     *           type: number
     *     responses:
     *       "200":
     *         description: Renvoie l'objet JSON complet de OpenWeatherMap.
     *       "400":
     *         description: "'lat' et 'lon' sont obligatoires."
     *       "401":
     *         description: Non autorisé.
     */
    app.get(
        "/api/external/weather",
        [authJwt.verifyToken],
        controller.getWeather
    );

    /**
     * @swagger
     * /api/external/plan-route:
     *   post:
     *     summary: Calcule un itinéraire à vélo
     *     description: Appelle l'API OpenRouteService. Nécessite d'être authentifié.
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
     *                 example: [-0.55, 47.47]
     *               end:
     *                 type: array
     *                 items:
     *                   type: number
     *                 example: [-0.56, 47.48]
     *     responses:
     *       "200":
     *         description: Renvoie l'objet JSON complet de OpenRouteService (avec le tracé).
     *       "400":
     *         description: "'start' et 'end' sont obligatoires."
     *       "401":
     *         description: Non autorisé.
     */
    app.post(
        "/api/external/plan-route",
        [authJwt.verifyToken],
        controller.planRoute
    );
};
