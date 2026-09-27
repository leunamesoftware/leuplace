import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/credit_remote_datasource.dart';
import '../../data/models/credit_transaction_model.dart';
import '../../data/repositories/credit_repository.dart';
import '../auth/auth_providers.dart';

final creditRemoteDataSourceProvider = Provider<CreditRemoteDataSource>((ref) {
  return CreditRemoteDataSource(ref.watch(apiClientProvider));
});

final creditRepositoryProvider = Provider<CreditRepository>((ref) {
  return CreditRepository(ref.watch(creditRemoteDataSourceProvider));
});

final creditHistoryProvider = FutureProvider<List<CreditTransactionModel>>((
  ref,
) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Future.value(const []);
  return ref.watch(creditRepositoryProvider).getHistory();
});
