import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';

class OnboardingLanguageScreen extends StatefulWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  State<OnboardingLanguageScreen> createState() => _OnboardingLanguageScreenState();
}

class _OnboardingLanguageScreenState extends State<OnboardingLanguageScreen> {
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    final loc = Provider.of<LocalizationService>(context, listen: false);
    _selectedCode = loc.currentLanguageCode;
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.getString('select_language')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding/welcome'),
          tooltip: loc.getString('back'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding/profile'),
            child: Text(loc.getString('skip')),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: loc.supportedLocales.length,
        itemBuilder: (context, index) {
          final code = loc.supportedLocales[index].languageCode;
          final name = loc.languageNames[code] ?? code;
          final flag = loc.languageFlags[code] ?? '🌐';
          final selected = _selectedCode == code;
          return ListTile(
            leading: Text(flag, style: const TextStyle(fontSize: 24)),
            title: Text(name),
            trailing: selected ? const Icon(Icons.check, color: Color(0xFFE53E3E)) : null,
            onTap: () async {
              setState(() => _selectedCode = code);
              await loc.changeLanguage(code);
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding/profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(loc.getString('next')),
            ),
          ),
        ),
      ),
    );
  }
}
