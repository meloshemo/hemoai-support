import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';
import '../../services/preferences_service.dart';

class OnboardingGoalsScreen extends StatefulWidget {
  const OnboardingGoalsScreen({super.key});

  @override
  State<OnboardingGoalsScreen> createState() => _OnboardingGoalsScreenState();
}

class _OnboardingGoalsScreenState extends State<OnboardingGoalsScreen> {
  int _waterGoal = 8;
  String _dietGoal = 'balanced';

  Future<void> _finish() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setWaterDailyGoal(_waterGoal);
    await prefs.setDietGoalType(_dietGoal);
    await prefs.setOnboardingCompleted(true);
    await prefs.setFirstLaunch(false);
    // If not logged in, enable guest mode for now; dashboard can surface upgrade prompts
    if (!prefs.isUserLoggedIn()) {
      await prefs.setGuestMode(true);
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.getString('goals_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding/profile'),
          tooltip: loc.getString('back'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.getString('water_goal_prompt')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _waterGoal.toDouble(),
                      min: 4,
                      max: 16,
                      divisions: 12,
                      label: _waterGoal.toString(),
                      onChanged: (v) => setState(() => _waterGoal = v.round()),
                    ),
                  ),
                  Text('$_waterGoal')
                ],
              ),
              const SizedBox(height: 16),
              Text(loc.getString('diet_goal')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DietChip(
                    label: loc.getString('diet_goal_balanced'),
                    selected: _dietGoal == 'balanced',
                    onTap: () => setState(() => _dietGoal = 'balanced'),
                  ),
                  _DietChip(
                    label: loc.getString('diet_goal_weight_loss'),
                    selected: _dietGoal == 'weight_loss',
                    onTap: () => setState(() => _dietGoal = 'weight_loss'),
                  ),
                  _DietChip(
                    label: loc.getString('diet_goal_iron_support'),
                    selected: _dietGoal == 'iron_support',
                    onTap: () => setState(() => _dietGoal = 'iron_support'),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _finish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(loc.getString('finish')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DietChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DietChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFFFE0E0),
      labelStyle: TextStyle(color: selected ? const Color(0xFFE53E3E) : null),
      side: BorderSide(color: selected ? const Color(0xFFE53E3E) : Colors.grey.shade300),
    );
  }
}
