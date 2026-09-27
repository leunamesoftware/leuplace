import '../datasources/user_remote_datasource.dart';
import '../models/user_model.dart';

/// Perfis de usuário: leitura pública (ex.: dados do vendedor na tela de
/// anúncio) e edição do próprio perfil.
class UserRepository {
  UserRepository(this._dataSource);

  final UserRemoteDataSource _dataSource;

  Future<UserModel?> getProfile(String uid) async {
    try {
      final json = await _dataSource.getPublicProfile(uid);
      return UserModel.fromApiJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    final json = await _dataSource.updateMyProfile(
      name: name,
      phone: phone,
      photoUrl: photoUrl,
    );
    return UserModel.fromApiJson(json);
  }
}
