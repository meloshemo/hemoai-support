import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/app_database.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../services/localization_service.dart';
import '../services/encryption_service.dart';
import '../services/notification_service.dart';
import '../services/health_sync_service.dart';
import '../services/ai_analysis_service.dart';
import 'package:logger/logger.dart';

part 'auth_provider.g.dart';

final logger = Logger();

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthState> build() async {
    final authService = ref.read(authServiceProvider);
    return await authService.getCurrentAuthState();
  }

  Future<bool> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      
      final authService = ref.read(authServiceProvider);
      final result = await authService.login(email, password);
      
      if (result.success) {
        state = AsyncValue.data(AuthState.authenticated(result.user!));
        logger.i('User logged in successfully: ${result.user!.email}');
        return true;
      } else {
        final loc = LocalizationService();
        state = AsyncValue.data(AuthState.unauthenticated(result.error ?? loc.getString('login_failed')));
        logger.e('${loc.getString('login_failed')}: ${result.error}');
        return false;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      logger.e('Login error: $error', error: error, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> register(UserModel user, String password) async {
    try {
      state = const AsyncValue.loading();
      
      final authService = ref.read(authServiceProvider);
      final result = await authService.register(user, password);
      
      if (result.success) {
        state = AsyncValue.data(AuthState.authenticated(result.user!));
        logger.i('User registered successfully: ${result.user!.email}');
        return true;
      } else {
        final loc = LocalizationService();
        state = AsyncValue.data(AuthState.unauthenticated(result.error ?? loc.getString('registration_failed')));
        logger.e('${loc.getString('registration_failed')}: ${result.error}');
        return false;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      logger.e('Registration error: $error', error: error, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.logout();
      final loc = LocalizationService();
      state = AsyncValue.data(AuthState.unauthenticated(loc.getString('logged_out')));
      logger.i(loc.getString('logged_out'));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      logger.e('Logout error: $error', error: error, stackTrace: stackTrace);
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      state = const AsyncValue.loading();
      
      final authService = ref.read(authServiceProvider);
      final result = await authService.changePassword(currentPassword, newPassword);
      
      if (result) {
        logger.i(LocalizationService().getString('password_changed_successfully'));
        return true;
      } else {
        logger.e(LocalizationService().getString('password_change_failed'));
        return false;
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      logger.e('Password change error: $error', error: error, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      final authService = ref.read(authServiceProvider);
      return await authService.resetPassword(email);
    } catch (error, stackTrace) {
      logger.e('Password reset error: $error', error: error, stackTrace: stackTrace);
      return false;
    }
  }
}

// Auth State
@riverpod
class AuthState extends _$AuthState {
  @override
  AuthStateData build() {
    return const AuthStateData.unauthenticated();
  }
}

// Auth Service Provider
@riverpod
AuthService authService(AuthServiceRef ref) {
  return AuthService(
    ref.read(databaseProvider),
    ref.read(encryptionServiceProvider),
  );
}

// Database Provider
@riverpod
AppDatabase database(DatabaseRef ref) {
  return AppDatabase();
}

// Encryption Service Provider
@riverpod
EncryptionService encryptionService(EncryptionServiceRef ref) {
  return EncryptionService();
}

// Current User Provider
@riverpod
Future<UserModel?> currentUser(CurrentUserRef ref) async {
  final authState = await ref.watch(authNotifierProvider.future);
  return authState.user;
}

// Notification Service Provider
@riverpod
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}

// Health Sync Service Provider
@riverpod
HealthSyncService healthSyncService(HealthSyncServiceRef ref) {
  return HealthSyncService();
}

// AI Analysis Service Provider
@riverpod
AIAnalysisService aiAnalysisService(AIAnalysisServiceRef ref) {
  return AIAnalysisService();
}

// Authentication State
enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthState._(this.status, this.user, this.error);

  factory AuthState.authenticated(UserModel user) => 
    AuthState._(AuthStatus.authenticated, user, null);
  
  factory AuthState.unauthenticated([String? error]) => 
    AuthState._(AuthStatus.unauthenticated, null, error);
  
  factory AuthState.loading() => 
    const AuthState._(AuthStatus.loading, null, null);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => error != null;
}

// Auth State Data for Riverpod
class AuthStateData {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  const AuthStateData._(this.status, this.user, this.error);

  factory AuthStateData.authenticated(UserModel user) => 
    AuthStateData._(AuthStatus.authenticated, user, null);
  
  factory AuthStateData.unauthenticated([String? error]) => 
    AuthStateData._(AuthStatus.unauthenticated, null, error);
  
  factory AuthStateData.loading() => 
    const AuthStateData._(AuthStatus.loading, null, null);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => error != null;
}

// Auth Result
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? error;

  const AuthResult({
    required this.success,
    this.user,
    this.error,
  });

  factory AuthResult.success(UserModel user) => 
    AuthResult(success: true, user: user);
  
  factory AuthResult.failure(String error) => 
    AuthResult(success: false, error: error);
}
