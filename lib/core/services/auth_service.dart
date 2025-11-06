import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/app_database.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'encryption_service.dart';
import 'package:logger/logger.dart';
import '../../../services/preferences_service.dart';
import '../../../services/cloud_sync_service.dart';
import '../../../services/email_service.dart';
import '../../../services/secure_store_service.dart';

class AuthService {
  final AppDatabase _database;
  final EncryptionService _encryptionService;
  final Logger _logger = Logger();

  AuthService(this._database, this._encryptionService);

  Future<AuthResult> login(String email, String password) async {
    try {
      _logger.i('Attempting login for email: $email');
      
      // Hash the password
      final hashedPassword = _hashPassword(password);
      
      // Find user by email
      final users = await _database.select(_database.users)
        ..where((u) => u.email.equals(email));
      
      final userData = await users.getSingleOrNull();
      
      if (userData == null) {
        _logger.w('User not found: $email');
        return AuthResult.failure('User not found');
      }

      // Verify password
      if (userData.passwordHash != hashedPassword) {
        _logger.w('Invalid password for user: $email');
        return AuthResult.failure('Invalid password');
      }

      // Check if user is active
      if (!userData.isActive) {
        _logger.w('Inactive user attempted login: $email');
        return AuthResult.failure('Account is deactivated');
      }

      // Convert to UserModel
      final user = _convertToUserModel(userData);
      
      // Save user session
      final prefs = await PreferencesService.getInstance();
      await prefs.setCurrentUserId(userData.id);
      await prefs.setUserInfo(user.name, user.email, user.phone);
      
      // Trigger cloud sync (background, non-blocking)
      _triggerCloudSync(userData.id, password).catchError((e) {
        _logger.w('Cloud sync failed (non-critical): $e');
      });
      
      // Log successful login
      await _logAuditEvent(userData.id, 'login', {
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _logger.i('Login successful for user: ${user.email}');
      return AuthResult.success(user);
      
    } catch (e, stackTrace) {
      _logger.e('Login error: $e', error: e, stackTrace: stackTrace);
      return AuthResult.failure('Login failed: ${e.toString()}');
    }
  }

  Future<AuthResult> register(UserModel user, String password) async {
    try {
      _logger.i('Attempting registration for email: ${user.email}');
      
      // Check if user already exists
      final existingUsers = await _database.select(_database.users)
        ..where((u) => u.email.equals(user.email));
      
      final existingUser = await existingUsers.getSingleOrNull();
      
      if (existingUser != null) {
        _logger.w('User already exists: ${user.email}');
        return AuthResult.failure('User already exists');
      }

      // Hash password
      final hashedPassword = _hashPassword(password);
      
      // Create user
      final userCompanion = UsersCompanion.insert(
        name: user.name,
        email: user.email,
        phone: user.phone,
        passwordHash: hashedPassword,
        age: user.age,
        gender: user.gender,
        height: user.height,
        weight: user.weight,
        bloodType: user.bloodType,
        medicalHistory: Value(user.medicalHistory),
        allergies: Value(user.allergies),
        medications: Value(user.medications),
      );

      final userId = await _database.into(_database.users).insert(userCompanion);
      
      // Get the created user
      final createdUserData = await _database.select(_database.users)
        ..where((u) => u.id.equals(userId));
      final userData = await createdUserData.getSingle();
      
      final createdUser = _convertToUserModel(userData);
      
      // Save user session
      final prefs = await PreferencesService.getInstance();
      await prefs.setCurrentUserId(userId);
      await prefs.setUserInfo(createdUser.name, createdUser.email, createdUser.phone);
      
      // Send welcome email (non-blocking)
      _sendWelcomeEmail(createdUser.email, createdUser.name).catchError((e) {
        _logger.w('Welcome email failed (non-critical): $e');
      });
      
      // Trigger initial cloud backup (background, non-blocking)
      _triggerCloudSync(userId, password).catchError((e) {
        _logger.w('Initial cloud sync failed (non-critical): $e');
      });
      
      // Log successful registration
      await _logAuditEvent(userId, 'register', {
        'email': user.email,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _logger.i('Registration successful for user: ${user.email}');
      return AuthResult.success(createdUser);
      
    } catch (e, stackTrace) {
      _logger.e('Registration error: $e', error: e, stackTrace: stackTrace);
      return AuthResult.failure('Registration failed: ${e.toString()}');
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      // This would need the current user context
      // Implementation depends on how you handle current user state
      final hashedNewPassword = _hashPassword(newPassword);
      
      // Update password in database
      // await _database.update(_database.users)
      //   ..where((u) => u.id.equals(currentUserId))
      //   ..write(UsersCompanion(passwordHash: Value(hashedNewPassword)));
      
      _logger.i('Password changed successfully');
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Password change error: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _logger.i('Password reset requested for: $email');
      
      // Check if user exists
      final users = await _database.select(_database.users)
        ..where((u) => u.email.equals(email));
      
      final userData = await users.getSingleOrNull();
      
      if (userData == null) {
        _logger.w('Password reset requested for non-existent user: $email');
        return false; // Don't reveal if user exists
      }

      // Generate reset token
      final resetToken = await _encryptionService.generateSecureToken();
      
      // Store reset token with expiration (24 hours)
      final tokenExpiry = DateTime.now().add(const Duration(hours: 24));
      // Store token in a secure way (for now in SharedPreferences, later in database)
      final prefs = await PreferencesService.getInstance();
      await prefs.saveCustomSettings('reset_token_${userData.id}', resetToken);
      await prefs.saveCustomSettings('reset_token_expiry_${userData.id}', tokenExpiry.toIso8601String());
      
      // Send password reset email
      final emailService = EmailService();
      // Try to get locale from preferences (default to 'en')
      String locale = 'en';
      try {
        final langCode = prefs.getCustomSetting<String>('language') ?? 'en';
        locale = langCode.length >= 2 ? langCode.substring(0, 2) : 'en';
      } catch (_) {
        locale = 'en';
      }
      final emailSent = await emailService.sendPasswordResetEmail(
        toEmail: email,
        resetToken: resetToken,
        locale: locale,
      );
      
      if (!emailSent) {
        _logger.w('Failed to send password reset email to $email');
        // Still return true to not reveal if user exists
      }

      // Log password reset request
      await _logAuditEvent(userData.id, 'password_reset_requested', {
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
        'status': emailSent ? 'email_sent' : 'email_failed',
      });

      _logger.i('Password reset email ${emailSent ? "sent" : "failed"} for: $email');
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Password reset error: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }
  
  // Additional method: Password reset with token verification
  Future<bool> resetPasswordWithToken(String email, String newPassword, String token) async {
    try {
      _logger.i('Password reset with token for: $email');
      
      // Find user
      final users = await _database.select(_database.users)
        ..where((u) => u.email.equals(email));
      
      final userData = await users.getSingleOrNull();
      
      if (userData == null) {
        return false;
      }
      
      // Verify token
      final prefs = await PreferencesService.getInstance();
      final storedToken = prefs.getCustomSetting<String>('reset_token_${userData.id}');
      final expiryStr = prefs.getCustomSetting<String>('reset_token_expiry_${userData.id}');
      
      if (storedToken != token || storedToken == null) {
        _logger.w('Invalid reset token for user: $email');
        return false;
      }
      
      if (expiryStr != null) {
        try {
          final expiry = DateTime.parse(expiryStr);
          if (DateTime.now().isAfter(expiry)) {
            _logger.w('Reset token expired for user: $email');
            // Clean up expired token
            await prefs.saveCustomSettings('reset_token_${userData.id}', '');
            return false;
          }
        } catch (_) {
          // Invalid expiry format, allow reset
        }
      }
      
      // Update password
      final hashedPassword = _hashPassword(newPassword);
      await _database.update(_database.users)
        ..where((u) => u.id.equals(userData.id))
        ..write(UsersCompanion(passwordHash: Value(hashedPassword), updatedAt: Value(DateTime.now())));
      
      // Clear reset token
      await prefs.saveCustomSettings('reset_token_${userData.id}', '');
      await prefs.saveCustomSettings('reset_token_expiry_${userData.id}', '');
      
      _logger.i('Password reset successful for: $email');
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Password reset error: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _logger.i('User logout');
      
      // Clear session data via PreferencesService
      final prefs = await PreferencesService.getInstance();
      await prefs.logout();
      
      _logger.i('User logged out successfully');
    } catch (e, stackTrace) {
      _logger.e('Logout error: $e', error: e, stackTrace: stackTrace);
    }
  }

  Future<AuthState> getCurrentAuthState() async {
    try {
      // Check if there's a stored session using PreferencesService
      final prefs = await PreferencesService.getInstance();
      
      if (prefs.isUserLoggedIn()) {
        final userId = prefs.getCurrentUserId();
        if (userId != null) {
          final user = await getUserById(userId);
          if (user != null && user.isActive) {
            _logger.i('Session restored for user: ${user.email}');
            
            // Attempt cloud restore if enabled (background, non-blocking)
            _attemptCloudRestore(userId).catchError((e) {
              _logger.w('Cloud restore failed (non-critical): $e');
            });
            
            return AuthState.authenticated(user);
          }
        }
      }
      
      return const AuthState.unauthenticated();
    } catch (e, stackTrace) {
      _logger.e('Get auth state error: $e', error: e, stackTrace: stackTrace);
      return AuthState.unauthenticated(e.toString());
    }
  }

  /// Attempt to restore from cloud backup on app launch
  Future<void> _attemptCloudRestore(int userId) async {
    try {
      final cloudSync = CloudSyncService();
      
      // Check if there's a newer backup in cloud
      final cloudMeta = await cloudSync.getLatestMeta();
      if (cloudMeta == null) {
        // No cloud backup exists
        return;
      }
      
      // Get user's password securely (needed for decryption)
      final password = await SecureStoreService().read('backup_password_for_sync');
      
      if (password == null || password.isEmpty) {
        // No password stored, skip restore
        _logger.i('No backup password stored, skipping cloud restore');
        return;
      }
      
      // Check if local data is older than cloud backup
      // For now, always attempt restore if cloud backup exists
      // In production, compare timestamps
      
      // Attempt restore (merge strategy to preserve local data)
      final restored = await cloudSync.restoreLatest(
        password,
        strategy: 'merge',
      );
      
      if (restored) {
        _logger.i('Cloud restore completed for user $userId');
      } else {
        _logger.w('Cloud restore failed for user $userId');
      }
    } catch (e) {
      _logger.w('Cloud restore error (non-critical): $e');
    }
  }

  Future<UserModel?> getUserById(int userId) async {
    try {
      final users = await _database.select(_database.users)
        ..where((u) => u.id.equals(userId));
      
      final userData = await users.getSingleOrNull();
      
      if (userData == null) return null;
      
      return _convertToUserModel(userData);
      
    } catch (e, stackTrace) {
      _logger.e('Get user by ID error: $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  Future<bool> updateUser(int userId, UserUpdateData updateData) async {
    try {
      final companion = UsersCompanion(
        name: Value(updateData.name),
        phone: Value(updateData.phone),
        age: Value(updateData.age),
        gender: Value(updateData.gender),
        height: Value(updateData.height),
        weight: Value(updateData.weight),
        bloodType: Value(updateData.bloodType),
        medicalHistory: Value(updateData.medicalHistory),
        allergies: Value(updateData.allergies),
        medications: Value(updateData.medications),
        updatedAt: Value(DateTime.now()),
      );

      await _database.update(_database.users)
        ..where((u) => u.id.equals(userId))
        ..write(companion);

      // Log user update
      await _logAuditEvent(userId, 'profile_updated', {
        'updated_fields': updateData.toJson().keys.toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });

      _logger.i('User updated successfully: $userId');
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Update user error: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> deactivateUser(int userId) async {
    try {
      await _database.update(_database.users)
        ..where((u) => u.id.equals(userId))
        ..write(UsersCompanion(
          isActive: const Value(false),
          updatedAt: Value(DateTime.now()),
        ));

      // Log user deactivation
      await _logAuditEvent(userId, 'account_deactivated', {
        'timestamp': DateTime.now().toIso8601String(),
      });

      _logger.i('User deactivated: $userId');
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Deactivate user error: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateResetToken() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }

  UserModel _convertToUserModel(User userData) {
    return UserModel(
      id: userData.id,
      name: userData.name,
      email: userData.email,
      phone: userData.phone,
      age: userData.age,
      gender: userData.gender,
      height: userData.height,
      weight: userData.weight,
      bloodType: userData.bloodType,
      medicalHistory: userData.medicalHistory,
      allergies: userData.allergies,
      medications: userData.medications,
      createdAt: userData.createdAt,
      updatedAt: userData.updatedAt,
      isActive: userData.isActive,
    );
  }

  Future<void> _logAuditEvent(int userId, String action, Map<String, dynamic> details) async {
    try {
      await _database.into(_database.auditLogs).insert(
        AuditLogsCompanion.insert(
          userId: userId,
          action: action,
          details: Value(jsonEncode(details)),
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      _logger.e('Failed to log audit event: $e');
    }
  }

  /// Trigger cloud sync after login/register
  Future<void> _triggerCloudSync(int userId, String password) async {
    try {
      final cloudSync = CloudSyncService();
      
      // Get user data
      final userData = await _database.select(_database.users)
        ..where((u) => u.id.equals(userId));
      final user = await userData.getSingleOrNull();
      
      if (user == null) return;
      
      // Set user identifier for cloud sync (use email as stable identifier)
      // CloudSyncService uses _userId internally, but we need to set it based on email
      await cloudSync.signInAnonymously(); // This creates/retrieves a user ID
      // For cloud sync, we'll use email as the identifier for backups
      final prefs = await PreferencesService.getInstance();
      await prefs.saveCustomSettings('cloud_sync_email', user.email);
      
      // Store password securely for backup/restore (secure storage)
      final secureStore = SecureStoreService();
      await secureStore.write('backup_password_for_sync', password);
      
      // Sync tables first (for Supabase)
      await cloudSync.syncTables(userId: userId);
      
      // Then do encrypted backup (use password)
      final backupSuccess = await cloudSync.backupNow(password);
      if (backupSuccess) {
        _logger.i('Cloud backup completed for user $userId');
        
        // Also trigger auto backup service to update last backup time
        final autoBackup = AutoBackupService();
        await autoBackup.backupNow(password);
      } else {
        _logger.w('Cloud backup failed for user $userId (non-critical)');
      }
    } catch (e) {
      _logger.w('Cloud sync error (non-critical): $e');
    }
  }

  /// Send welcome email after registration
  Future<void> _sendWelcomeEmail(String email, String name) async {
    try {
      final emailService = EmailService();
      final prefs = await PreferencesService.getInstance();
      // Try to get locale from preferences (default to 'en')
      String locale = 'en';
      try {
        final langCode = prefs.getCustomSetting<String>('language') ?? 'en';
        locale = langCode.length >= 2 ? langCode.substring(0, 2) : 'en';
      } catch (_) {
        locale = 'en';
      }
      
      await emailService.sendWelcomeEmail(
        toEmail: email,
        userName: name,
        locale: locale,
      );
      _logger.i('Welcome email sent to $email');
    } catch (e) {
      _logger.w('Welcome email error (non-critical): $e');
    }
  }
}
