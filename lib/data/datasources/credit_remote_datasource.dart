import '../../core/services/api_client.dart';

/// Acesso bruto ao backend próprio (Cloudflare Worker) para créditos.
class CreditRemoteDataSource {
  CreditRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> getCredits() async {
    return await _api.get('/credits') as Map<String, dynamic>;
  }
}
