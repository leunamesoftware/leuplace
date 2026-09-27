/// Endereço do backend próprio (Cloudflare Worker), publicado via GitHub
/// Actions (`.github/workflows/deploy-worker.yml`).
abstract final class ApiConfig {
  static const String baseUrl = 'https://leuplace-api.leunamesoftware.com';
}
