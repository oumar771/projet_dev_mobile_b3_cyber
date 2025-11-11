module.exports = (sequelize, Sequelize) => {
    const Route = sequelize.define("routes", {
        // Nom du trajet, ex: "Balade au lac"
        name: {
            type: Sequelize.STRING,
            allowNull: false // Ne peut pas être vide
        },
        // Description du trajet
        description: {
            type: Sequelize.STRING
        },
        // Si le trajet est visible par tout le monde ou juste par le créateur
        isPublic: {
            type: Sequelize.BOOLEAN,
            defaultValue: false
        },
        // On va stocker les points GPS du trajet sous forme de texte (JSON)
        // ex: "[{lat: 47.4, lon: -0.5}, {lat: 47.5, lon: -0.6}]"
        waypoints: {
            type: Sequelize.TEXT,
            allowNull: false
        }
        // L'ID de l'utilisateur qui a créé ce trajet sera ajouté automatiquement
        // grâce à une "relation" que nous définirons plus tard.
    });

    return Route;
};