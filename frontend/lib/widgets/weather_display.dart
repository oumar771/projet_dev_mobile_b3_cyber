import 'package:flutter/material.dart';
import '../models/weather.dart';

class WeatherDisplay extends StatelessWidget {
  final Weather weather;
  final bool compact;

  const WeatherDisplay({
    super.key,
    required this.weather,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView(context);
    }
    return _buildFullView(context);
  }

  Widget _buildCompactView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getWeatherGradient(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            weather.iconUrl,
            width: 40,
            height: 40,
            errorBuilder: (_, __, ___) => const Icon(Icons.cloud, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weather.tempCelsius,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                weather.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Icon(
            weather.isGoodForCycling ? Icons.check_circle : Icons.warning_amber,
            color: weather.isGoodForCycling ? Colors.green[300] : Colors.orange[300],
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildFullView(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getWeatherGradient(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    weather.location,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Temperature et icône
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.tempCelsius,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        weather.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Image.network(
                    weather.iconUrl,
                    width: 80,
                    height: 80,
                    errorBuilder: (_, __, ___) => const Icon(Icons.cloud, color: Colors.white, size: 80),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Détails météo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherDetail(
                    icon: Icons.air,
                    label: 'Vent',
                    value: '${(weather.windSpeed * 3.6).toStringAsFixed(1)} km/h',
                  ),
                  _buildWeatherDetail(
                    icon: Icons.water_drop,
                    label: 'Humidité',
                    value: '${weather.humidity}%',
                  ),
                  if (weather.feelsLike != null)
                    _buildWeatherDetail(
                      icon: Icons.thermostat,
                      label: 'Ressenti',
                      value: '${weather.feelsLike!.toStringAsFixed(1)}°C',
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Recommandation vélo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: weather.isGoodForCycling
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: weather.isGoodForCycling
                        ? Colors.green[200]!
                        : Colors.orange[200]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      weather.isGoodForCycling
                          ? Icons.directions_bike
                          : Icons.warning_amber,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        weather.cyclingRecommendation,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  List<Color> _getWeatherGradient() {
    if (weather.description.toLowerCase().contains('rain') ||
        weather.description.toLowerCase().contains('storm')) {
      return [Colors.grey.shade700, Colors.grey.shade500];
    } else if (weather.description.toLowerCase().contains('cloud')) {
      return [Colors.blue.shade400, Colors.blue.shade300];
    } else {
      // Ensoleillé
      return [Colors.orange.shade400, Colors.yellow.shade300];
    }
  }
}
