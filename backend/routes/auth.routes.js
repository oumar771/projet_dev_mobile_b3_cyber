// backend/routes/auth.routes.js
const { verifySignUp } = require("../middleware");
const controller = require("../controllers/auth.controller");

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
     *   - name: Authentification
     *     description: Endpoints d'inscription et de connexion
     */

    /**
     * @swagger
     * /api/auth/signup:
     *   post:
     *     summary: Inscription d'un nouvel utilisateur
     *     tags:
     *       - Authentification
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               username:
     *                 type: string
     *                 example: jdoe
     *               email:
     *                 type: string
     *                 format: email
     *                 example: jdoe@example.com
     *               password:
     *                 type: string
     *                 format: password
     *                 example: Passw0rd!
     *             required:
     *               - username
     *               - email
     *               - password
     *     responses:
     *       "201":
     *         description: Utilisateur enregistré avec succès
     *       "400":
     *         description: Erreur de validation ou compte déjà existant
     */
    app.post(
        "/api/auth/signup",
        [verifySignUp.checkDuplicateUsernameOrEmail, verifySignUp.checkRolesExisted],
        controller.signup
    );

    /**
     * @swagger
     * /api/auth/signin:
     *   post:
     *     summary: Connexion d'un utilisateur
     *     tags:
     *       - Authentification
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               username:
     *                 type: string
     *                 example: jdoe
     *               password:
     *                 type: string
     *                 format: password
     *                 example: Passw0rd!
     *             required:
     *               - username
     *               - password
     *     responses:
     *       "200":
     *         description: Connexion réussie, renvoie le token JWT
     *       "401":
     *         description: Mot de passe invalide
     *       "404":
     *         description: Utilisateur non trouvé
     */
    app.post("/api/auth/signin", controller.signin);

    /**
     * @swagger
     * /api/auth/google:
     *   post:
     *     summary: Connexion avec Google Sign-In
     *     tags:
     *       - Authentification
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               idToken:
     *                 type: string
     *                 description: Token ID de Google
     *             required:
     *               - idToken
     *     responses:
     *       "200":
     *         description: Connexion Google réussie
     *       "400":
     *         description: Token invalide
     */
    app.post("/api/auth/google", controller.googleSignIn);
};