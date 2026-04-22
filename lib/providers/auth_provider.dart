import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((_) => AuthRepository());

/// Raw Firebase auth state (null = signed out)
final authStateProvider = StreamProvider<UserModel?>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  await for (final firebaseUser in repo.authStateChanges) {
    if (firebaseUser == null) {
      yield null;
    } else {
      yield await repo.getCurrentUser();
    }
  }
});

/// Convenience: the signed-in user (throws if null)
final currentUserProvider = Provider<UserModel>((ref) {
  return ref.watch(authStateProvider).requireValue!;
});

class AuthNotifier extends AsyncNotifier<void> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<void> build() async {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signInWithEmail(email, password),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.signOut());
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
