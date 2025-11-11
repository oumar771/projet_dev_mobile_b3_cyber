const config = require("../config/db.config.js");
const Sequelize = require("sequelize");
// configuration database
const sequelize = new Sequelize(
    config.DB,
    config.USER,
    config.PASSWORD,
    {
        host: config.HOST,
        port: config.PORT,
        dialect: config.dialect,
        operatorsAliases: 0,
        pool: {
            max: config.pool.max,
            min: config.pool.min,
            acquire: config.pool.acquire,
            idle: config.pool.idle
        }
    }
);

// constante BDD
const db = {};
db.Sequelize = Sequelize;
db.sequelize = sequelize;
// model and table
db.user = require("../models/user.model.js")(sequelize, Sequelize);
db.role = require("../models/role.model.js")(sequelize, Sequelize);
db.route = require("../models/route.model.js")(sequelize, Sequelize);
db.favorite = require("../models/favorite.model.js")(sequelize, Sequelize);
db.comment = require("../models/comment.model.js")(sequelize, Sequelize);
// relation Many to Many between Role and Users
db.role.belongsToMany(db.user, {
    through: "user_roles",
    foreignKey: "roleId",
    otherKey: "userId"
});
db.user.belongsToMany(db.role, {
    through: "user_roles",
    foreignKey: "userId",
    otherKey: "roleId"
});
db.ROLES = ["user", "admin", "moderator"];
db.user.hasMany(db.route, {
    as: "routes" // On pourra appeler user.getRoutes()
});
db.route.belongsTo(db.user, {
    foreignKey: "userId",
    as: "user"
});
// Un utilisateur peut avoir plusieurs trajets en favori
db.user.belongsToMany(db.route, {
    through: db.favorite, // La table "pivot" est 'favorites'
    as: "favoriteRoutes"
});
db.route.belongsToMany(db.user, {
    through: db.favorite, // La table "pivot" est 'favorites'
    as: "favoritedByUsers"
});

// --- Relation Commentaires (Utilisateurs <-> Trajets) ---
// Un utilisateur peut poster plusieurs commentaires
db.user.hasMany(db.comment, {
    as: "comments"
});
db.comment.belongsTo(db.user, {
    foreignKey: "userId",
    as: "user"
});

// Un trajet peut avoir plusieurs commentaires
db.route.hasMany(db.comment, {
    as: "comments"
});
db.comment.belongsTo(db.route, {
    foreignKey: "routeId",
    as: "route"
});
module.exports = db;