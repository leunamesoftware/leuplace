/// Endereço do backend próprio (Cloudflare Worker).
///
/// Ainda é um placeholder de propósito — o Worker (código em `cloudflare/`)
/// ainda não foi publicado. Assim que for, troque este valor pela URL real
/// (algo como `https://leuplace-api.SEU-SUBDOMINIO.workers.dev`).
abstract final class ApiConfig {
  static const String baseUrl = 'https://leuplace-api.example.workers.dev';
}
