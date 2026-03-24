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
    if (state.value == null) {
      state = const AsyncValue.loading();
    }
    
    try {
      // Try fetching latest from backend
      final user = await _authService.fetchProfile();
      if (user != null) {
        state = AsyncValue.data(user);
        return;
      }
      
      // Fallback to local if fetch returns null (e.g. no token)
      final localUser = await _authService.getUser();
      state = AsyncValue.data(localUser);
    } catch (e, st) {
      // If error occurs (e.g. network), fallback to what we have or error
      final localUser = await _authService.getUser();
      if (localUser != null) {
        state = AsyncValue.data(localUser);
      } else {
        state = AsyncValue.error(e, st);
      }
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
