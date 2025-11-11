// Modele pour les donnees meteo
class Weather {
  final String location;
  final double temperature;
  final String description;
  final String icon;
  final double windSpeed;
  final int humidity;
  final double? feelsLike;

  Weather({
    required this.location,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.windSpeed,
    required this.humidity,
    this.feelsLike,
  });

  // Parse depuis l'API OpenWeatherMap
  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      location: json['name'] ?? '',
      temperature: (json['main']?['temp'] ?? 0).toDouble(),
      description: json['weather']?[0]?['description'] ?? '',
      icon: json['weather']?[0]?['icon'] ?? '01d',
      windSpeed: (json['wind']?['speed'] ?? 0).toDouble(),
      humidity: json['main']?['humidity'] ?? 0,
      feelsLike: json['main']?['feels_like']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'temperature': temperature,
      'description': description,
      'icon': icon,
      'windSpeed': windSpeed,
      'humidity': humidity,
      'feelsLike': feelsLike,
    };
  }

  // URL de l'icone meteo
  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  // Temperature en Celsius arrondie
  String get tempCelsius => '${temperature.toStringAsFixed(1)}°C';

  // Est-ce que c'est bon pour faire du velo ?
  bool get isGoodForCycling {
    // Bon si temperature entre 10 et 30°C, vent < 25 km/h, et pas de pluie
    return temperature >= 10 &&
           temperature <= 30 &&
           windSpeed < 7 && // 7 m/s = 25 km/h
           !description.toLowerCase().contains('rain') &&
           !description.toLowerCase().contains('storm');
  }

  String get cyclingRecommendation {
    if (isGoodForCycling) return 'Parfait pour faire du velo !';
    if (temperature < 10) return 'Trop froid pour faire du velo';
    if (temperature > 30) return 'Trop chaud pour faire du velo';
    if (windSpeed >= 7) return 'Vent trop fort';
    if (description.toLowerCase().contains('rain')) return 'Risque de pluie';
    return 'Conditions moyennes pour faire du velo';
  }
}
