import '../../core/constants/category_seed.dart';
import '../datasources/category_remote_datasource.dart';
import '../models/category_model.dart';

/// Lista de categorias ativas. Enquanto o backend não tiver nenhuma
/// categoria cadastrada, cai para [CategorySeed.initial] como carga inicial.
class CategoryRepository {
  CategoryRepository(this._dataSource);

  final CategoryRemoteDataSource _dataSource;

  Future<List<CategoryModel>> getCategories() async {
    final rows = await _dataSource.getCategories();
    final categories = rows
        .map((row) => CategoryModel.fromApiJson(row as Map<String, dynamic>))
        .where((category) => category.active)
        .toList();
    return categories.isEmpty ? CategorySeed.initial : categories;
  }
}
