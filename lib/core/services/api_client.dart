import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_config.dart';
import '../errors/app_failure.dart';

/// Cliente HTTP para o backend próprio (Cloudflare Worker): guarda o token
/// de sessão, anexa o cabeçalho de autenticação e traduz erros da API em
/// [AppFailure], para a camada de repositório nunca lidar com `http`/`json`
/// diretamente.
class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  static const _tokenKey = 'leuplace_auth_token';
  static const _timeout = Duration(seconds: 15);

  final http.Client _http;
  String? _token;
  bool _tokenLoaded = false;

  Future<void> _ensureTokenLoaded() async {
    if (_tokenLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _tokenLoaded = true;
  }

  String? get currentToken => _token;

  /// Token de sessão, lido do aparelho se ainda não estiver em memória.
  Future<String?> loadToken() async {
    await _ensureTokenLoaded();
    return _token;
  }

  Future<void> setToken(String? token) async {
    _token = token;
    _tokenLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Object? body}) async {
    await _ensureTokenLoaded();

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
    final encodedBody = body == null ? null : jsonEncode(body);

    final Future<http.Response> request = switch (method) {
      'GET' => _http.get(uri, headers: headers),
      'POST' => _http.post(uri, headers: headers, body: encodedBody),
      'PATCH' => _http.patch(uri, headers: headers, body: encodedBody),
      'DELETE' => _http.delete(uri, headers: headers),
      _ => throw ArgumentError('Método HTTP não suportado: $method'),
    };

    http.Response response;
    try {
      response = await request.timeout(_timeout);
    } on TimeoutException {
      throw const AppFailure(
        'O servidor demorou para responder. Tente novamente.',
      );
    } catch (_) {
      throw const AppFailure('Falha de conexão. Verifique sua internet.');
    }

    final dynamic data = response.body.isEmpty
        ? null
        : jsonDecode(response.body);

    if (response.statusCode >= 400) {
      final message = (data is Map && data['error'] is String)
          ? data['error'] as String
          : 'Não foi possível concluir a operação (${response.statusCode}).';
      throw AppFailure(message);
    }

    return data;
  }
}
