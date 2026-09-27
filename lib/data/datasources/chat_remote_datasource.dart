import '../../core/services/api_client.dart';

/// Acesso bruto ao backend próprio (Cloudflare Worker) para chat.
class ChatRemoteDataSource {
  ChatRemoteDataSource(this._api);

  final ApiClient _api;

  Future<List<dynamic>> getChats() async {
    return await _api.get('/chats') as List<dynamic>;
  }

  Future<Map<String, dynamic>?> getChat(String chatId) async {
    try {
      return await _api.get('/chats/$chatId') as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Encontra o chat já existente entre comprador e vendedor para o produto,
  /// ou cria um novo (o backend decide isso — basta informar o anúncio).
  Future<Map<String, dynamic>> findOrCreateChat(String productId) async {
    return await _api.post('/chats', body: {'productId': productId})
        as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMessages(String chatId) async {
    return await _api.get('/chats/$chatId/messages') as List<dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    String text = '',
    String? imageUrl,
  }) async {
    return await _api.post(
      '/chats/$chatId/messages',
      body: {'text': text, if (imageUrl != null) 'imageUrl': imageUrl},
    ) as Map<String, dynamic>;
  }
}
