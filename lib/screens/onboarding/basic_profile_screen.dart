import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';
import '../../services/preferences_service.dart';

class OnboardingBasicProfileScreen extends StatefulWidget {
  const OnboardingBasicProfileScreen({super.key});

  @override
  State<OnboardingBasicProfileScreen> createState() => _OnboardingBasicProfileScreenState();
}

class _OnboardingBasicProfileScreenState extends State<OnboardingBasicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'male';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndNext() async {
    if (!_formKey.currentState!.validate()) return;
    final prefs = await PreferencesService.getInstance();
    final age = int.tryParse(_ageCtrl.text.trim()) ?? 0;
    await prefs.setUserInfo(_nameCtrl.text.trim(), '', '');
    await prefs.setPersonalInfo(age, _gender, 0, 0);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/onboarding/goals');
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.getString('basic_profile_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding/language'),
          tooltip: loc.getString('back'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: loc.getString('name'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? loc.getString('name_required') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: loc.getString('age'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = int.tryParse((v ?? '').trim());
                    if (t == null || t < 0) return loc.getString('please_fill_all_fields');
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: loc.getString('gender'),
                    border: const OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _gender,
                      items: [
                        DropdownMenuItem(value: 'male', child: Text(loc.getString('male'))),
                        DropdownMenuItem(value: 'female', child: Text(loc.getString('female'))),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'male'),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveAndNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53E3E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(loc.getString('next')),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.getString('complete_later_hint'),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
