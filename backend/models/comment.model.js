module.exports = (sequelize, Sequelize) => {
    const Comment = sequelize.define("comments", {
        // Le texte du commentaire
        text: {
            type: Sequelize.STRING,
            allowNull: false // Un commentaire ne peut pas être vide
        }
        // L'ID de l'utilisateur (userId) et l'ID du trajet (routeId)
        // seront ajoutés automatiquement par les relations.
    });

    return Comment;
};