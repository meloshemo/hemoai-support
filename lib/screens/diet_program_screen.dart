import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../widgets/app_drawer.dart';
import '../services/preferences_service.dart';
import '../services/localization_service.dart';
import '../services/diet_program_service.dart';
import '../models/diet_program.dart';
import '../services/database_helper.dart';
import '../utils/responsive_helper.dart';

class DietProgramScreen extends StatefulWidget {
  const DietProgramScreen({super.key});

  @override
  State<DietProgramScreen> createState() => _DietProgramScreenState();
}

class _DietProgramScreenState extends State<DietProgramScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _userId;
  Map<String, bool> _todayMeals = {'breakfast': false, 'lunch': false, 'dinner': false, 'snack': false};
  int _selectedWeekday = DateTime.now().weekday; // 1=Monday, 7=Sunday

  Future<_DietData> _loadData() async {
    final prefs = await PreferencesService.getInstance();
    final user = prefs.getUserInfo();
    final int age = (user != null && user['age'] is int) ? (user['age'] as int) : 30;
    final Map<String, double>? lastValues = prefs.getLastHemogramValues();
    _userId = prefs.getCurrentUserId();

    final service = DietProgramService();
    final programs = service.generate(values: lastValues ?? {});
    final ageGroupKey = service.ageGroupFor(age);

    return _DietData(
      age: age,
      ageGroupKey: ageGroupKey,
      programs: programs,
      hasMeasuredValues: lastValues != null && lastValues.isNotEmpty,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Set Sunday as index 0 for Turkish week starting from Sunday
    _selectedWeekday = (DateTime.now().weekday == 7) ? 0 : DateTime.now().weekday;
    // Defer tracking load until after first frame to ensure context initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTracking();
    });
  }

  Future<void> _loadTracking() async {
    try {
      final prefs = await PreferencesService.getInstance();
      _userId = prefs.getCurrentUserId();
      final db = DatabaseHelper.instance;
      final today = DateTime.now().toIso8601String().split('T')[0];
      if (_userId != null) {
        final row = await db.getDietTrackingForDate(_userId!, today);
        if (mounted) {
          setState(() {
            _todayMeals = {
              'breakfast': (row?['breakfast'] ?? 0) == 1,
              'lunch': (row?['lunch'] ?? 0) == 1,
              'dinner': (row?['dinner'] ?? 0) == 1,
              'snack': (row?['snack'] ?? 0) == 1,
            };
          });
        }
        // Optionally, load weekly stats here in the future.
      } else {
        // Not logged in: nothing to load.
      }
    } catch (_) {
      // Ignore tracking load errors silently
    }
  }

  Future<void> _toggleMeal(String key, bool value) async {
    setState(() {
      _todayMeals[key] = value;
    });
    final prefs = await PreferencesService.getInstance();
    final userId = prefs.getCurrentUserId();
    if (userId == null) return;
    final db = DatabaseHelper.instance;
    final today = DateTime.now().toIso8601String().split('T')[0];
    await db.upsertDietTracking(
      userId: userId,
      date: today,
      breakfast: _todayMeals['breakfast'] ?? false,
      lunch: _todayMeals['lunch'] ?? false,
      dinner: _todayMeals['dinner'] ?? false,
      snack: _todayMeals['snack'] ?? false,
    );
    // refresh weekly
    await db.getDietTrackingForLast7Days(userId); // fetched but not used yet
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
  backgroundColor: cs.surface,
      drawer: const AppDrawer(currentRoute: '/diet_program'),
      appBar: AppBar(
        title: Consumer<LocalizationService>(
          builder: (context, localization, child) => Text(localization.getString('personal_diet_program')),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        actions: [
          // Copy current day's menu
          Builder(builder: (context) {
            return IconButton(
              tooltip: Provider.of<LocalizationService>(context, listen: false).getString('copy_day_menu'),
              icon: const Icon(Icons.copy_all_rounded),
              onPressed: () async {
                final loc = Provider.of<LocalizationService>(context, listen: false);
                final text = _buildSelectedDayShareText(loc, _selectedWeekday);
                await Clipboard.setData(ClipboardData(text: text));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.getString('day_menu_copied'))),
                  );
                }
              },
            );
          }),
          Builder(builder: (context) {
            return IconButton(
              tooltip: Provider.of<LocalizationService>(context, listen: false).getString('share_day_menu'),
              icon: const Icon(Icons.ios_share),
              onPressed: () {
                final loc = Provider.of<LocalizationService>(context, listen: false);
                final text = _buildSelectedDayShareText(loc, _selectedWeekday);
                Share.share(text);
              },
            );
          })
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          tabs: [
            Tab(text: Provider.of<LocalizationService>(context, listen: true).getString('diet_recommendations')),
            Tab(text: Provider.of<LocalizationService>(context, listen: true).getString('weekly_plan')),
          ],
        ),
      ),
      body: Consumer<LocalizationService>(
        builder: (context, localization, child) => FutureBuilder<_DietData>(
          future: _loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(child: CircularProgressIndicator(color: cs.primary));
            }
            if (!snapshot.hasData) {
              return Center(child: Text(localization.getString('no_data_available')));
            }
            final data = snapshot.data!;

            final ageGroupLabel = localization.getString(data.ageGroupKey);
            final suitabilityText = localization.getStringWithParams('suitable_for_age', {
              'age_group': ageGroupLabel,
            });

            Widget todayTab = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: ResponsiveHelper.getScreenPadding(context).copyWith(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu, size: ResponsiveHelper.getIconSize(context, 28), color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            localization.getString('diet_recommendations_title'),
                            style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 20), fontWeight: FontWeight.bold, color: cs.onSurface),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              final data = snapshot.data!;
                              final buffer = StringBuffer();
                              buffer.writeln(localization.getString('diet_share_message_prefix'));
                              buffer.writeln();
                              for (final p in data.programs) {
                                buffer.writeln('• ${localization.getString(p.titleKey)}');
                                buffer.writeln(localization.getString(p.descriptionKey));
                                buffer.writeln(localization.getString(p.includeKey));
                                buffer.writeln(localization.getString(p.limitKey));
                                if (p.macrosKey != null) {
                                  buffer.writeln(localization.getString(p.macrosKey!));
                                }
                                if (p.sampleMenuKey != null) {
                                  buffer.writeln(localization.getString(p.sampleMenuKey!));
                                }
                                buffer.writeln();
                              }
                              Share.share(buffer.toString());
                            },
                            icon: Icon(Icons.share, color: cs.primary),
                            label: Text(localization.getString('diet_share_button')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localization.getString('diet_program_description'),
                        style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 14), color: cs.onSurface.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.check_box_outlined, size: ResponsiveHelper.getIconSize(context, 20), color: cs.primary),
                          const SizedBox(width: 8),
                          Text(localization.getString('diet_toggle_hint'), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: cs.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _mealRow(context, 'meal_breakfast', 'breakfast'),
                              const Divider(height: 16),
                              _mealRow(context, 'meal_lunch', 'lunch'),
                              const Divider(height: 16),
                              _mealRow(context, 'meal_dinner', 'dinner'),
                              const Divider(height: 16),
                              _mealRow(context, 'meal_snack', 'snack'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: Icon(Icons.cake, size: 18, color: cs.onPrimary),
                          label: Text(suitabilityText, style: TextStyle(color: cs.onPrimary)),
                          backgroundColor: cs.primary,
                        ),
                      ),
                      if (!data.hasMeasuredValues) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: cs.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  localization.getString('enter_hemogram_values'),
                                  style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 14), color: cs.onSurface),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/hemogram_entry'),
                                child: Text(localization.getString('go_to_hemogram_entry')),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: ResponsiveHelper.getScreenPadding(context).copyWith(top: 8),
                    itemCount: data.programs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final DietProgram program = data.programs[index];
                      return _DietCard(program: program);
                    },
                  ),
                ),
              ],
            );

            Widget weekTab = Padding(
              padding: ResponsiveHelper.getScreenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with toggle button
                  Row(
                    children: [
                      Icon(Icons.restaurant_menu, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        localization.getString('diet_recommendations'),
                        style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 18), fontWeight: FontWeight.bold, color: cs.onSurface),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person, color: cs.onPrimary, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              localization.getString('for_you'),
                              style: TextStyle(color: cs.onPrimary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localization.getString('hemogram_based_nutrition_plan'),
                    style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 14), color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Weekly tabs as ChoiceChips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(7, (index) {
                        final dayKeys = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
                        final selected = _selectedWeekday == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(localization.getString(dayKeys[index])),
                            selected: selected,
                            onSelected: (_) => setState(() => _selectedWeekday = index),
                            selectedColor: cs.primary,
                            labelStyle: TextStyle(color: selected ? cs.onPrimary : cs.onSurface),
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Hemoglobin Support Diet section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.bloodtype, color: cs.onPrimary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                localization.getString('hemoglobin_support_diet'),
                                style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 16), fontWeight: FontWeight.w600, color: cs.onSurface),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localization.getString('hemoglobin_diet_description'),
                          style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 14), color: cs.onSurface),
                        ),
                        const SizedBox(height: 12),
                        
                        // Nutritional recommendations
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.green.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              localization.getString('increase_consumption'),
                              style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 14), fontWeight: FontWeight.w600, color: Colors.green.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localization.getString('iron_rich_foods_list'),
                          style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 13), color: cs.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.trending_down, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              localization.getString('limit_consumption'),
                              style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 14), fontWeight: FontWeight.w600, color: Colors.orange.shade800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localization.getString('iron_inhibiting_foods_list'),
                          style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 13), color: cs.onSurface),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Daily menu for selected day
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(_selectedWeekday),
                        child: _buildDailyMenu(localization, _selectedWeekday),
                      ),
                    ),
                  ),
                ],
              ),
            );

            return TabBarView(
              controller: _tabController,
              children: [todayTab, weekTab],
            );
          },
        ),
      ),
    );
  }

  Widget _mealRow(BuildContext context, String labelKey, String stateKey) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final checked = _todayMeals[stateKey] ?? false;
    return Row(
      children: [
        Expanded(child: Text(loc.getString(labelKey), style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface))),
        Builder(builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Switch(
            value: checked,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return cs.onPrimary;
              return cs.outlineVariant;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return cs.primary;
              return cs.outlineVariant;
            }),
            onChanged: (v) => _toggleMeal(stateKey, v),
          );
        }),
      ],
    );
  }

  Widget _buildDailyMenu(LocalizationService localization, int dayIndex) {
  final cs = Theme.of(context).colorScheme;
    final dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    final selectedDay = dayNames[dayIndex];
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: cs.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${localization.getString(selectedDay)} — ${localization.getString('daily_menu')}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Breakfast
          _buildMealSection(
            localization,
            Icons.wb_sunny,
            'breakfast',
            _getMealMenu(localization, 'breakfast', selectedDay),
          ),
          const SizedBox(height: 12),
          
          // Lunch
          _buildMealSection(
            localization,
            Icons.restaurant,
            'lunch',
            _getMealMenu(localization, 'lunch', selectedDay),
          ),
          const SizedBox(height: 12),
          
          // Snack
          _buildMealSection(
            localization,
            Icons.coffee,
            'snack',
            _getMealMenu(localization, 'snack', selectedDay),
          ),
          const SizedBox(height: 12),
          
          // Dinner
          _buildMealSection(
            localization,
            Icons.dinner_dining,
            'dinner',
            _getMealMenu(localization, 'dinner', selectedDay),
          ),
        ],
      ),
    );
  }

  Widget _buildMealSection(LocalizationService localization, IconData icon, String mealKey, String menuText) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                localization.getString(mealKey),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            menuText,
            style: TextStyle(fontSize: 14, color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  String _getMealMenu(LocalizationService localization, String mealType, String dayName) {
    // Static key mapping to avoid dynamic string interpolation issues with validator
    final mealKeys = {
      'breakfast_sunday': 'breakfast_menu_sunday',
      'breakfast_monday': 'breakfast_menu_monday',
      'breakfast_tuesday': 'breakfast_menu_tuesday',
      'breakfast_wednesday': 'breakfast_menu_wednesday',
      'breakfast_thursday': 'breakfast_menu_thursday',
      'breakfast_friday': 'breakfast_menu_friday',
      'breakfast_saturday': 'breakfast_menu_saturday',
      'lunch_sunday': 'lunch_menu_sunday',
      'lunch_monday': 'lunch_menu_monday',
      'lunch_tuesday': 'lunch_menu_tuesday',
      'lunch_wednesday': 'lunch_menu_wednesday',
      'lunch_thursday': 'lunch_menu_thursday',
      'lunch_friday': 'lunch_menu_friday',
      'lunch_saturday': 'lunch_menu_saturday',
      'snack_sunday': 'snack_menu_sunday',
      'snack_monday': 'snack_menu_monday',
      'snack_tuesday': 'snack_menu_tuesday',
      'snack_wednesday': 'snack_menu_wednesday',
      'snack_thursday': 'snack_menu_thursday',
      'snack_friday': 'snack_menu_friday',
      'snack_saturday': 'snack_menu_saturday',
      'dinner_sunday': 'dinner_menu_sunday',
      'dinner_monday': 'dinner_menu_monday',
      'dinner_tuesday': 'dinner_menu_tuesday',
      'dinner_wednesday': 'dinner_menu_wednesday',
      'dinner_thursday': 'dinner_menu_thursday',
      'dinner_friday': 'dinner_menu_friday',
      'dinner_saturday': 'dinner_menu_saturday',
    };
    
    final lookupKey = '${mealType}_$dayName';
    final actualKey = mealKeys[lookupKey];
    
    String fallbackFor(String meal) {
      switch (meal) {
        case 'breakfast':
          return localization.getString('default_breakfast_menu');
        case 'lunch':
          return localization.getString('default_lunch_menu');
        case 'snack':
          return localization.getString('default_snack_menu');
        case 'dinner':
          return localization.getString('default_dinner_menu');
        default:
          return '';
      }
    }

    if (actualKey != null) {
      try {
        return localization.getString(actualKey);
      } catch (e) {
        return fallbackFor(mealType);
      }
    } else {
      return fallbackFor(mealType);
    }
  }

  String _buildSelectedDayShareText(LocalizationService localization, int dayIndex) {
    final dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    final dayKey = dayNames[dayIndex];
    final title = localization.getString('share_day_menu_title');
    final dayLabel = localization.getString(dayKey);
    final b = StringBuffer();
    b.writeln('$title — $dayLabel');
    b.writeln();
    String mealLine(String mealKey) {
      final header = localization.getString(mealKey);
      final menu = _getMealMenu(localization, mealKey, dayKey);
      return '[$header]\n$menu';
    }
    b.writeln(mealLine('breakfast'));
    b.writeln();
    b.writeln(mealLine('lunch'));
    b.writeln();
    b.writeln(mealLine('snack'));
    b.writeln();
    b.writeln(mealLine('dinner'));
    return b.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _DietCard extends StatelessWidget {
  final DietProgram program;
  const _DietCard({required this.program});

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0.5,
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.getString(program.titleKey),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.primary),
            ),
            const SizedBox(height: 6),
            Text(
              localization.getString(program.descriptionKey),
              style: TextStyle(fontSize: 14, color: cs.onSurface),
            ),
            const SizedBox(height: 12),
            if (program.macrosKey != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.pie_chart_outline, color: Colors.deepPurple.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localization.getString(program.macrosKey!),
                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localization.getString(program.includeKey),
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.block, color: Colors.redAccent.shade200),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localization.getString(program.limitKey),
                    style: TextStyle(fontSize: 14, color: cs.onSurface),
                  ),
                ),
              ],
            ),
            if (program.sampleMenuKey != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.menu_book, color: Colors.teal.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localization.getString(program.sampleMenuKey!),
                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DietData {
  final int age;
  final String ageGroupKey;
  final List<DietProgram> programs;
  final bool hasMeasuredValues;

  _DietData({
    required this.age,
    required this.ageGroupKey,
    required this.programs,
    required this.hasMeasuredValues,
  });
}
