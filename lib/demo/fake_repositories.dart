import '../data/models/chat_model.dart';
import '../data/models/message_model.dart';
import '../data/models/product_model.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../data/repositories/product_repository.dart';
import 'fake_data.dart';

/// Implementações sem backend real, usadas só na prévia de demonstração —
/// `implements` (não `extends`) para nunca precisar construir um datasource
/// de verdade nem tocar no backend.
class FakeProductRepository implements ProductRepository {
  final List<ProductModel> _products = List.of(FakeData.products);

  @override
  Future<List<ProductModel>> getActiveProducts() async => _products;

  @override
  Future<List<ProductModel>> getByCategory(String categoryId) async {
    return _products.where((p) => p.categoryId == categoryId).toList();
  }

  @override
  Future<void> publish(ProductModel product) async {
    _products.insert(0, product);
  }

  @override
  Future<ProductModel?> getById(String id) async {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<List<ProductModel>> getMyProducts() async {
    return _products.where((p) => p.sellerId == FakeData.me.uid).toList();
  }

  @override
  Future<void> pause(String productId) async {}

  @override
  Future<void> activate(String productId) async {}

  @override
  Future<void> delete(String productId) async {
    _products.removeWhere((p) => p.id == productId);
  }

  @override
  Future<List<ProductModel>> searchByTitle(String query) async {
    if (query.trim().isEmpty) return getActiveProducts();
    final lower = query.toLowerCase();
    return _products
        .where((p) => p.title.toLowerCase().contains(lower))
        .toList();
  }
}

class FakeChatRepository implements ChatRepository {
  @override
  Future<List<ChatModel>> getChats() async => [FakeData.chat];

  @override
  Future<ChatModel?> getChat(String chatId) async => FakeData.chat;

  @override
  Future<ChatModel> findOrCreateChat(String productId) async {
    return FakeData.chat;
  }

  @override
  Future<List<MessageModel>> getMessages(String chatId) async {
    final sorted = List.of(FakeData.messages)
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return sorted;
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    String text = '',
    String? imageUrl,
  }) async {
    FakeData.messages.add(
      MessageModel(
        id: 'm${FakeData.messages.length + 1}',
        chatId: chatId,
        senderId: FakeData.me.uid,
        text: text,
        imageUrl: imageUrl,
        sentAt: DateTime.now(),
      ),
    );
  }
}

class FakeAuthRepository implements AuthRepository {
  @override
  Stream<UserModel?> get authStateChanges => Stream.value(null);

  @override
  UserModel? get currentUser => null;

  @override
  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {}

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> refreshProfile() async {}

  @override
  Future<void> signOut() async {}
}
