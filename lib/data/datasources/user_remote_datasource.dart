import '../../core/services/api_client.dart';

/// Acesso bruto ao backend próprio (Cloudflare Worker) para perfis de
/// usuário — sem regra de negócio.
class UserRemoteDataSource {
  UserRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> getPublicProfile(String uid) async {
    return await _api.get('/users/$uid') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMyProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    return await _api.patch(
      '/me',
      body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (photoUrl != null) 'photoUrl': photoUrl,
      },
    ) as Map<String, dynamic>;
  }
}
