import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/auth_providers.dart';
import '../constants/api_config.dart';
import '../errors/app_failure.dart';
import 'api_client.dart';

/// Foto escolhida pelo usuário, já lida em memória — funciona igual no
/// celular e no navegador (onde não existe acesso a arquivo por caminho).
class PickedPhoto {
  const PickedPhoto({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

/// Upload de fotos para o backend próprio (Cloudflare Worker + R2).
class StorageService {
  StorageService(this._api);

  final ApiClient _api;

  Future<String> uploadChatImage(PickedPhoto photo) =>
      _upload(photo, folder: 'chat');

  Future<String> uploadProductImage(PickedPhoto photo) =>
      _upload(photo, folder: 'product');

  Future<String> _upload(PickedPhoto photo, {required String folder}) async {
    final token = await _api.loadToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/uploads?folder=$folder'),
      headers: {
        'Content-Type': _contentType(photo.name),
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: photo.bytes,
    );

    if (response.statusCode >= 400) {
      throw const AppFailure(
        'Não foi possível enviar a foto. Tente novamente.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String;
  }

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(apiClientProvider));
});
