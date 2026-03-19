import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<Map<String, dynamic>?>>((ref) {
  return UserNotifier(ref.read(authServiceProvider));
});

class UserNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final AuthService _authService;

  UserNotifier(this._authService) : super(const AsyncValue.loading()) {
    refreshUser();
  }

  Future<void> refreshUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.getUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setUser(Map<String, dynamic>? user) {
    state = AsyncValue.data(user);
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}
