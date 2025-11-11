// On importe les outils dont on a besoin
const axios = require("axios"); // Pour faire des requêtes HTTP
const config = require("../config/auth.config"); // Pour récupérer notre clé API

// --- Fonction pour récupérer la météo ---
// (CETTE FONCTION EST INCHANGÉE)
exports.getWeather = (req, res) => {
    // ... (votre code getWeather est parfait, on n'y touche pas) ...
    const { lat, lon } = req.query;

    if (!lat || !lon) {
        return res.status(400).send({ message: "Erreur! 'lat' et 'lon' sont obligatoires." });
    }
    const apiKey = config.openWeatherKey;
    const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&appid=${apiKey}&units=metric&lang=fr`;

    axios.get(url)
        .then(response => {
            res.status(200).send(response.data);
        })
        .catch(error => {
            console.error("Erreur lors de l'appel à OpenWeatherMap:", error.message);
            res.status(500).send({ message: "Erreur lors de la récupération de la météo." });
        });
};

// --- Fonction pour planifier un itinéraire à vélo (VERSION CORRIGÉE) ---
exports.planRoute = async (req, res) => {
    // 1. On récupère les coordonnées (comme avant)
    const { start, end } = req.body;

    if (!start || !end) {
        return res.status(400).send({ message: "Erreur! 'start' et 'end' sont obligatoires." });
    }

    // 2. On récupère la clé API (comme avant)
    const apiKey = config.openRouteKey;
    const orsApiUrl = "https://api.openrouteservice.org/v2/directions";

    // 3. On définit les 2 profils qu'on veut
    const profils = [
        { type: "rapide", ors_profile: "cycling-road" },
        { type: "securise", ors_profile: "cycling-regular" } 
    ];

    // 4. On prépare les 2 appels
    const headers = {
        'Authorization': apiKey,
        'Content-Type': 'application/json'
    };
    const postData = {
        coordinates: [start, end]
    };

    // ??? CORRECTION : Un seul point sur "profils.map" ???
    const routePromises = profils.map(profil => {
        const url = `${orsApiUrl}/${profil.ors_profile}/geojson`;
        return axios.post(url, postData, { headers: headers });
    });

    // 5. On exécute les 2 appels en parallèle
    try {
        const results = await Promise.allSettled(routePromises);
        const formattedRoutes = [];

        // 6. On traite les 2 réponses
        results.forEach((result, index) => {
            const profilType = profils[index].type;

            if (result.status === 'fulfilled' && result.value.data.features) {
                const feature = result.value.data.features[0];
                const summary = feature.properties.summary;

                formattedRoutes.push({
                    type: profilType,
                    distance: (summary.distance / 1000).toFixed(1),
                    duree: Math.round(summary.duration / 60),
                    trace: feature.geometry.coordinates
                });
            } else {
                // On garde le log, juste au cas où
                console.warn(`[DEBUG] Échec du calcul pour le profil: ${profilType}`);
                if (result.reason && result.reason.response) {
                    console.error(`[DEBUG] Erreur ORS (${profilType}):`, JSON.stringify(result.reason.response.data, null, 2));
                } else {
                    console.error(`[DEBUG] Erreur inconnue (${profilType}):`, result.reason);
                }
            }
        });

        // 7. On envoie le TABLEAU de résultats
        res.status(200).send(formattedRoutes);

    } catch (error) {
        console.error("Erreur lors de l'appel à OpenRouteService:", error.message);
        res.status(500).send({ message: "Erreur lors de la planification du trajet." });
    }
};