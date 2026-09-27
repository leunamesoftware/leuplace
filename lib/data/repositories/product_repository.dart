import '../datasources/product_remote_datasource.dart';
import '../models/product_model.dart';

/// Regras de leitura/escrita de anúncios contra o backend próprio.
class ProductRepository {
  ProductRepository(this._dataSource);

  final ProductRemoteDataSource _dataSource;

  Future<List<ProductModel>> getActiveProducts() async {
    final rows = await _dataSource.getActiveProducts();
    return _mapRows(rows);
  }

  Future<List<ProductModel>> getByCategory(String categoryId) async {
    final rows = await _dataSource.getByCategory(categoryId);
    return _mapRows(rows);
  }

  Future<List<ProductModel>> searchByTitle(String query) async {
    if (query.trim().isEmpty) return getActiveProducts();
    final rows = await _dataSource.searchByTitle(query.trim());
    return _mapRows(rows);
  }

  /// Publica o anúncio consumindo 1 crédito do vendedor. O backend recusa
  /// (HTTP 402, traduzido para [AppFailure]) quando não há créditos.
  Future<void> publish(ProductModel product) {
    return _dataSource.create(product.toApiJson());
  }

  Future<ProductModel?> getById(String id) async {
    final json = await _dataSource.getById(id);
    if (json == null) return null;
    return ProductModel.fromApiJson(json);
  }

  Future<List<ProductModel>> getMyProducts() async {
    final rows = await _dataSource.getMine();
    return _mapRows(rows);
  }

  Future<void> pause(String productId) =>
      _dataSource.updateStatus(productId, 'paused');

  Future<void> activate(String productId) =>
      _dataSource.updateStatus(productId, 'active');

  Future<void> delete(String productId) => _dataSource.delete(productId);

  List<ProductModel> _mapRows(List<dynamic> rows) {
    return rows
        .map((row) => ProductModel.fromApiJson(row as Map<String, dynamic>))
        .toList();
  }
}
