import 'dart:async';

import '../../core/services/api_client.dart';
import '../models/user_model.dart';

/// Acesso bruto ao backend próprio (Cloudflare Worker) para autenticação —
/// sem regra de negócio. A camada de repositório decide o que fazer com o
/// resultado.
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._api) {
    _restoreSession();
  }

  final ApiClient _api;
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;
  bool _resolved = false;

  /// Emite o usuário autenticado (ou `null`) sempre que o estado de login
  /// muda. Quem começar a ouvir depois da sessão já resolvida recebe o valor
  /// atual na hora — sem isso a tela de abertura podia ficar esperando para
  /// sempre um evento que já tinha passado.
  Stream<UserModel?> get authStateChanges async* {
    if (_resolved) yield _currentUser;
    yield* _controller.stream;
  }

  UserModel? get currentUser => _currentUser;

  void _emit(UserModel? user) {
    _currentUser = user;
    _resolved = true;
    _controller.add(user);
  }

  Future<void> _restoreSession() async {
    if (await _api.loadToken() == null) {
      _emit(null);
      return;
    }
    try {
      final json = await _api.get('/me');
      _emit(UserModel.fromApiJson(json as Map<String, dynamic>));
    } catch (_) {
      _emit(null);
    }
  }

  /// Busca o perfil de novo (ex.: depois de publicar um anúncio, para o
  /// saldo de créditos exibido na tela ficar correto).
  Future<void> refresh() => _restoreSession();

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final json = await _api.post(
      '/auth/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
      },
    );
    return _applySession(json as Map<String, dynamic>);
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    final json = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return _applySession(json as Map<String, dynamic>);
  }

  Future<UserModel> _applySession(Map<String, dynamic> json) async {
    await _api.setToken(json['token'] as String);
    final user = UserModel.fromApiJson(json['user'] as Map<String, dynamic>);
    _emit(user);
    return user;
  }

  Future<void> signOut() async {
    await _api.setToken(null);
    _emit(null);
  }

  void dispose() => _controller.close();
}
