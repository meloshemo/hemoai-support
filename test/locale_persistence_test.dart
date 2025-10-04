import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hemoai/services/localization_service.dart';

void main() {
  group('Locale change persistence', () {
    tearDown(() async {
      // Reset language to English to avoid leaking state across tests
      await LocalizationService().changeLanguage('en');
    });

    test('Changing language does not alter stored data', () async {
      // Seed initial data as if user previously saved info in Turkish
      final initialUsers = [jsonEncode({'id': 1, 'name': 'Ayşe'})];
      final initialFamilyMembers = [
        jsonEncode({'id': 10, 'user_id': 1, 'name': 'Mehmet'})
      ];

      SharedPreferences.setMockInitialValues({
        'selected_language': 'tr',
        'users': initialUsers,
        'family_members': initialFamilyMembers,
      });

      final prefsBefore = await SharedPreferences.getInstance();
      final usersBefore = List<String>.from(prefsBefore.getStringList('users') ?? <String>[]);
      final familyBefore = List<String>.from(prefsBefore.getStringList('family_members') ?? <String>[]);

      // Change language to English
      final loc = LocalizationService();
      await loc.changeLanguage('en');

      // Verify language preference updated
      final prefsAfter = await SharedPreferences.getInstance();
      expect(prefsAfter.getString('selected_language'), 'en');

      // Verify data remains unchanged
      final usersAfter = prefsAfter.getStringList('users') ?? <String>[];
      final familyAfter = prefsAfter.getStringList('family_members') ?? <String>[];

      expect(usersAfter, usersBefore);
      expect(familyAfter, familyBefore);

      // And decoded contents are intact
      final decodedUser = jsonDecode(usersAfter.first) as Map<String, dynamic>;
      expect(decodedUser['id'], 1);
      expect(decodedUser['name'], 'Ayşe');

      final decodedFamily = jsonDecode(familyAfter.first) as Map<String, dynamic>;
      expect(decodedFamily['id'], 10);
      expect(decodedFamily['user_id'], 1);
      expect(decodedFamily['name'], 'Mehmet');
    });
  });
}
