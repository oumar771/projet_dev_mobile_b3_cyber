const db = require("./models");

async function fixUsersTable() {
    try {
        console.log("🔧 Correction de la table users...");

        // Désactiver les contraintes de clés étrangères temporairement
        console.log("Désactivation des contraintes de clés étrangères...");
        await db.sequelize.query("SET FOREIGN_KEY_CHECKS=0");

        // 1. Supprimer la table existante
        console.log("Suppression de la table users...");
        await db.sequelize.query("DROP TABLE IF EXISTS `users`");

        // 2. Recréer la table proprement
        console.log("Recréation de la table users...");
        await db.sequelize.query(`
            CREATE TABLE users (
                id INT(11) NOT NULL AUTO_INCREMENT,
                username VARCHAR(255) DEFAULT NULL,
                email VARCHAR(255) DEFAULT NULL,
                password VARCHAR(255) DEFAULT NULL,
                googleId VARCHAR(255) DEFAULT NULL COMMENT 'ID Google de l\\'utilisateur pour Google Sign-In',
                isVisibleOnMap TINYINT(1) DEFAULT 1,
                currentLat FLOAT DEFAULT NULL,
                currentLon FLOAT DEFAULT NULL,
                createdAt DATETIME NOT NULL,
                updatedAt DATETIME NOT NULL,
                PRIMARY KEY (id),
                UNIQUE KEY googleId (googleId)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
        `);

        // Réactiver les contraintes de clés étrangères
        console.log("Réactivation des contraintes de clés étrangères...");
        await db.sequelize.query("SET FOREIGN_KEY_CHECKS=1");

        console.log("✅ Table users corrigée avec succès!");
        process.exit(0);
    } catch (error) {
        console.error("❌ Erreur:", error.message);
        // Toujours réactiver les contraintes en cas d'erreur
        try {
            await db.sequelize.query("SET FOREIGN_KEY_CHECKS=1");
        } catch (e) {
            // Ignorer l'erreur si la connexion est déjà fermée
        }
        process.exit(1);
    }
}

fixUsersTable();
