import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../auth/auth_providers.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource(ref.watch(apiClientProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(chatRemoteDataSourceProvider));
});

/// Conversas do usuário autenticado (comprador ou vendedor), mais recentes
/// primeiro. Invalide (`ref.invalidate(myChatsProvider)`) após enviar uma
/// mensagem ou abrir uma conversa nova.
final myChatsProvider = FutureProvider<List<ChatModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Future.value(const []);
  return ref.watch(chatRepositoryProvider).getChats();
});

final chatDetailProvider = FutureProvider.family<ChatModel?, String>((
  ref,
  chatId,
) {
  return ref.watch(chatRepositoryProvider).getChat(chatId);
});

/// Mensagens de uma conversa — invalide após enviar para ver a mensagem
/// aparecer (não há atualização automática em tempo real via REST).
final chatMessagesProvider = FutureProvider.family<List<MessageModel>, String>((
  ref,
  chatId,
) {
  return ref.watch(chatRepositoryProvider).getMessages(chatId);
});
