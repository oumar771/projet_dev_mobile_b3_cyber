const db = require("../models");
const config = require("../config/auth.config");
const User = db.user;
const Role = db.role;
const Op = db.Sequelize.Op;
var jwt = require("jsonwebtoken");
var bcrypt = require("bcryptjs");
const axios = require('axios'); // ⭐ NOUVEAU : Pour appeler l'API Google

// ⭐ NOUVEAU : Client OAuth2 pour Google Sign-In
const { OAuth2Client } = require('google-auth-library');

const googleClient = new OAuth2Client(
    process.env.GOOGLE_CLIENT_ID || "555355804039-cfl4t0lksb567pukjm7nuro3bj6vgqdi.apps.googleusercontent.com"
);

// ========================================
// INSCRIPTION (SIGNUP)
// ========================================
exports.signup = (req, res) => {
    // Save User to Database
    User.create({
        username: req.body.username,
        email: req.body.email,
        password: bcrypt.hashSync(req.body.password, 8)
    })
        .then(user => {
            if (req.body.roles) {
                Role.findAll({
                    where: {
                        name: {
                            [Op.or]: req.body.roles
                        }
                    }
                }).then(roles => {
                    user.setRoles(roles).then(() => {
                        // Générer un token JWT après l'inscription
                        var token = jwt.sign({ id: user.id }, config.secret, {
                            expiresIn: 86400 // 24 hours
                        });

                        // Récupérer les rôles pour les retourner
                        user.getRoles().then(userRoles => {
                            var authorities = [];
                            for (let i = 0; i < userRoles.length; i++) {
                                authorities.push("ROLE_" + userRoles[i].name.toUpperCase());
                            }

                            res.send({
                                message: "l'utilisateur est enregistré!",
                                id: user.id,
                                username: user.username,
                                email: user.email,
                                roles: authorities,
                                accessToken: token
                            });
                        });
                    });
                });
            } else {
                // user role = 1
                user.setRoles([1]).then(() => {
                    // Générer un token JWT après l'inscription
                    var token = jwt.sign({ id: user.id }, config.secret, {
                        expiresIn: 86400 // 24 hours
                    });

                    // Récupérer les rôles pour les retourner
                    user.getRoles().then(userRoles => {
                        var authorities = [];
                        for (let i = 0; i < userRoles.length; i++) {
                            authorities.push("ROLE_" + userRoles[i].name.toUpperCase());
                        }

                        res.send({
                            message: "l'utilisateur est enregistré!",
                            id: user.id,
                            username: user.username,
                            email: user.email,
                            roles: authorities,
                            accessToken: token
                        });
                    });
                });
            }
        })
        .catch(err => {
            res.status(500).send({ message: err.message });
        });
};

// ========================================
// CONNEXION (SIGNIN)
// ========================================
exports.signin = async (req, res) => {
    User.findOne({
        where: {
            username: req.body.username
        }
    })
        .then(user => {
            if (!user) {
                return res.status(404).send({ message: "Utilisateur non trouvé." });
            }
            var passwordIsValid = bcrypt.compareSync(
                req.body.password,
                user.password
            );
            if (!passwordIsValid) {
                return res.status(401).send({
                    accessToken: null,
                    message: "Mot de passe incorrect!"
                });
            }
            var token = jwt.sign({ id: user.id }, config.secret, {
                expiresIn: 86400 // 24 hours
            });
            var authorities = [];
            user.getRoles().then(roles => {
                for (let i = 0; i < roles.length; i++) {
                    authorities.push("ROLE_" + roles[i].name.toUpperCase());
                }
                res.status(200).send({
                    id: user.id,
                    username: user.username,
                    email: user.email,
                    roles: authorities,
                    accessToken: token
                });
            });
        })
        .catch(err => {
            res.status(500).send({ message: err.message });
        });
};

