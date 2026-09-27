import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Orquestra login/cadastro por e-mail contra o backend próprio (Cloudflare
/// Worker). Login social (Google/Facebook) e por telefone ainda não são
/// suportados pelo backend — ver `cloudflare/src/index.ts`.
class AuthRepository {
  AuthRepository(this._authDataSource);

  final AuthRemoteDataSource _authDataSource;

  Stream<UserModel?> get authStateChanges => _authDataSource.authStateChanges;

  UserModel? get currentUser => _authDataSource.currentUser;

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) {
    return _authDataSource.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _authDataSource.signInWithEmail(email, password);
  }

  /// Busca o perfil de novo (ex.: depois de publicar um anúncio, para o
  /// saldo de créditos exibido na tela ficar correto).
  Future<void> refreshProfile() => _authDataSource.refresh();

  Future<void> signOut() => _authDataSource.signOut();
}
