import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/auth_providers.dart';
import '../constants/api_config.dart';
import '../errors/app_failure.dart';
import 'api_client.dart';

/// Upload de arquivos para o backend próprio (Cloudflare Worker + R2).
class StorageService {
  StorageService(this._api);

  final ApiClient _api;

  Future<String> uploadChatImage({
    required String chatId,
    required File file,
  }) {
    return _upload(file, folder: 'chat');
  }

  Future<String> uploadProductImage({
    required String sellerId,
    required File file,
    required int index,
  }) {
    return _upload(file, folder: 'product');
  }

  Future<String> _upload(File file, {required String folder}) async {
    final bytes = await file.readAsBytes();
    final contentType = _guessContentType(file.path);

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/uploads?folder=$folder'),
      headers: {
        'Content-Type': contentType,
        if (_api.currentToken != null)
          'Authorization': 'Bearer ${_api.currentToken}',
      },
      body: bytes,
    );

    if (response.statusCode >= 400) {
      throw const AppFailure(
        'Não foi possível enviar a foto. Tente novamente.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String;
  }

  String _guessContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(apiClientProvider));
});
