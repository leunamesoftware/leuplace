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

  /// Emite o usuário autenticado (ou `null`) sempre que o estado de login
  /// muda. O primeiro valor só chega depois de tentar restaurar a sessão
  /// salva (token no dispositivo) — até lá, quem observa vê "carregando".
  Stream<UserModel?> get authStateChanges => _controller.stream;

  UserModel? get currentUser => _currentUser;

  Future<void> _restoreSession() async {
    try {
      final json = await _api.get('/me');
      _currentUser = UserModel.fromApiJson(json as Map<String, dynamic>);
    } catch (_) {
      _currentUser = null;
    }
    _controller.add(_currentUser);
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
    _currentUser = user;
    _controller.add(user);
    return user;
  }

  Future<void> signOut() async {
    await _api.setToken(null);
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
