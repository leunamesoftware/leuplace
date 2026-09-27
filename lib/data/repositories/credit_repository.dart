import '../datasources/credit_remote_datasource.dart';
import '../models/credit_transaction_model.dart';

class CreditRepository {
  CreditRepository(this._dataSource);

  final CreditRemoteDataSource _dataSource;

  Future<List<CreditTransactionModel>> getHistory() async {
    final json = await _dataSource.getCredits();
    final rows = json['history'] as List<dynamic>? ?? const [];
    return rows
        .map(
          (row) =>
              CreditTransactionModel.fromApiJson(row as Map<String, dynamic>),
        )
        .toList();
  }
}
