import '../../core/services/api_client.dart';

/// Acesso bruto ao backend próprio (Cloudflare Worker) para anúncios.
class ProductRemoteDataSource {
  ProductRemoteDataSource(this._api);

  final ApiClient _api;

  Future<List<dynamic>> getActiveProducts({int limit = 30}) async {
    return await _api.get('/products?limit=$limit') as List<dynamic>;
  }

  Future<List<dynamic>> getByCategory(String categoryId, {int limit = 30}) async {
    return await _api.get('/products?category=$categoryId&limit=$limit')
        as List<dynamic>;
  }

  Future<List<dynamic>> searchByTitle(String query, {int limit = 30}) async {
    return await _api.get('/products?q=${Uri.encodeQueryComponent(query)}&limit=$limit')
        as List<dynamic>;
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    try {
      return await _api.get('/products/$id') as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<dynamic>> getMine() async {
    return await _api.get('/products/mine') as List<dynamic>;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    return await _api.post('/products', body: body) as Map<String, dynamic>;
  }

  Future<void> updateStatus(String productId, String status) {
    return _api.patch('/products/$productId/status', body: {'status': status});
  }

  Future<void> delete(String productId) {
    return _api.delete('/products/$productId');
  }
}
