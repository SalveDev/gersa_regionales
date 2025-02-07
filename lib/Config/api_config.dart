class ApiConfig {
  // URL base del servidor
  static const String domain = "127.0.0.1";
  static const String baseUrl = "http://$domain/regionWatch";

  // Endpoints de la API
  static const String login = "$baseUrl/login";
  static const String inicio = "$baseUrl/inicio";
  static const String refresh = "$baseUrl/refresh";
}