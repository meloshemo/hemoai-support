import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/localization_service.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  bool _activating = true;
  PreferencesService? _prefs;
  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _activateGuest();
  }

  Future<void> _activateGuest() async {
    _prefs = await PreferencesService.getInstance();
    // Ensure a Guest user exists and set as current
    final guestEmail = 'guest@hemoai.com';
    Map<String, dynamic>? user = await _db.getUser(guestEmail);
    if (user == null) {
      final hash = sha256.convert(utf8.encode('guest')).toString();
      final userRow = {
        'name': 'Guest',
        'email': guestEmail,
        'phone': 'guest',
        'password_hash': hash,
        'age': 0,
        'gender': 'male',
        'height': 0.0,
        'weight': 0.0,
        'bmi': 0.0,
      };
      final id = await _db.insertUser(userRow);
      user = {...userRow, 'id': id};
    }
    // Mark as logged in and guest
    await _prefs!.saveUserInfo(
      name: user['name'] as String,
      email: user['email'] as String,
      phone: user['phone'] as String,
      age: (user['age'] as num).toInt(),
      gender: user['gender'] as String,
      height: (user['height'] as num).toDouble(),
      weight: (user['weight'] as num).toDouble(),
    );
    await _prefs!.setCurrentUserId(user['id'] as int);
    await _prefs!.saveCustomSettings('is_guest', true);
    if (mounted) setState(() => _activating = false);
  }

  void _nav(String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    if (_activating) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.getString('continue_as_guest'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final tiles = [
      _FeatureTile(Icons.person, loc.getString('personal_info'), '/personal_info'),
      _FeatureTile(Icons.bloodtype, loc.getString('hemogram_entry'), '/hemogram_entry'),
      _FeatureTile(Icons.analytics, loc.getString('analysis'), '/analysis'),
      _FeatureTile(Icons.restaurant_menu, loc.getString('diet_program'), '/diet_program'),
      _FeatureTile(Icons.family_restroom, loc.getString('family_panel'), '/family_panel'),
      _FeatureTile(Icons.notifications, loc.getString('notifications'), '/notifications'),
      _FeatureTile(Icons.picture_as_pdf, loc.getString('export_options'), '/export_options'),
      _FeatureTile(Icons.alarm, loc.getString('reminders_title'), '/reminders'),
  _FeatureTile(Icons.insights, loc.getString('stats_overview_title'), '/stats'),
      _FeatureTile(Icons.local_florist, loc.getString('alternative_medicine'), '/alternative_medicine'),
      _FeatureTile(Icons.settings, loc.getString('settings'), '/settings'),
  _FeatureTile(Icons.info, loc.getString('about_hemoai'), '/about'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(loc.getString('continue_as_guest'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline),
                    const SizedBox(width: 12),
                    Expanded(child: Text(loc.getString('guest_mode_description'))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                      child: Text(loc.getString('go_to_main_panel')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: tiles.length,
                itemBuilder: (_, i) => _FeatureCard(tile: tiles[i], onTap: _nav),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile {
  final IconData icon;
  final String label;
  final String route;
  _FeatureTile(this.icon, this.label, this.route);
}

class _FeatureCard extends StatelessWidget {
  final _FeatureTile tile;
  final void Function(String) onTap;
  const _FeatureCard({required this.tile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(tile.route),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tile.icon, size: 36, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  tile.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

