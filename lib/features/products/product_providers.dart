import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/product_remote_datasource.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../auth/auth_providers.dart';

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((
  ref,
) {
  return ProductRemoteDataSource(ref.watch(apiClientProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(productRemoteDataSourceProvider));
});

/// Anúncios ativos mais recentes (usado na Home — "Anúncios perto de você";
/// filtro por localização real chega na Fase 3/4 avançada).
final nearbyProductsProvider = FutureProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).getActiveProducts();
});

final productDetailProvider = FutureProvider.family<ProductModel?, String>((
  ref,
  productId,
) {
  return ref.watch(productRepositoryProvider).getById(productId);
});

/// Anúncios do usuário atual — invalide após publicar/pausar/excluir para
/// a tela "Meus anúncios" recarregar (`ref.invalidate(myProductsProvider)`).
final myProductsProvider = FutureProvider<List<ProductModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Future.value(const []);
  return ref.watch(productRepositoryProvider).getMyProducts();
});

final productsByCategoryProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, categoryId) {
      return ref.watch(productRepositoryProvider).getByCategory(categoryId);
    });

/// Estado da tela de Buscar: texto digitado e categoria selecionada (quando
/// a busca chega a partir de um toque na grade de Categorias).
final searchQueryProvider = StateProvider<String>((ref) => '');
final categoryFilterProvider = StateProvider<String?>((ref) => null);

final searchResultsProvider = FutureProvider<List<ProductModel>>((ref) {
  final categoryId = ref.watch(categoryFilterProvider);
  final query = ref.watch(searchQueryProvider);

  final repository = ref.watch(productRepositoryProvider);
  if (categoryId != null) return repository.getByCategory(categoryId);
  return repository.searchByTitle(query);
});