// ========================================
// CONNEXION AVEC GOOGLE SIGN-IN
// Gère à la fois idToken (JWT) et accessToken (OAuth2)
// ========================================
exports.googleSignIn = async (req, res) => {
    try {
        const { idToken } = req.body;

        if (!idToken) {
            return res.status(400).send({ message: "Token Google manquant" });
        }

        console.log('🔐 Tentative de connexion Google...');
        console.log('📄 Token reçu:', idToken.substring(0, 50) + '...');

        let payload;

        // ==========================================
        // MÉTHODE 1 : Essayer de vérifier comme un idToken JWT
        // ==========================================
        try {
            const ticket = await googleClient.verifyIdToken({
                idToken: idToken,
                audience: process.env.GOOGLE_CLIENT_ID || "555355804039-cfl4t0lksb567pukjm7nuro3bj6vgqdi.apps.googleusercontent.com",
            });
            payload = ticket.getPayload();
            console.log("✅ Token vérifié comme idToken JWT");
        } catch (jwtError) {
            // ==========================================
            // MÉTHODE 2 : Si la vérification JWT échoue, 
            // c'est peut-être un accessToken OAuth2
            // On va appeler l'API Google pour récupérer les infos utilisateur
            // ==========================================
            console.log("⚠️ Échec vérification JWT, tentative comme accessToken...");
            try {
                const response = await axios.get('https://www.googleapis.com/oauth2/v2/userinfo', {
                    headers: {
                        Authorization: `Bearer ${idToken}`
                    }
                });

                payload = {
                    email: response.data.email,
                    name: response.data.name,
                    sub: response.data.id,
                    picture: response.data.picture
                };
                console.log("✅ Token vérifié comme accessToken via API Google");
            } catch (apiError) {
                console.error("❌ Erreur vérification token Google:", apiError.message);
                return res.status(400).send({
                    message: "Token Google invalide",
                    details: apiError.response?.data || apiError.message
                });
            }
        }

        // ==========================================
        // Extraire les informations utilisateur
        // ==========================================
        const { email, name, sub: googleId, picture } = payload;

        if (!email) {
            console.error("❌ Email Google non disponible");
            return res.status(400).send({ message: "Email Google non disponible" });
        }

        console.log('📧 Email Google:', email);
        console.log('👤 Nom:', name);
        console.log('🆔 Google ID:', googleId);

        // ==========================================
        // Chercher si l'utilisateur existe déjà
        // ==========================================
        let user = await User.findOne({ where: { email: email } });

        if (!user) {
            // Créer un nouvel utilisateur
            const username = name || email.split('@')[0];

            console.log('📝 Création d\'un nouvel utilisateur Google:', username);

            user = await User.create({
                username: username,
                email: email,
                password: bcrypt.hashSync(googleId, 8), // Hash du googleId comme password
                googleId: googleId
            });

            // Assigner le rôle "user" par défaut
            await user.setRoles([1]);
            console.log(`✅ Nouvel utilisateur Google créé: ${email}`);
        } else {
            console.log('✅ Utilisateur Google existant:', email);

            // Si l'utilisateur existe mais n'a pas de googleId, on l'ajoute
            if (!user.googleId) {
                user.googleId = googleId;
                await user.save();
                console.log('📝 Google ID ajouté à l\'utilisateur existant');
            }
        }

        // ==========================================
        // Générer un token JWT pour notre application
        // ==========================================
        const token = jwt.sign({ id: user.id }, config.secret, {
            expiresIn: 86400 // 24 heures
        });

        // ==========================================
        // Récupérer les rôles
        // ==========================================
        const roles = await user.getRoles();
        const authorities = roles.map(role => "ROLE_" + role.name.toUpperCase());

        console.log('🎉 Connexion Google réussie !');

        // ==========================================
        // Retourner la réponse
        // ==========================================
        res.status(200).send({
            id: user.id,
            username: user.username,
            email: user.email,
            roles: authorities,
            accessToken: token
        });

    } catch (error) {
        console.error("❌ Erreur connexion Google:", error);
        res.status(500).send({
            message: "Erreur serveur lors de la connexion Google",
            error: error.message
        });
    }
};