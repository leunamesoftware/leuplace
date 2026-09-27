import '../../core/services/api_client.dart';

/// Acesso bruto ao backend próprio (Cloudflare Worker) para categorias.
class CategoryRemoteDataSource {
  CategoryRemoteDataSource(this._api);

  final ApiClient _api;

  Future<List<dynamic>> getCategories() async {
    return await _api.get('/categories') as List<dynamic>;
  }
}
