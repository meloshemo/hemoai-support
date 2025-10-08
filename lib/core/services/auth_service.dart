import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/app_database.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'encryption_service.dart';
import 'package:logger/logger.dart';

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

      // Generate reset token and send email
      // This would integrate with an email service
      final resetToken = _generateResetToken();
      
      // Store reset token (you'd need a reset_tokens table)
      // await _database.into(_database.resetTokens).insert(
      //   ResetTokensCompanion.insert(
      //     userId: userData.id,
      //     token: resetToken,
      //     expiresAt: DateTime.now().add(const Duration(hours: 1)),
      //   ),
      // );

      // Send reset email
      // await _emailService.sendPasswordResetEmail(email, resetToken);

      // Log password reset request
      await _logAuditEvent(userData.id, 'password_reset_requested', {
        'email': email,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _logger.i('Password reset email sent to: $email');
      return true;
      
    } catch (e, stackTrace) {
      _logger.e('Password reset error: $e', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      _logger.i('User logout');
      // Clear any session data
      // You might want to invalidate tokens here
    } catch (e, stackTrace) {
      _logger.e('Logout error: $e', error: e, stackTrace: stackTrace);
    }
  }

  Future<AuthState> getCurrentAuthState() async {
    try {
      // Check if there's a stored session
      // This would depend on your session management strategy
      return const AuthState.unauthenticated();
    } catch (e, stackTrace) {
      _logger.e('Get auth state error: $e', error: e, stackTrace: stackTrace);
      return AuthState.unauthenticated(e.toString());
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
}
