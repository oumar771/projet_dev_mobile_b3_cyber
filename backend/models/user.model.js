module.exports = (sequelize, Sequelize) => {
    const User = sequelize.define("users", {
        username: {
            type: Sequelize.STRING
        },
        email: {
            type: Sequelize.STRING
        },
        password: {
            type: Sequelize.STRING
        },
        // ⭐ NOUVEAU : ID Google pour l'authentification Google Sign-In
        googleId: {
            type: Sequelize.STRING,
            allowNull: true,
            unique: true,
            comment: "ID Google de l'utilisateur pour Google Sign-In"
        },
        // --- DÉBUT DE NOS AJOUTS POUR L'APPLICATION VÉLO ---
        // Le "switch" pour être visible ou non sur la carte
        isVisibleOnMap: {
            type: Sequelize.BOOLEAN, // Un simple Vrai/Faux
            defaultValue: true       // Les nouveaux utilisateurs sont visibles par défaut
        },
        // La dernière latitude GPS connue de l'utilisateur
        currentLat: {
            type: Sequelize.FLOAT,   // Un nombre à virgule
            allowNull: true          // Peut être nul si on n'a jamais eu la position
        },
        // La dernière longitude GPS connue de l'utilisateur
        currentLon: {
            type: Sequelize.FLOAT,
            allowNull: true
        }
        // --- FIN DE NOS AJOUTS ---
    });
    return User;
};