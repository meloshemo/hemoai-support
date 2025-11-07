import 'package:flutter/material.dart';
import '../utils/color_compat.dart';
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
import '../services/wellness_service.dart';
import '../services/ai_diet_menu_service.dart';

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
  String _selectedFilter = 'all';
  List<Map<String, dynamic>>? _weeklyProgress;
  static const Map<String, Map<String, double>> _ref = {
    'hemoglobin': {'min': 12.0, 'max': 17.0},
    'iron': {'min': 60.0, 'max': 170.0},
    'white_blood_cells': {'min': 4.0, 'max': 11.0},
    'glucose': {'min': 70.0, 'max': 100.0},
    'calcium': {'min': 8.6, 'max': 10.2},
    'sodium': {'min': 135.0, 'max': 145.0},
    'potassium': {'min': 3.5, 'max': 5.1},
    'chloride': {'min': 98.0, 'max': 106.0},
    'alt': {'min': 0.0, 'max': 40.0},
    'ast': {'min': 0.0, 'max': 40.0},
    'ggt': {'min': 0.0, 'max': 60.0},
    'total_bilirubin': {'min': 0.0, 'max': 1.2},
    'direct_bilirubin': {'min': 0.0, 'max': 0.3},
    'crp': {'min': 0.0, 'max': 5.0},
    'tsh': {'min': 0.4, 'max': 4.0},
    'free_t3': {'min': 2.0, 'max': 4.4},
    'free_t4': {'min': 0.9, 'max': 1.7},
    'vitamin_d3': {'min': 20.0, 'max': 100.0},
    'vitamin_b12': {'min': 200.0, 'max': 900.0},
  };

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
      values: Map<String, double>.from(lastValues ?? {}),
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
        final weekly = await db.getDietTrackingForLast7Days(_userId!);
        if (mounted) {
          setState(() {
            _todayMeals = {
              'breakfast': (row?['breakfast'] ?? 0) == 1,
              'lunch': (row?['lunch'] ?? 0) == 1,
              'dinner': (row?['dinner'] ?? 0) == 1,
              'snack': (row?['snack'] ?? 0) == 1,
            };
            _weeklyProgress = weekly;
          });
        }
      } else {
        // Not logged in: nothing to load.
      }
    } catch (_) {
      // Ignore tracking load errors silently
    }
  }

  List<Widget> _buildFilterChips(LocalizationService loc, ColorScheme cs) {
    final filters = <Map<String, String>>[
      {'key': 'all', 'label': 'diet_filter_all'},
      {'key': 'glucose', 'label': 'diet_filter_glucose'},
      {'key': 'liver', 'label': 'diet_filter_liver'},
      {'key': 'bilirubin', 'label': 'diet_filter_bilirubin'},
      {'key': 'crp', 'label': 'diet_filter_crp'},
      {'key': 'thyroid', 'label': 'diet_filter_thyroid'},
      {'key': 'vitamin_d3', 'label': 'diet_filter_vitd'},
      {'key': 'vitamin_b12', 'label': 'diet_filter_b12'},
      {'key': 'electrolytes', 'label': 'diet_filter_electrolytes'},
      {'key': 'calcium', 'label': 'diet_filter_calcium'},
      {'key': 'hemoglobin', 'label': 'diet_filter_hemoglobin'},
      {'key': 'iron', 'label': 'diet_filter_iron'},
      {'key': 'white_blood_cells', 'label': 'diet_filter_wbc'},
    ];
    return filters.map((f) {
      final selected = (_selectedFilter == f['key']);
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(loc.getString(f['label']!)),
          selected: selected,
          onSelected: (_) => setState(() => _selectedFilter = f['key']!),
          selectedColor: cs.primary,
          labelStyle: TextStyle(color: selected ? cs.onPrimary : cs.onSurface),
          backgroundColor: cs.surfaceContainerHighest,
        ),
      );
    }).toList();
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
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
  backgroundColor: cs.surface,
      drawer: canPop ? null : const AppDrawer(currentRoute: '/diet_program'),
      appBar: AppBar(
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: Provider.of<LocalizationService>(context, listen: false).getString('back'),
              )
            : null,
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
                final text = await _buildSelectedDayShareTextAsync(loc, _selectedWeekday);
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
              onPressed: () async {
                final loc = Provider.of<LocalizationService>(context, listen: false);
                final text = await _buildSelectedDayShareTextAsync(loc, _selectedWeekday);
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

            // Premium hero header + content
            Widget todayTab = ListView(
              padding: ResponsiveHelper.getScreenPadding(context).copyWith(bottom: 8),
              children: [
                _premiumHero(localization, data),
                const SizedBox(height: 12),
                _kpiRow(localization),
                if (_weeklyProgress != null) ...[
                  const SizedBox(height: 12),
                  _buildWeeklyProgressCard(localization),
                ],
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // AI Coach header row
                      Row(
                        children: [
                          Icon(Icons.psychology, size: ResponsiveHelper.getIconSize(context, 26), color: cs.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(localization.getString('ai_coach'), style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 18), fontWeight: FontWeight.w700, color: cs.onSurface))),
                          Text(localization.getString('view_all'), style: TextStyle(color: cs.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(localization.getString('ai_coach_sub'), style: TextStyle(fontSize: ResponsiveHelper.getFontSize(context, 14), color: cs.onSurface.withValues(alpha: 0.7))),

                      // Latest results card
                      const SizedBox(height: 12),
                      if (data.hasMeasuredValues)
                        _buildLatestResultsCard(localization, data.values),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.check_box_outlined, size: ResponsiveHelper.getIconSize(context, 20), color: cs.primary),
                          const SizedBox(width: 8),
                          Text(localization.getString('diet_toggle_hint'), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outlineVariant),
                          gradient: LinearGradient(colors: [cs.surface, cs.surfaceContainerHighest], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0,4))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            _mealRow(context, 'meal_breakfast', 'breakfast'),
                            const Divider(height: 20),
                            _mealRow(context, 'meal_lunch', 'lunch'),
                            const Divider(height: 20),
                            _mealRow(context, 'meal_dinner', 'dinner'),
                            const Divider(height: 20),
                            _mealRow(context, 'meal_snack', 'snack'),
                          ]),
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

                      const SizedBox(height: 12),
                      // Filters row
                      Text(
                        localization.getString('diet_filters_title'),
                        style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _buildFilterChips(localization, cs),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (data.hasMeasuredValues)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.recommend, color: cs.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  localization.getString('diet_personalized_header'),
                                  style: TextStyle(color: cs.onSurface),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (data.hasMeasuredValues) ...[
                        const SizedBox(height: 12),
                        // Smart suggestions also in Today tab (requested)
                        Builder(builder: (_) {
                          final weekday = DateTime.now().weekday; // 1..7
                          final dayKey = _dayKeyFromWeekday(weekday);
                          return _buildSmartSuggestions(localization, data, dayKey, chipCount: 12, tipCount: 2);
                        }),
                      ],
                    ],
                ),
                const SizedBox(height: 8),
                ...(() {
                  // Build a day-curated list of programs for Today tab
                  final weekday = DateTime.now().weekday; // 1..7
                  final dayKey = _dayKeyFromWeekday(weekday);
                  List<DietProgram> curated = _programsForDay(data, dayKey);
                  // Apply filter if any
                  final filtered = curated.where((p) => _selectedFilter == 'all' ? true : p.riskTag == _selectedFilter).toList();
                  // Optionally limit to top N for a concise Today view
                  final limited = filtered.take(8).toList();
                  final widgets = <Widget>[];
                  for (int i = 0; i < limited.length; i++) {
                    widgets.add(_DietCard(program: limited[i]));
                    if (i < limited.length - 1) widgets.add(const SizedBox(height: 12));
                  }
                  return widgets;
                })(),
              ],
            );

            Widget weekTab = ListView(
              padding: ResponsiveHelper.getScreenPadding(context),
              children: [
                _premiumHero(localization, data),
                const SizedBox(height: 12),
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

                // Smart, actionable suggestions (integrated look)
                Builder(builder: (_) {
                  final dayKeys = ['sunday','monday','tuesday','wednesday','thursday','friday','saturday'];
                  final dayKey = dayKeys[_selectedWeekday];
                  return _buildSmartSuggestions(localization, data, dayKey, chipCount: 12, tipCount: 2);
                }),
                const SizedBox(height: 16),

                // Daily menu for selected day (non-nested scroll)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: KeyedSubtree(
                    key: ValueKey(_selectedWeekday),
                    child: _buildDailyMenu(localization, data, _selectedWeekday),
                  ),
                ),
              ],
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

  Widget _buildLatestResultsCard(LocalizationService loc, Map<String, double> values) {
    final cs = Theme.of(context).colorScheme;
    // Order keys for display
    final ordered = [
      'glucose','alt','ast','ggt','total_bilirubin','direct_bilirubin','crp','tsh','free_t3','free_t4','vitamin_d3','vitamin_b12','sodium','potassium','chloride','calcium','hemoglobin','iron','white_blood_cells'
    ].where((k) => values.containsKey(k)).toList();

    // AI-like summary: count abnormalities
    int low = 0, high = 0;
    for (final k in ordered) {
      final v = values[k]!;
      final min = _ref[k]!['min']!;
      final max = _ref[k]!['max']!;
      if (v < min) low++; else if (v > max) high++;
    }
    String summaryKey;
    if (low == 0 && high == 0) summaryKey = 'overall_assessment_normal';
    else if (low + high <= 3) summaryKey = 'overall_assessment_some_abnormal';
    else summaryKey = 'overall_assessment_many_abnormal';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
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
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.science, color: cs.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(loc.getString('latest_results_title'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
              ),
              IconButton(
                tooltip: loc.getString('copy_values'),
                icon: const Icon(Icons.copy_all_rounded),
                onPressed: () async {
                  final buf = StringBuffer();
                  for (final k in ordered) {
                    buf.writeln('${loc.getString(k)}: ${values[k]!.toStringAsFixed(2)}');
                  }
                  await Clipboard.setData(ClipboardData(text: buf.toString()));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.getString('values_copied'))));
                  }
                },
              ),
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/analysis', arguments: values),
                icon: const Icon(Icons.open_in_new),
                label: Text(loc.getString('see_full_analysis')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ordered.map((k) => _buildValueChip(loc, k, values[k]!)).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.psychology, color: cs.secondary),
              const SizedBox(width: 6),
              Text(loc.getString('ai_interpretation_title'), style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 4),
          Text(loc.getString(summaryKey), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.8))),
          Text(loc.getString('ai_interpretation_hint'), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildValueChip(LocalizationService loc, String key, double value) {
    final cs = Theme.of(context).colorScheme;
    final min = _ref[key]!['min']!;
    final max = _ref[key]!['max']!;
    late Color bg; late Color fg; late IconData icon; late String statusKey;
    if (value < min) { bg = Colors.orange.withValues(alpha: 0.12); fg = Colors.orange.shade700; icon = Icons.trending_down; statusKey = 'status_low'; }
    else if (value > max) { bg = Colors.red.withValues(alpha: 0.12); fg = Colors.red.shade700; icon = Icons.trending_up; statusKey = 'status_high'; }
    else { bg = Colors.green.withValues(alpha: 0.12); fg = Colors.green.shade700; icon = Icons.check_circle; statusKey = 'status_normal'; }

    return GestureDetector(
      onTap: () => _showValueDetails(loc, key, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: fg.withValues(alpha: 0.3))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 16),
            const SizedBox(width: 6),
            Text('${loc.getString(key)}: ${value.toStringAsFixed(2)}', style: TextStyle(color: cs.onSurface)),
            const SizedBox(width: 6),
            Text(loc.getString(statusKey), style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // Premium hero header with gradient, category chip and CTA
  Widget _premiumHero(LocalizationService loc, _DietData data) {
    final cs = Theme.of(context).colorScheme;
    final weekday = DateTime.now().weekday;
    final dayKey = _dayKeyFromWeekday(weekday);
    final tag = data.hasMeasuredValues ? _tagForDay(data.values, dayKey) : 'general';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [cs.primary.withValues(alpha: 0.12), cs.secondary.withValues(alpha: 0.10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.getString('diet_premium_title'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(loc.getString('diet_premium_sub'), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.8))),
                const SizedBox(height: 10),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_iconFor(tag), color: cs.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(loc.getString(_labelKeyFor(tag)), style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/hemogram_entry'),
                    icon: const Icon(Icons.fact_check),
                    label: Text(loc.getString('edit_preferences')),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () => _tabController.index = 1,
            child: Text(loc.getString('start_today')),
          ),
        ],
      ),
    );
  }

  // KPI mini cards (placeholder values)
  Widget _kpiRow(LocalizationService loc) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<WellnessService>(
      builder: (context, wellness, _) {
        Widget kpi({
          required IconData icon,
          required String title,
          required String value,
          required VoidCallback onTap,
          required VoidCallback onLongPress,
        }) {
          return Expanded(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: cs.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.8))),
                      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    ]),
                  ),
                ]),
              ),
            ),
          );
        }

        final kcal = wellness.calories;
        final waterMl = wellness.waterMl;
        final steps = wellness.steps;

        String kcalText = '$kcal ${loc.getString('kcal_unit')}';
        String waterText = '$waterMl ${loc.getString('ml_unit')}';
        String stepsText = '$steps';

        return Row(children: [
          kpi(
            icon: Icons.local_fire_department,
            title: loc.getString('kpi_calories'),
            value: kcalText,
            onTap: () => wellness.addCalories(100),
            onLongPress: () async {
              final v = await _promptForInt(loc,
                  title: loc.getString('set_value'),
                  initial: wellness.calories,
                  unit: loc.getString('kcal_unit'));
              if (v != null) {
                await wellness.setCalories(v);
              }
            },
          ),
          const SizedBox(width: 8),
          kpi(
            icon: Icons.water_drop,
            title: loc.getString('kpi_hydration'),
            value: waterText,
            onTap: () => wellness.addWater(250),
            onLongPress: () async {
              final v = await _promptForInt(loc,
                  title: loc.getString('set_value'),
                  initial: wellness.waterMl,
                  unit: loc.getString('ml_unit'));
              if (v != null) {
                await wellness.setWater(v);
              }
            },
          ),
          const SizedBox(width: 8),
          kpi(
            icon: Icons.directions_walk,
            title: loc.getString('kpi_steps'),
            value: stepsText,
            onTap: () => wellness.addSteps(500),
            onLongPress: () async {
              final v = await _promptForInt(loc,
                  title: loc.getString('set_value'),
                  initial: wellness.steps,
                  unit: '');
              if (v != null) {
                await wellness.setSteps(v);
              }
            },
          ),
        ]);
      },
    );
  }

  Future<int?> _promptForInt(LocalizationService loc, {required String title, required int initial, required String unit}) async {
    final controller = TextEditingController(text: initial.toString());
    final cs = Theme.of(context).colorScheme;
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cs.surface,
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
            decoration: InputDecoration(
              labelText: loc.getString('enter_value'),
              suffixText: unit.isNotEmpty ? unit : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(loc.getString('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final raw = controller.text.trim();
                final parsed = int.tryParse(raw);
                if (parsed == null) {
                  Navigator.of(context).pop(null);
                } else {
                  Navigator.of(context).pop(parsed);
                }
              },
              child: Text(loc.getString('ok')),
            ),
          ],
        );
      },
    );
  }

  void _showValueDetails(LocalizationService loc, String key, double value) {
    final cs = Theme.of(context).colorScheme;
    final min = _ref[key]!['min']!;
    final max = _ref[key]!['max']!;
    final tag = _riskTagForKey(key);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(loc.getString(key), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Text('${loc.getString('value')}: ${value.toStringAsFixed(2)}'),
              Text(loc.getStringWithParams('normal_range_template', {'min': min.toStringAsFixed(1), 'max': max.toStringAsFixed(1)})),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _selectedFilter = tag);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.filter_alt),
                    label: Text(loc.getString('filter_to_category')),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/analysis'),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(loc.getString('see_full_analysis')),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  String _riskTagForKey(String key) {
    switch (key) {
      case 'glucose':
        return 'glucose';
      case 'alt':
      case 'ast':
      case 'ggt':
        return 'liver';
      case 'total_bilirubin':
      case 'direct_bilirubin':
        return 'bilirubin';
      case 'crp':
        return 'crp';
      case 'tsh':
      case 'free_t3':
      case 'free_t4':
        return 'thyroid';
      case 'vitamin_d3':
        return 'vitamin_d3';
      case 'vitamin_b12':
        return 'vitamin_b12';
      case 'sodium':
      case 'potassium':
      case 'chloride':
        return 'electrolytes';
      case 'calcium':
        return 'calcium';
      case 'hemoglobin':
        return 'hemoglobin';
      case 'iron':
        return 'iron';
      case 'white_blood_cells':
        return 'white_blood_cells';
      default:
        return 'general';
    }
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

  Widget _buildDailyMenu(LocalizationService localization, _DietData data, int dayIndex) {
  final cs = Theme.of(context).colorScheme;
    final dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    final selectedDay = dayNames[dayIndex];
    
    // Determine a single tag/program for the selected day to ensure consistency across meals,
    // while still rotating by day for variety
    final dayTag = data.hasMeasuredValues
        ? _tagForDay(data.values, selectedDay)
        : _fallbackTags()[_dayIndex(selectedDay) % _fallbackTags().length];
    final DietProgram? dayProgram = () {
      try {
        return data.programs.firstWhere((p) => p.riskTag == dayTag);
      } catch (_) {
        return data.programs.isNotEmpty ? data.programs.first : null;
      }
    }();

    return Column(
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
                const Spacer(),
                if (dayProgram != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.25))
                    ),
                    child: Row(children: [
                      Icon(_iconFor(dayProgram.riskTag), color: cs.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(localization.getString(_labelKeyFor(dayProgram.riskTag)), style: TextStyle(color: cs.onSurface, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
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
            dayProgram != null
                ? _getMealMenuFromProgram(localization, dayProgram, 'breakfast', selectedDay)
                : _getMealMenu(localization, data, 'breakfast', selectedDay),
            tag: dayProgram?.riskTag,
          ),
          const SizedBox(height: 12),
          
          // Lunch
          _buildMealSection(
            localization,
            Icons.restaurant,
            'lunch',
            dayProgram != null
                ? _getMealMenuFromProgram(localization, dayProgram, 'lunch', selectedDay)
                : _getMealMenu(localization, data, 'lunch', selectedDay),
            tag: dayProgram?.riskTag,
          ),
          const SizedBox(height: 12),
          
          // Snack
          _buildMealSection(
            localization,
            Icons.coffee,
            'snack',
            dayProgram != null
                ? _getMealMenuFromProgram(localization, dayProgram, 'snack', selectedDay)
                : _getMealMenu(localization, data, 'snack', selectedDay),
            tag: dayProgram?.riskTag,
          ),
          const SizedBox(height: 12),
          
          // Dinner
          _buildMealSection(
            localization,
            Icons.dinner_dining,
            'dinner',
            dayProgram != null
                ? _getMealMenuFromProgram(localization, dayProgram, 'dinner', selectedDay)
                : _getMealMenu(localization, data, 'dinner', selectedDay),
            tag: dayProgram?.riskTag,
          ),
      ],
    );
  }

  Widget _buildMealSection(LocalizationService localization, IconData icon, String mealKey, String menuText, {String? tag}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: tag != null ? _gradientFor(context, tag) : null,
        color: tag == null ? cs.surface : null,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.primary, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                localization.getString(mealKey),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
              const Spacer(),
              if (tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    localization.getString(_labelKeyFor(tag)),
                    style: TextStyle(color: cs.onPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
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

  String _getMealMenu(LocalizationService localization, _DietData data, String mealType, String dayName) {
    // If we have measured values, generate dynamic, tag-aware menus per day
    if (data.hasMeasuredValues) {
      final tag = _tagForDay(data.values, dayName);
      final program = data.programs.firstWhere(
        (p) => p.riskTag == tag,
        orElse: () => data.programs.isNotEmpty ? data.programs.first : (throw StateError('No diet programs')),
      );
      return _getMealMenuFromProgram(localization, program, mealType, dayName);
    }

    // Use localized per-day base menus when values are not measured
    return _baseMenuForDay(localization, mealType, dayName);
  }

  String _getMealMenuFromProgram(LocalizationService localization, DietProgram program, String mealType, String dayName) {
    // Use AI-powered menu service for rich, varied daily meals
    final aiService = AIDietMenuService();
    final dayIndex = _dayIndex(dayName);
    
    // Generate AI-powered menu for this specific day
    // Note: We use the hemogram values from the data context if available
    final dailyMenu = aiService.generateDailyMenu(
      riskTag: program.riskTag,
      dayIndex: dayIndex,
      hemogramValues: null, // Will be passed from context if needed
    );
    
    // Get items for this meal type
    final mealItems = dailyMenu[mealType] ?? [];
    
    // Localize and format the menu items
    final localizedItems = mealItems.map((key) {
      try {
        return localization.getString(key);
      } catch (_) {
        // Fallback: return a readable version of the key
        return key.replaceAll('diet_item_', '').replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
      }
    }).where((item) => item.isNotEmpty).toList();
    
    if (localizedItems.isEmpty) {
      // Fallback to base menu if AI service returns empty
      return _baseMenuForDay(localization, mealType, dayName);
    }
    
    // Format as bullet points
    final bullets = localizedItems.map((e) => '• $e').join('\n');
    return bullets;
  }

  // Returns the localized per-day base menu for the given meal type and day,
  // falling back to default_*_menu when a day-specific key is missing.
  String _baseMenuForDay(LocalizationService localization, String mealType, String dayName) {
    // Static key mapping to avoid dynamic string interpolation issues with validator
    const mealKeys = {
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

    final lookupKey = '${mealType}_$dayName';
    final actualKey = mealKeys[lookupKey];
    if (actualKey == null) return fallbackFor(mealType);
    try {
      return localization.getString(actualKey);
    } catch (_) {
      return fallbackFor(mealType);
    }
  }

  List<String> _enrichmentPool(LocalizationService loc, DietProgram program) {
    final lines = <String>[];
    String tryGet(String key) {
      try { return loc.getString(key); } catch (_) { return ''; }
    }
    if (program.sampleMenuKey != null) {
      lines.addAll(_splitLines(tryGet(program.sampleMenuKey!)));
    }
    lines.addAll(_splitLines(tryGet(program.includeKey)));
    // Deduplicate and sanitize
    final seen = <String>{};
    final result = <String>[];
    for (final l in lines) {
      final s = l.trim();
      if (s.isEmpty) continue;
      if (seen.add(s)) result.add(s);
    }
    return result;
  }

  List<String> _splitLines(String value) {
    return value
        .split('\n')
        .map((e) => e.replaceAll(RegExp(r'^[-•]\s*'), ''))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<String> _pickDeterministic(List<String> pool, int count, String seed) {
    if (pool.isEmpty) return const [];
    if (count >= pool.length) return List<String>.from(pool);
    final picks = <String>[];
    var idx = _hash(seed) % pool.length;
    // choose a coprime step to traverse pool evenly
    final steps = [3, 5, 7, 11];
    final step = steps[_hash(seed + '#') % steps.length];
    final used = <int>{};
    while (picks.length < count) {
      if (!used.contains(idx)) {
        picks.add(pool[idx]);
        used.add(idx);
      }
      idx = (idx + step) % pool.length;
    }
    return picks;
  }

  int _hash(String s) {
    // Simple FNV-1a 32-bit
    const int fnvOffset = 0x811C9DC5;
    const int fnvPrime = 0x01000193;
    int hash = fnvOffset;
    for (int i = 0; i < s.length; i++) {
      hash ^= s.codeUnitAt(i);
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  // Determine a priority tag for a given day based on abnormal values; rotate across tags for variety
  String _tagForDay(Map<String, double> values, String dayName) {
    final prioritized = _priorityTags(values);
    final pool = <String>[]
      ..addAll(prioritized)
      ..addAll(_fallbackTags().where((t) => !prioritized.contains(t)));
    final index = _dayIndex(dayName) % pool.length;
    return pool[index];
  }

  List<String> _fallbackTags() => const [
        'glucose','liver','bilirubin','crp','thyroid','vitamin_d3','vitamin_b12','electrolytes','calcium','hemoglobin','iron','white_blood_cells'
      ];

  int _dayIndex(String dayName) {
    const order = {
      'sunday': 0,
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
    };
    return order[dayName] ?? 0;
  }

  List<String> _priorityTags(Map<String, double> values) {
    final List<Map<String, dynamic>> entries = [];
    values.forEach((k, v) {
      if (!_ref.containsKey(k)) return;
      final min = _ref[k]!['min']!;
      final max = _ref[k]!['max']!;
      if (v < min || v > max) {
        final severity = v < min ? (min - v) / (min == 0 ? 1 : min) : (v - max) / (max == 0 ? 1 : max);
        final tag = _riskTagForKey(k);
        entries.add({'tag': tag, 'severity': severity});
      }
    });
    // Group by tag and take max severity per tag
    final Map<String, double> byTag = {};
    for (final e in entries) {
      final t = e['tag'] as String;
      final s = e['severity'] as double;
      byTag[t] = (byTag[t] ?? 0).clamp(0.0, double.infinity) < s ? s : byTag[t]!;
      byTag[t] ??= s;
    }
    final list = byTag.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.map((e) => e.key).toList();
  }

  String _dayKeyFromWeekday(int weekday) {
    // weekday: 1=Mon..7=Sun
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
      default:
        return 'sunday';
    }
  }

  List<DietProgram> _programsForDay(_DietData data, String dayKey) {
    if (data.programs.isEmpty) return const <DietProgram>[];
    final tag = data.hasMeasuredValues ? _tagForDay(data.values, dayKey) : null;
    final prioritizedTags = <String>[
      if (tag != null) tag,
      ..._priorityTags(data.values),
      ..._fallbackTags(),
    ];
    // Build unique-ordered list of programs by tag order
    final added = <String>{};
    final output = <DietProgram>[];
    for (final t in prioritizedTags) {
      for (final p in data.programs) {
        if (p.riskTag == t && added.add(p.titleKey)) {
          output.add(p);
        }
      }
    }
    // Ensure any remaining programs without recognized tags are appended
    for (final p in data.programs) {
      if (!added.contains(p.titleKey)) {
        output.add(p);
      }
    }
    return output;
  }

  String _defaultMealBase(LocalizationService loc, String mealType) {
    switch (mealType) {
      case 'breakfast':
        return loc.getString('default_breakfast_menu');
      case 'lunch':
        return loc.getString('default_lunch_menu');
      case 'snack':
        return loc.getString('default_snack_menu');
      case 'dinner':
      default:
        return loc.getString('default_dinner_menu');
    }
  }

  String _enrichmentLine(LocalizationService loc, DietProgram program, String mealType, String dayName) {
    // Try to derive a short enrichment line from program.includeKey or sampleMenuKey
    String source = '';
    try {
      source = loc.getString(program.sampleMenuKey ?? program.includeKey);
    } catch (_) {
      try {
        source = loc.getString(program.includeKey);
      } catch (_) {
        source = '';
      }
    }
    if (source.isEmpty) return '';
    // Split and pick a deterministic line per meal+day
    final lines = source.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (lines.isEmpty) return '';
    int base = _dayIndex(dayName);
    switch (mealType) {
      case 'breakfast':
        base += 0; break;
      case 'lunch':
        base += 1; break;
      case 'snack':
        base += 2; break;
      case 'dinner':
        base += 3; break;
    }
    final pick = lines[base % lines.length];
    return pick;
  }

  // New: Smart suggestions panel shown in Weekly Plan
  Widget _buildSmartSuggestions(LocalizationService loc, _DietData data, String dayKey, {int chipCount = 12, int tipCount = 2}) {
    final cs = Theme.of(context).colorScheme;
    final tag = data.hasMeasuredValues
        ? _tagForDay(data.values, dayKey)
        : _fallbackTags()[_dayIndex(dayKey) % _fallbackTags().length];
    DietProgram? program;
    try {
      program = data.programs.firstWhere((p) => p.riskTag == tag);
    } catch (_) {
      program = data.programs.isNotEmpty ? data.programs.first : null;
    }

    List<Widget> _chips(List<String> items, Color color) {
      return items.take(chipCount).map((t) => Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 6),
        child: Chip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: color.withValues(alpha: 0.35)),
          backgroundColor: color.withValues(alpha: 0.12),
          label: Text(t, style: TextStyle(color: cs.onSurface)),
        ),
      )).toList();
    }

    final includeLines = program != null ? _splitLines(_safeGet(loc, program.includeKey)) : const <String>[];
    final limitLines = program != null ? _splitLines(_safeGet(loc, program.limitKey)) : const <String>[];
    final tips = () {
      if (program == null) return const <String>[];
      final pool = _enrichmentPool(loc, program);
      if (pool.isEmpty) return const <String>[];
      return _pickDeterministic(pool, tipCount, 'tip|$dayKey');
    }();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.lightbulb, color: cs.onPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loc.getString('smart_nutrition_title'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text(loc.getString('smart_nutrition_subtitle'), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.primary.withValues(alpha: 0.25))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_iconFor(tag), color: cs.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(loc.getString(_labelKeyFor(tag)), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick actions
          Row(
            children: [
              Icon(Icons.flash_on, color: cs.primary),
              const SizedBox(width: 8),
              Text(loc.getString('quick_actions'), style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add_reminder'),
              icon: const Icon(Icons.alarm_add),
              label: Text(loc.getString('add_reminder')),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/analysis', arguments: data.values),
              icon: const Icon(Icons.analytics),
              label: Text(loc.getString('analysis')),
            ),
          ]),
          const SizedBox(height: 12),
          // Prefer / Limit chips
          if (includeLines.isNotEmpty) ...[
            Row(children: [Icon(Icons.thumb_up, color: Colors.green.shade700), const SizedBox(width: 8), Text(loc.getString('foods_to_prefer'), style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface))]),
            const SizedBox(height: 6),
            Wrap(children: _chips(includeLines, Colors.green.shade600)),
            const SizedBox(height: 12),
          ],
          if (limitLines.isNotEmpty) ...[
            Row(children: [Icon(Icons.block, color: Colors.orange.shade800), const SizedBox(width: 8), Text(loc.getString('foods_to_limit'), style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface))]),
            const SizedBox(height: 6),
            Wrap(children: _chips(limitLines, Colors.orange.shade700)),
            const SizedBox(height: 12),
          ],
          if (tips.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: cs.outlineVariant)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.tips_and_updates, color: cs.secondary),
                  const SizedBox(width: 8),
                  Text(loc.getString('today_tip'), style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                ]),
                const SizedBox(height: 6),
                ...tips.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• '),
                    Expanded(child: Text(t, style: TextStyle(color: cs.onSurface))),
                  ]),
                )),
              ]),
            ),

          const SizedBox(height: 12),
          // Expert dietitian suite per top markers
          Row(children: [
            Icon(Icons.local_hospital, color: cs.primary),
            const SizedBox(width: 8),
            Text(loc.getString('expert_suite_title'), style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
          ]),
          const SizedBox(height: 8),
          ...(() {
            final tags = data.hasMeasuredValues ? _priorityTags(data.values) : _fallbackTags();
            final show = tags.take(3).toList();
            return show.map((t) {
              final tips = _getExpertTipLines(loc, t);
              final weeks = _expertFollowupWeeks(t);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(_iconFor(t), color: cs.primary),
                    const SizedBox(width: 8),
                    Text(loc.getString(_labelKeyFor(t)), style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                  ]),
                  const SizedBox(height: 6),
                  if (tips.isNotEmpty)
                    ...tips.map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('• '),
                        Expanded(child: Text(line, style: TextStyle(color: cs.onSurface))),
                      ]),
                    )),
                  const SizedBox(height: 6),
                  Text(loc.getStringWithParams('expert_followup_template', {'weeks': weeks.toString()}), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.8))),
                ]),
              );
            }).toList();
          })(),
        ],
      ),
    );
  }

  String _safeGet(LocalizationService loc, String key) {
    try { return loc.getString(key); } catch (_) { return ''; }
  }

  List<String> _getExpertTipLines(LocalizationService loc, String tag) {
    final key = 'expert_tips_' + tag;
    final v = _safeGet(loc, key);
    if (v.isEmpty) return const <String>[];
    return _splitLines(v);
  }

  int _expertFollowupWeeks(String tag) {
    switch (tag) {
      case 'iron':
      case 'hemoglobin':
      case 'vitamin_b12':
      case 'vitamin_d3':
        return 8;
      case 'thyroid':
        return 6;
      case 'glucose':
      case 'liver':
      case 'bilirubin':
      case 'calcium':
        return 4;
      case 'crp':
      case 'electrolytes':
      case 'white_blood_cells':
        return 2;
      default:
        return 4;
    }
  }

  Future<String> _buildSelectedDayShareTextAsync(LocalizationService localization, int dayIndex) async {
    // Load latest data to ensure dynamic menus reflect current values
    final data = await _loadData();
    return _buildSelectedDayShareTextFromData(localization, data, dayIndex);
  }

  String _buildSelectedDayShareTextFromData(LocalizationService localization, _DietData data, int dayIndex) {
    final dayNames = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    final dayKey = dayNames[dayIndex];
    final title = localization.getString('share_day_menu_title');
    final dayLabel = localization.getString(dayKey);
    final b = StringBuffer();
    b.writeln('$title — $dayLabel');
    b.writeln();
    String mealLine(String mealKey) {
      final header = localization.getString(mealKey);
      final menu = _getMealMenu(localization, data, mealKey, dayKey);
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

  Widget _buildWeeklyProgressCard(LocalizationService loc) {
    if (_weeklyProgress == null || _weeklyProgress!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final cs = Theme.of(context).colorScheme;
    
    // Calculate streak and completion stats
    int streak = 0;
    int totalMeals = 0;
    int completedMeals = 0;
    
    for (var day in _weeklyProgress!) {
      final breakfast = (day['breakfast'] ?? 0) == 1;
      final lunch = (day['lunch'] ?? 0) == 1;
      final dinner = (day['dinner'] ?? 0) == 1;
      final snack = (day['snack'] ?? 0) == 1;
      
      final dayTotal = (breakfast ? 1 : 0) + (lunch ? 1 : 0) + (dinner ? 1 : 0) + (snack ? 1 : 0);
      completedMeals += dayTotal;
      totalMeals += 4;
      
      if (dayTotal == 4) streak++;
    }
    
    final completionPercent = totalMeals > 0 ? (completedMeals / totalMeals * 100).round() : 0;
    final streakEmoji = streak >= 7 ? '🔥' : streak >= 4 ? '⭐' : streak >= 1 ? '✨' : '🌱';
    final streakMessage = streak >= 7 ? loc.getString('diet_streak_fire')
        : streak >= 4 ? loc.getString('diet_streak_great')
        : streak >= 1 ? loc.getString('diet_streak_good')
        : loc.getString('diet_streak_start');
    
    // Calculate current day completion
    final today = DateTime.now();
    final todayKey = today.toIso8601String().split('T')[0];
    final todayData = _weeklyProgress!.firstWhere((d) => d['date'] == todayKey, orElse: () => {});
    final todayBreakfast = (todayData['breakfast'] ?? 0) == 1;
    final todayLunch = (todayData['lunch'] ?? 0) == 1;
    final todayDinner = (todayData['dinner'] ?? 0) == 1;
    final todaySnack = (todayData['snack'] ?? 0) == 1;
    final todayCompleted = (todayBreakfast ? 1 : 0) + (todayLunch ? 1 : 0) + (todayDinner ? 1 : 0) + (todaySnack ? 1 : 0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withValues(alpha: 0.15),
            Colors.deepPurple.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.trending_up, color: Colors.deepPurple, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          streakEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$streak ${loc.getString("days_streak")}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      streakMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Today's progress
          Text(
            loc.getString('today_progress'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: todayCompleted / 4,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            borderRadius: BorderRadius.circular(8),
            minHeight: 12,
          ),
          const SizedBox(height: 4),
          Text(
            '$todayCompleted / 4 ${loc.getString("meals_completed_today")}',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          
          // Weekly overview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.getString('weekly_completion'),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completionPercent%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: cs.outlineVariant,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.getString('total_meals'),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completedMeals / $totalMeals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    final icon = _iconFor(program.riskTag);
    final gradient = _gradientFor(context, program.riskTag);
    final tagKey = _labelKeyFor(program.riskTag);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localization.getString(program.titleKey),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      localization.getString(tagKey),
                      style: TextStyle(color: cs.onPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 6),
              Text(
                localization.getString(program.descriptionKey),
                style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.9)),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final text = StringBuffer()
                        ..writeln(localization.getString(program.titleKey))
                        ..writeln(localization.getString(program.descriptionKey))
                        ..writeln(localization.getString(program.includeKey))
                        ..writeln(localization.getString(program.limitKey));
                      if (program.macrosKey != null) text.writeln(localization.getString(program.macrosKey!));
                      if (program.sampleMenuKey != null) text.writeln(localization.getString(program.sampleMenuKey!));
                      await Clipboard.setData(ClipboardData(text: text.toString()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(localization.getString('diet_copy_plan'))),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_all_rounded),
                    label: Text(localization.getString('diet_copy_plan')),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      final text = StringBuffer()
                        ..writeln(localization.getString(program.titleKey))
                        ..writeln()
                        ..writeln(localization.getString(program.descriptionKey))
                        ..writeln(localization.getString(program.includeKey))
                        ..writeln(localization.getString(program.limitKey));
                      if (program.macrosKey != null) text.writeln(localization.getString(program.macrosKey!));
                      if (program.sampleMenuKey != null) text.writeln(localization.getString(program.sampleMenuKey!));
                      Share.share(text.toString());
                    },
                    icon: const Icon(Icons.ios_share),
                    label: Text(localization.getString('diet_share_plan')),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Helpers for UI enhancements

IconData _iconFor(String tag) {
  switch (tag) {
    case 'glucose':
      return Icons.bubble_chart;
    case 'liver':
      return Icons.local_dining;
    case 'bilirubin':
      return Icons.water_drop;
    case 'crp':
      return Icons.local_fire_department;
    case 'thyroid':
      return Icons.auto_awesome;
    case 'vitamin_d3':
      return Icons.wb_sunny;
    case 'vitamin_b12':
      return Icons.bolt;
    case 'electrolytes':
      return Icons.ev_station;
    case 'calcium':
      return Icons.health_and_safety;
    case 'hemoglobin':
      return Icons.bloodtype;
    case 'iron':
      return Icons.construction;
    case 'white_blood_cells':
      return Icons.coronavirus;
    default:
      return Icons.restaurant;
  }
}

LinearGradient _gradientFor(BuildContext context, String tag) {
  final cs = Theme.of(context).colorScheme;
  Color a = cs.surfaceContainerHighest;
  Color b = cs.surface;
  switch (tag) {
    case 'glucose':
      a = Colors.orange.withValues(alpha: 0.25); b = Colors.orange.withValues(alpha: 0.05); break;
    case 'liver':
      a = Colors.green.withValues(alpha: 0.25); b = Colors.green.withValues(alpha: 0.05); break;
    case 'bilirubin':
      a = Colors.amber.withValues(alpha: 0.25); b = Colors.amber.withValues(alpha: 0.05); break;
    case 'crp':
      a = Colors.deepPurple.withValues(alpha: 0.25); b = Colors.deepPurple.withValues(alpha: 0.05); break;
    case 'thyroid':
      a = Colors.purple.withValues(alpha: 0.25); b = Colors.purple.withValues(alpha: 0.05); break;
    case 'vitamin_d3':
      a = Colors.orangeAccent.withValues(alpha: 0.25); b = Colors.orangeAccent.withValues(alpha: 0.05); break;
    case 'vitamin_b12':
      a = Colors.blueGrey.withValues(alpha: 0.25); b = Colors.blueGrey.withValues(alpha: 0.05); break;
    case 'electrolytes':
      a = Colors.lightBlue.withValues(alpha: 0.25); b = Colors.lightBlue.withValues(alpha: 0.05); break;
    case 'calcium':
      a = Colors.teal.withValues(alpha: 0.25); b = Colors.teal.withValues(alpha: 0.05); break;
    case 'hemoglobin':
      a = Colors.red.withValues(alpha: 0.25); b = Colors.red.withValues(alpha: 0.05); break;
    case 'iron':
      a = Colors.brown.withValues(alpha: 0.25); b = Colors.brown.withValues(alpha: 0.05); break;
    case 'white_blood_cells':
      a = Colors.indigo.withValues(alpha: 0.25); b = Colors.indigo.withValues(alpha: 0.05); break;
  }
  return LinearGradient(colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight);
}

String _labelKeyFor(String tag) {
  switch (tag) {
    case 'glucose':
      return 'glucose';
    case 'liver':
      return 'liver_function';
    case 'bilirubin':
      return 'bilirubin';
    case 'crp':
      return 'crp';
    case 'thyroid':
      return 'thyroid_function';
    case 'vitamin_d3':
      return 'vitamin_d3';
    case 'vitamin_b12':
      return 'vitamin_b12';
    case 'electrolytes':
      return 'electrolytes';
    case 'calcium':
      return 'calcium';
    case 'hemoglobin':
      return 'hemoglobin';
    case 'iron':
      return 'iron';
    case 'white_blood_cells':
      return 'white_blood_cells';
    default:
      return 'diet_recommendations';
  }
}

class _DietData {
  final int age;
  final String ageGroupKey;
  final List<DietProgram> programs;
  final bool hasMeasuredValues;
  final Map<String, double> values;

  _DietData({
    required this.age,
    required this.ageGroupKey,
    required this.programs,
    required this.hasMeasuredValues,
    required this.values,
  });
}
