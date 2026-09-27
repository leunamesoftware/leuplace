import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/api_client.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/user_remote_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dataSource = AuthRemoteDataSource(ref.watch(apiClientProvider));
  ref.onDispose(dataSource.dispose);
  return dataSource;
});

final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource(ref.watch(apiClientProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(userRemoteDataSourceProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(authRemoteDataSourceProvider));
});

/// Emite o usuário autenticado (ou `null`) sempre que o estado de login
/// muda. O primeiro valor demora até a sessão salva no aparelho ser
/// conferida com o backend — até lá, `authState.isLoading` é `true`.
final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Uid do usuário autenticado, sem acoplar o resto do app ao tipo do
/// backend — facilita trocar de backend (ou usar dados falsos numa prévia)
/// sem tocar nas telas.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateChangesProvider).value?.uid;
});

/// Perfil (com papel/permissões) do usuário atualmente autenticado — o
/// mesmo valor de [authStateChangesProvider], só com um nome mais claro
/// para quem só precisa do perfil.
final currentUserProfileProvider = Provider<AsyncValue<UserModel?>>((ref) {
  return ref.watch(authStateChangesProvider);
});

/// Atalho para checagem de permissão de administrador na UI.
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProfileProvider).value?.isAdmin ?? false;
});

/// Perfil público de qualquer usuário (ex.: dados do vendedor na tela de
/// produto), buscado uma única vez por uid.
final userProfileProvider = FutureProvider.family<UserModel?, String>((
  ref,
  uid,
) {
  return ref.watch(userRepositoryProvider).getProfile(uid);
});
