import '../datasources/chat_remote_datasource.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRepository {
  ChatRepository(this._dataSource);

  final ChatRemoteDataSource _dataSource;

  Future<List<ChatModel>> getChats() async {
    final rows = await _dataSource.getChats();
    final chats = rows
        .map((row) => ChatModel.fromApiJson(row as Map<String, dynamic>))
        .toList();
    chats.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return chats;
  }

  Future<ChatModel?> getChat(String chatId) async {
    final json = await _dataSource.getChat(chatId);
    if (json == null) return null;
    return ChatModel.fromApiJson(json);
  }

  /// Encontra a conversa já existente sobre o anúncio, ou cria uma nova.
  Future<ChatModel> findOrCreateChat(String productId) async {
    final json = await _dataSource.findOrCreateChat(productId);
    return ChatModel.fromApiJson(json);
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    final rows = await _dataSource.getMessages(chatId);
    return rows
        .map((row) => MessageModel.fromApiJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> sendMessage({
    required String chatId,
    String text = '',
    String? imageUrl,
  }) {
    return _dataSource.sendMessage(
      chatId: chatId,
      text: text,
      imageUrl: imageUrl,
    );
  }
}
