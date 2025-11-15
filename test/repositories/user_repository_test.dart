import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserRepository', () {
    late UserRepository userRepository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      userRepository = UserRepository();
    });

    group('Active User Management', () {
      test('should set active user ID', () async {
        await userRepository.setActiveUserId(1);
        final userId = await userRepository.getActiveUserId();
        expect(userId, equals(1));
      });

      test('should get active user ID', () async {
        await userRepository.setActiveUserId(123);
        final userId = await userRepository.getActiveUserId();
        expect(userId, equals(123));
      });

      test('should return null when no active user', () async {
        SharedPreferences.setMockInitialValues({});
        final userId = await userRepository.getActiveUserId();
        expect(userId, isNull);
      });
    });

    group('User CRUD Operations', () {
      test('should create user', () async {
        final user = {
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '5551234567',
          // Required non-null schema fields for native SQLite implementation
          'password_hash': 'test_hash',
          'age': 30,
          'gender': 'male',
          'height': 175.0,
          'weight': 70.0,
        };
        
        final userId = await userRepository.createUser(user);
        expect(userId, isA<int>());
        expect(userId, greaterThan(0));
      });

      test('should get user by email', () async {
        final user = {
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '5551234567',
          'password_hash': 'test_hash',
          'age': 30,
          'gender': 'male',
          'height': 175.0,
          'weight': 70.0,
        };
        
        await userRepository.createUser(user);
        final retrieved = await userRepository.getUserByEmail('test@example.com');
        
        expect(retrieved, isNotNull);
        expect(retrieved!['email'], equals('test@example.com'));
      });

      test('should get user by ID', () async {
        final user = {
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '5551234567',
          'password_hash': 'test_hash',
          'age': 30,
          'gender': 'male',
          'height': 175.0,
          'weight': 70.0,
        };
        
        final userId = await userRepository.createUser(user);
        final retrieved = await userRepository.getUserById(userId);
        
        expect(retrieved, isNotNull);
        expect(retrieved!['email'], equals('test@example.com'));
      });

      test('should update user', () async {
        final user = {
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '5551234567',
          'password_hash': 'test_hash',
          'age': 30,
          'gender': 'male',
          'height': 175.0,
          'weight': 70.0,
        };
        
        final userId = await userRepository.createUser(user);
        
        final updated = {
          'name': 'Updated User',
          'email': 'test@example.com',
          'phone': '5551234567',
          'password_hash': 'test_hash', // unchanged hash placeholder
          'age': 31,
          'gender': 'male',
          'height': 176.0,
          'weight': 71.0,
        };
        
        final result = await userRepository.updateUser(userId, updated);
        expect(result, equals(1));
        
        final retrieved = await userRepository.getUserById(userId);
        expect(retrieved!['name'], equals('Updated User'));
      });

      test('should return null for non-existent user', () async {
        final user = await userRepository.getUserByEmail('nonexistent@example.com');
        expect(user, isNull);
      });
    });

    group('User Statistics', () {
      test('should get user stats', () async {
        final user = {
          'name': 'Test User',
          'email': 'test@example.com',
          'phone': '5551234567',
          'password_hash': 'test_hash',
          'age': 30,
          'gender': 'male',
          'height': 175.0,
          'weight': 70.0,
        };
        
        final userId = await userRepository.createUser(user);
        final stats = await userRepository.getUserStats(userId);
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalTests'), true);
      });
    });
  });
}

