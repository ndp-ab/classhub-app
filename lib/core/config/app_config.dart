class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
    // defaultValue: 'http://192.168.1.5:8080/api',

  );
}
