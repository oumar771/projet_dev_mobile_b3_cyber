// --- Imports de base ---
const express = require('express');
const cors = require('cors');
const path = require('path');
const cookieParser = require('cookie-parser');
const logger = require('morgan');

// --- Imports pour Swagger ---
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');

// --- Initialisation de l'App ---
const app = express();


// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!! LA CORRECTION EST ICI !!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//
// var corsOptions = {
//   origin: "http://localhost:8080" // <- C'ÉTAIT L'ERREUR.
// };
// app.use(cors(corsOptions));
//
// En appelant cors() sans options, on autorise TOUTES les origines (ex: votre app Flutter).
// C'est parfait pour le développement.
app.use(cors());
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


app.use(logger('dev'));
app.use(express.json()); // pour parser le JSON
app.use(express.urlencoded({ extended: true })); // pour parser les formulaires
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

// --- Connexion à la Base de Données ---
const db = require("./models");
db.sequelize.sync().then(() => {
    console.log('Database synced.');
    // initial(); // Pas besoin de le lancer à chaque fois
});

// --- Configuration Swagger ---
const swaggerOptions = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'API Projet Vélo Angers',
            version: '1.0.0',
            description: 'Documentation de l\'API REST pour le projet B3 de vélo à Angers.',
        },
        servers: [
            {
                url: 'http://localhost:8080',
                description: 'Serveur de développement local'
            }
        ],
        components: {
            securitySchemes: {
                'x-access-token': {
                    type: 'apiKey',
                    in: 'header',
                    name: 'x-access-token'
                }
            }
        },
        security: [
            {
                'x-access-token': []
            }
        ]
    },
    // On dit à Swagger de lire les commentaires dans TOUS les fichiers .js du dossier routes
    apis: [`${__dirname}/routes/*.routes.js`],
};

const swaggerDocs = swaggerJsdoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs));
// --- Fin Configuration Swagger ---


// --- ROUTES DE NOTRE API ---
// On charge toutes nos routes d'API
require('./routes/auth.routes')(app);
require('./routes/user.routes')(app);
require('./routes/route.routes.js')(app);
require('./routes/favorite.routes.js')(app);
require('./routes/comment.routes.js')(app);
require('./routes/external.routes.js')(app);


// --- GESTION DES ERREURS 404 (pour API) ---
// Si une route n'est pas trouvée, on renvoie un JSON 404
app.use((req, res, next) => {
    res.status(404).send({
        status: 404,
        message: 'Route non trouvée!'
    });
});


// --- DÉMARRAGE DU SERVEUR ---
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}.`);
    console.log(`Swagger Docs available at http://localhost:${PORT}/api-docs`);
});

// On garde la fonction initial() si on en a besoin un jour
function initial() {
    const Role = db.role;
    Role.create({ id: 1, name: "user" });
    Role.create({ id: 2, name: "moderator" });
    Role.create({ id: 3, name: "admin" });
}

