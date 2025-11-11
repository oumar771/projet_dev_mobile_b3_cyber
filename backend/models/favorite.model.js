module.exports = (sequelize, Sequelize) => {
    const Favorite = sequelize.define("favorites", {
        // Il n'y a pas de champs 'id' ou 'name'
        // Sequelize va gérer les clés étrangères (userId et routeId)
        // automatiquement grâce aux relations que l'on va définir.
    });

    return Favorite;
};