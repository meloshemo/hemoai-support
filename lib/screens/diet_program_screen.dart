// ignore_for_file: use_build_context_synchronously
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
import '../services/wellness_service.dart';
import '../services/ai_diet_menu_service.dart';
import '../services/water_service.dart';
import '../widgets/medical_disclaimer_banner.dart';
import 'dart:async';

class DietProgramScreen extends StatefulWidget {
  const DietProgramScreen({super.key});

  @override
  State<DietProgramScreen> createState() => _DietProgramScreenState();
}

class _DietProgramScreenState extends State<DietProgramScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  int? _userId;
  Map<String, bool> _todayMeals = {
    'breakfast': false,
    'lunch': false,
    'dinner': false,
    'snack': false
  };
  int _selectedWeekday = DateTime.now().weekday; // 1=Monday, 7=Sunday
  String _selectedFilter = 'all';
  List<Map<String, dynamic>>? _weeklyProgress;
  final AIDietMenuService _aiMenuService = AIDietMenuService();
  _DietData? _latestDietData;
  Map<String, Map<String, List<String>>> _aiWeeklyPlan = {};
  Map<String, String> _aiPlanDayTags = {};
  String? _aiPlanFocusTag;
  DateTime? _aiPlanGeneratedAt;
  bool _aiPlanDynamic = true;
  DietPlanSafetyReport? _aiPlanSafetyReport;
  static const List<String> _weekdayKeys = [
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
  ];
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
    final int age =
        (user != null && user['age'] is int) ? (user['age'] as int) : 30;
    Map<String, double>? lastValues = prefs.getLastHemogramValues();
    if (lastValues == null || lastValues.isEmpty) {
      lastValues = await prefs.loadActiveHemogramValues();
    }
    String? dateIso = prefs.getLastHemogramDate();
    if ((dateIso == null || dateIso.isEmpty) && lastValues != null) {
      dateIso = prefs.getLastHemogramDate();
    }
    final DateTime? lastTestDate = (dateIso != null && dateIso.isNotEmpty)
        ? DateTime.tryParse(dateIso)
        : null;
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
      latestTestDate: lastTestDate,
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    // Set Sunday as index 0 for Turkish week starting from Sunday
    _selectedWeekday =
        (DateTime.now().weekday == 7) ? 0 : DateTime.now().weekday;
    // Defer tracking load until after first frame to ensure context initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTracking();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
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
    // Save scroll position
    final scrollPosition = _scrollController.hasClients ? _scrollController.offset : 0.0;
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Update state without full rebuild
    if (mounted) {
      setState(() {
        _todayMeals[key] = value;
      });
    }
    
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
    
    // Refresh weekly progress
    final weekly = await db.getDietTrackingForLast7Days(userId);
    if (mounted) {
      setState(() {
        _weeklyProgress = weekly;
      });
      // Restore scroll position after a brief delay
      if (_scrollController.hasClients && scrollPosition > 0) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(scrollPosition);
          }
        });
      }
    }
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
                tooltip:
                    Provider.of<LocalizationService>(context, listen: false)
                        .getString('back'),
              )
            : null,
        title: Consumer<LocalizationService>(
          builder: (context, localization, child) =>
              Text(localization.getString('ai_diet_assistant_title')),
        ),
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        actions: [
          // Copy current day's menu
          Builder(builder: (context) {
            return IconButton(
              tooltip: Provider.of<LocalizationService>(context, listen: false)
                  .getString('copy_day_menu'),
              icon: const Icon(Icons.copy_all_rounded),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final loc =
                    Provider.of<LocalizationService>(context, listen: false);
                final text = await _buildSelectedDayShareTextAsync(
                    loc, _selectedWeekday);
                await Clipboard.setData(ClipboardData(text: text));
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(loc.getString('day_menu_copied'))),
                );
              },
            );
          }),
          Builder(builder: (context) {
            return IconButton(
              tooltip: Provider.of<LocalizationService>(context, listen: false)
                  .getString('share_day_menu'),
              icon: const Icon(Icons.ios_share),
              onPressed: () async {
                final loc =
                    Provider.of<LocalizationService>(context, listen: false);
                final text = await _buildSelectedDayShareTextAsync(
                    loc, _selectedWeekday);
                Share.share(text);
              },
            );
          })
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          tabs: [
            Tab(
                text: Provider.of<LocalizationService>(context, listen: true)
                    .getString('diet_recommendations')),
            Tab(
                text: Provider.of<LocalizationService>(context, listen: true)
                    .getString('weekly_plan')),
          ],
        ),
      ),
      body: Consumer<LocalizationService>(
        builder: (context, localization, child) => FutureBuilder<_DietData>(
          future: _loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(
                  child: CircularProgressIndicator(color: cs.primary));
            }
            if (!snapshot.hasData) {
              return Center(
                  child: Text(localization.getString('no_data_available')));
            }
            final data = snapshot.data!;
            _latestDietData = data;

            final ageGroupLabel = localization.getString(data.ageGroupKey);
            final suitabilityText =
                localization.getStringWithParams('suitable_for_age', {
              'age_group': ageGroupLabel,
            });

            // Premium hero header + content
            final planSafety = _aiPlanSafetyReport ??
                _aiMenuService.evaluatePlanSafety(
                  hemogramValues: data.values,
                  focusTags:
                      _aiPlanDayTags.isNotEmpty ? _aiPlanDayTags.values : null,
                );

            Widget todayTab = ListView(
              controller: _scrollController,
              padding: ResponsiveHelper.getScreenPadding(context)
                  .copyWith(bottom: 8),
              children: [
                const MedicalDisclaimerBanner(),
                DietPlanSafetyAlert(report: planSafety),
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
                        Icon(Icons.psychology,
                            size: ResponsiveHelper.getIconSize(context, 26),
                            color: cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(localization.getString('ai_coach'),
                                style: TextStyle(
                                    fontSize: ResponsiveHelper.getFontSize(
                                        context, 18),
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface))),
                        Text(localization.getString('view_all'),
                            style: TextStyle(color: cs.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(localization.getString('ai_coach_sub'),
                        style: TextStyle(
                            fontSize: ResponsiveHelper.getFontSize(context, 14),
                            color: cs.onSurface.withValues(alpha: 0.85))),

                    // Latest results card
                    const SizedBox(height: 12),
                    if (data.hasMeasuredValues)
                      _buildLatestResultsCard(localization, data.values),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.check_box_outlined,
                            size: ResponsiveHelper.getIconSize(context, 20),
                            color: cs.primary),
                        const SizedBox(width: 8),
                        Text(localization.getString('diet_toggle_hint'),
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.85))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Modern meal tracking section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            cs.primaryContainer.withValues(alpha: 0.3),
                            cs.surfaceContainerHighest,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
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
                                  color: cs.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.restaurant_menu,
                                  color: cs.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      localization.getString('track_meals'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    Text(
                                      localization.getString('track_meals_subtitle'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Meal cards
                          _mealRow(context, 'meal_breakfast', 'breakfast'),
                          _mealRow(context, 'meal_lunch', 'lunch'),
                          _mealRow(context, 'meal_dinner', 'dinner'),
                          _mealRow(context, 'meal_snack', 'snack'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        avatar: Icon(Icons.cake, size: 18, color: cs.onPrimary),
                        label: Text(suitabilityText,
                            style: TextStyle(color: cs.onPrimary)),
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
                                style: TextStyle(
                                    fontSize: ResponsiveHelper.getFontSize(
                                        context, 14),
                                    color: cs.onSurface),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, '/hemogram_entry'),
                              child: Text(localization
                                  .getString('go_to_hemogram_entry')),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _buildFilterChips(localization, cs),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                const SizedBox(height: 8),
                ...(() {
                  // Build a day-curated list of programs for Today tab
                  final weekday = DateTime.now().weekday; // 1..7
                  final dayKey = _dayKeyFromWeekday(weekday);
                  List<DietProgram> curated = _programsForDay(data, dayKey);
                  // Apply filter if any
                  final filtered = curated
                      .where((p) => _selectedFilter == 'all'
                          ? true
                          : p.riskTag == _selectedFilter)
                      .toList();
                  // Optionally limit to top N for a concise Today view
                  final limited = filtered.take(8).toList();
                  final widgets = <Widget>[];
                  for (int i = 0; i < limited.length; i++) {
                    widgets.add(_DietCard(program: limited[i]));
                    if (i < limited.length - 1) {
                      widgets.add(const SizedBox(height: 12));
                    }
                  }
                  return widgets;
                })(),
              ],
            );

            Widget weekTab = ListView(
              controller: _scrollController,
              padding: ResponsiveHelper.getScreenPadding(context),
              children: [
                const MedicalDisclaimerBanner(),
                DietPlanSafetyAlert(report: planSafety),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary,
                        cs.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: cs.onPrimary, size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              localization.getString('ai_diet_assistant_title'),
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontSize:
                                    ResponsiveHelper.getFontSize(context, 20),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localization.getString('ai_diet_assistant_subtitle'),
                        style: TextStyle(
                          color: cs.onPrimary.withValues(alpha: 0.85),
                          fontSize: ResponsiveHelper.getFontSize(context, 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                _openAiAssistantDialog(localization),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text(localization
                                .getString('ai_diet_assistant_action')),
                            style: FilledButton.styleFrom(
                              backgroundColor: cs.onPrimary,
                              foregroundColor: cs.primary,
                            ),
                          ),
                          if (_aiWeeklyPlan.isNotEmpty)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.restart_alt),
                              label:
                                  Text(localization.getString('ai_plan_clear')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.onPrimary,
                                side: BorderSide(
                                    color: cs.onPrimary.withValues(alpha: 0.6)),
                              ),
                              onPressed: _clearAiPlan,
                            ),
                        ],
                      ),
                      if (_aiWeeklyPlan.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildAiPlanStatus(localization, cs),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Weekly tabs as ChoiceChips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (index) {
                      final dayKeys = [
                        'sunday',
                        'monday',
                        'tuesday',
                        'wednesday',
                        'thursday',
                        'friday',
                        'saturday'
                      ];
                      final selected = _selectedWeekday == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(localization.getString(dayKeys[index])),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedWeekday = index),
                          selectedColor: cs.primary,
                          labelStyle: TextStyle(
                              color: selected ? cs.onPrimary : cs.onSurface),
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // Daily menu for selected day (non-nested scroll)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: KeyedSubtree(
                    key: ValueKey(_selectedWeekday),
                    child:
                        _buildDailyMenu(localization, data, _selectedWeekday),
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

  Widget _buildLatestResultsCard(
      LocalizationService loc, Map<String, double> values) {
    final cs = Theme.of(context).colorScheme;
    // Order keys for display
    final ordered = [
      'glucose',
      'alt',
      'ast',
      'ggt',
      'total_bilirubin',
      'direct_bilirubin',
      'crp',
      'tsh',
      'free_t3',
      'free_t4',
      'vitamin_d3',
      'vitamin_b12',
      'sodium',
      'potassium',
      'chloride',
      'calcium',
      'hemoglobin',
      'iron',
      'white_blood_cells'
    ].where((k) => values.containsKey(k)).toList();

    // AI-like summary: count abnormalities
    int low = 0, high = 0;
    for (final k in ordered) {
      final v = values[k]!;
      final min = _ref[k]!['min']!;
      final max = _ref[k]!['max']!;
      if (v < min) {
        low++;
      } else if (v > max) {
        high++;
      }
    }
    String summaryKey;
    if (low == 0 && high == 0) {
      summaryKey = 'overall_assessment_normal';
    } else if (low + high <= 3) {
      summaryKey = 'overall_assessment_some_abnormal';
    } else {
      summaryKey = 'overall_assessment_many_abnormal';
    }

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
                decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.science, color: cs.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(loc.getString('latest_results_title'),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
              ),
              IconButton(
                tooltip: loc.getString('copy_values'),
                icon: const Icon(Icons.copy_all_rounded),
                onPressed: () async {
                  final buf = StringBuffer();
                  for (final k in ordered) {
                    buf.writeln(
                        '${loc.getString(k)}: ${values[k]!.toStringAsFixed(2)}');
                  }
                  await Clipboard.setData(ClipboardData(text: buf.toString()));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(loc.getString('values_copied'))));
                  }
                },
              ),
              TextButton.icon(
                onPressed: () {
                  final args = <String, dynamic>{
                    'values': Map<String, double>.from(values),
                  };
                  // Use the cached latest diet data for test date if available
                  final date = _latestDietData?.latestTestDate;
                  if (date != null) {
                    args['testDate'] = date;
                  }
                  Navigator.pushNamed(context, '/analysis', arguments: args);
                },
                icon: const Icon(Icons.open_in_new),
                label: Text(loc.getString('see_full_analysis')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ordered
                .map((k) => _buildValueChip(loc, k, values[k]!))
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.psychology, color: cs.secondary),
              const SizedBox(width: 6),
              Text(loc.getString('ai_interpretation_title'),
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: cs.onSurface)),
            ],
          ),
          const SizedBox(height: 4),
          Text(loc.getString(summaryKey),
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.8))),
          Text(loc.getString('ai_interpretation_hint'),
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildValueChip(LocalizationService loc, String key, double value) {
    final cs = Theme.of(context).colorScheme;
    final min = _ref[key]!['min']!;
    final max = _ref[key]!['max']!;
    late Color bg;
    late Color fg;
    late IconData icon;
    late String statusKey;
    if (value < min) {
      bg = Colors.orange.withValues(alpha: 0.12);
      fg = Colors.orange.shade700;
      icon = Icons.trending_down;
      statusKey = 'status_low';
    } else if (value > max) {
      bg = Colors.red.withValues(alpha: 0.12);
      fg = Colors.red.shade700;
      icon = Icons.trending_up;
      statusKey = 'status_high';
    } else {
      bg = Colors.green.withValues(alpha: 0.12);
      fg = Colors.green.shade700;
      icon = Icons.check_circle;
      statusKey = 'status_normal';
    }

    return GestureDetector(
      onTap: () => _showValueDetails(loc, key, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: fg.withValues(alpha: 0.3))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 16),
            const SizedBox(width: 6),
            Text('${loc.getString(key)}: ${value.toStringAsFixed(2)}',
                style: TextStyle(color: cs.onSurface)),
            const SizedBox(width: 6),
            Text(loc.getString(statusKey),
                style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          ],
        ),
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
                    decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: cs.primary, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.8))),
                          Text(value,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface)),
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

  Future<int?> _promptForInt(LocalizationService loc,
      {required String title,
      required int initial,
      required String unit}) async {
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
            keyboardType: const TextInputType.numberWithOptions(
                signed: false, decimal: false),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                  Text(loc.getString(key),
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Text('${loc.getString('value')}: ${value.toStringAsFixed(2)}'),
              Text(loc.getStringWithParams('normal_range_template', {
                'min': min.toStringAsFixed(1),
                'max': max.toStringAsFixed(1)
              })),
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
                    onPressed: () {
                      final args = <String, dynamic>{
                        'values': Map<String, double>.from(
                          _latestDietData?.values ?? const {},
                        ),
                      };
                      final date = _latestDietData?.latestTestDate;
                      if (date != null) {
                        args['testDate'] = date;
                      }
                      Navigator.pushNamed(context, '/analysis',
                          arguments: args);
                    },
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
    final cs = Theme.of(context).colorScheme;
    
    // Meal icons
    final mealIcons = {
      'breakfast': Icons.wb_sunny,
      'lunch': Icons.restaurant,
      'dinner': Icons.dinner_dining,
      'snack': Icons.coffee,
    };
    final icon = mealIcons[stateKey] ?? Icons.restaurant;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: checked 
            ? cs.primary.withValues(alpha: 0.1)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: checked 
              ? cs.primary
              : cs.outlineVariant,
          width: checked ? 2 : 1,
        ),
        boxShadow: checked ? [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: InkWell(
        onTap: () => _toggleMeal(stateKey, !checked),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Icon with animated background
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: checked 
                    ? cs.primary
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: checked 
                    ? cs.onPrimary
                    : cs.onSurface.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.getString(labelKey),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: checked 
                          ? cs.primary
                          : cs.onSurface,
                    ),
                  ),
                  if (checked) ...[
                    const SizedBox(height: 4),
                    Text(
                      loc.getString('completed'),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Checkmark or empty circle
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: checked
                  ? Container(
                      key: const ValueKey('checked'),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: cs.onPrimary,
                        size: 20,
                      ),
                    )
                  : Container(
                      key: const ValueKey('unchecked'),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.outlineVariant,
                          width: 2,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiPlanStatus(LocalizationService localization, ColorScheme cs) {
    final focusTag = _aiPlanFocusTag ?? 'general';
    final focusLabel = localization.getString(_labelKeyFor(focusTag));
    final variantLabel = localization.getString(
        _aiPlanDynamic ? 'ai_plan_auto_variant' : 'ai_plan_fixed_variant');
    String generatedText = '';
    if (_aiPlanGeneratedAt != null) {
      final date = localization.formatDate(_aiPlanGeneratedAt!);
      final time = localization.formatTime(_aiPlanGeneratedAt!);
      generatedText = localization
          .getStringWithParams('ai_plan_generated_at', {'time': '$date $time'});
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onPrimary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: cs.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localization.getString('ai_plan_active_label'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localization
                .getStringWithParams('ai_plan_focus', {'focus': focusLabel}),
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            variantLabel,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.85)),
          ),
          if (generatedText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              generatedText,
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String? _localizedAiMenu(
      LocalizationService localization, String dayName, String mealType) {
    final items = _aiWeeklyPlan[dayName]?[mealType];
    if (items == null || items.isEmpty) return null;
    final bulletLines = <String>[];
    for (final key in items) {
      final item = _localizeDietItem(localization, key);
      if (item.isEmpty) continue;
      bulletLines.add('• $item');
    }
    if (bulletLines.isEmpty) return null;
    return bulletLines.join('\n');
  }

  String _localizeDietItem(LocalizationService localization, String key) {
    try {
      return localization.getString(key);
    } catch (_) {
      final sanitized =
          key.replaceAll('diet_item_', '').replaceAll('_', ' ').trim();
      if (sanitized.isEmpty) return key;
      return sanitized
          .split(' ')
          .where((part) => part.isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join(' ');
    }
  }

  Widget _buildDailyMenu(
      LocalizationService localization, _DietData data, int dayIndex) {
    final cs = Theme.of(context).colorScheme;
    final dayNames = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday'
    ];
    final selectedDay = dayNames[dayIndex];

    final waterGoalMl = _currentWaterGoalMl();

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
    final overrideTag = _aiPlanDayTags[selectedDay];
    final displayTag = overrideTag ?? dayProgram?.riskTag;
    final focusTag = displayTag ?? 'general';
    final dayInsights = _aiMenuService.generateDayInsights(
      riskTag: focusTag,
      dayIndex: dayIndex,
      hemogramValues: data.values,
      waterGoalMl: waterGoalMl,
    );

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
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface),
              ),
              const Spacer(),
              if (displayTag != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: cs.primary.withValues(alpha: 0.25))),
                  child: Row(children: [
                    Icon(_iconFor(displayTag), color: cs.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(localization.getString(_labelKeyFor(displayTag)),
                        style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
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
          _getMealMenu(localization, data, 'breakfast', selectedDay),
          tag: displayTag,
        ),
        const SizedBox(height: 12),

        // Lunch
        _buildMealSection(
          localization,
          Icons.restaurant,
          'lunch',
          _getMealMenu(localization, data, 'lunch', selectedDay),
          tag: displayTag,
        ),
        const SizedBox(height: 12),

        // Snack
        _buildMealSection(
          localization,
          Icons.coffee,
          'snack',
          _getMealMenu(localization, data, 'snack', selectedDay),
          tag: displayTag,
        ),
        const SizedBox(height: 12),

        // Dinner
        _buildMealSection(
          localization,
          Icons.dinner_dining,
          'dinner',
          _getMealMenu(localization, data, 'dinner', selectedDay),
          tag: displayTag,
        ),
        _buildAiTips(localization, dayInsights),
      ],
    );
  }

  Widget _buildMealSection(LocalizationService localization, IconData icon,
      String mealKey, String menuText,
      {String? tag}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: tag != null ? _gradientFor(context, tag) : null,
        color: tag == null ? cs.surface : null,
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4)),
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
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface),
              ),
              const Spacer(),
              if (tag != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    localization.getString(_labelKeyFor(tag)),
                    style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
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

  Widget _buildAiTips(LocalizationService localization, DayInsights insights) {
    final messages = _composeAiTipMessages(localization, insights);
    if (messages.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.getString('ai_tip_section_title'),
            style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          ...messages.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(m.icon, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.text,
                        style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.85)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<_AiTipMessage> _composeAiTipMessages(
      LocalizationService localization, DayInsights insights) {
    final focusLabel = localization.getString(_labelKeyFor(insights.focusTag));
    final messages = <_AiTipMessage>[];

    if (insights.hasBoost) {
      final items = _joinItems(insights.boostItems
          .map<String>((key) => _localizeDietItem(localization, key))
          .toList());
      if (items.isNotEmpty) {
        messages.add(_AiTipMessage(
          icon: Icons.auto_awesome,
          text: localization.getStringWithParams('ai_tip_boost_template', {
            'focus': focusLabel,
            'items': items,
          }),
        ));
      }
    }

    if (insights.hasSwap) {
      final items = _joinItems(insights.swapItems
          .map<String>((key) => _localizeDietItem(localization, key))
          .toList());
      if (items.isNotEmpty) {
        messages.add(_AiTipMessage(
          icon: Icons.swap_horiz,
          text: localization
              .getStringWithParams('ai_tip_swap_template', {'items': items}),
        ));
      }
    }

    final hydrationText = localization.getStringWithParams(
      'ai_tip_hydration_template',
      {'water': '${insights.hydrationLiters.toStringAsFixed(1)}L'},
    );
    messages.add(_AiTipMessage(icon: Icons.water_drop, text: hydrationText));

    final mindfulSource = localization.getString(insights.mindfulKey);
    if (mindfulSource.isNotEmpty) {
      messages.add(_AiTipMessage(
        icon: Icons.lightbulb_outline,
        text: localization.getStringWithParams(
            'ai_tip_mindful_template', {'tip': mindfulSource}),
      ));
    }

    return messages;
  }

  String _joinItems(List<String> items) {
    final filtered = items.where((e) => e.isNotEmpty).toList();
    if (filtered.isEmpty) return '';
    return filtered.join(', ');
  }

  int? _currentWaterGoalMl() {
    final waterService = Provider.of<WaterService>(context, listen: false);
    final goal = waterService.goal;
    if (goal <= 0) return null;
    return goal * 250;
  }

  String _getMealMenu(LocalizationService localization, _DietData data,
      String mealType, String dayName) {
    final override = _localizedAiMenu(localization, dayName, mealType);
    if (override != null) return override;

    // If we have measured values, generate dynamic, tag-aware menus per day
    if (data.hasMeasuredValues) {
      final tag = _tagForDay(data.values, dayName);
      if (data.programs.isEmpty) {
        // Fallback gracefully when no programs are available
        return _baseMenuForDay(localization, mealType, dayName);
      }
      final program = data.programs.firstWhere(
        (p) => p.riskTag == tag,
        orElse: () => data.programs.first,
      );
      return _getMealMenuFromProgram(
          localization, program, mealType, dayName, data.values);
    }

    // Use localized per-day base menus when values are not measured
    return _baseMenuForDay(localization, mealType, dayName);
  }

  String _getMealMenuFromProgram(
    LocalizationService localization,
    DietProgram program,
    String mealType,
    String dayName,
    Map<String, double> values,
  ) {
    final override = _localizedAiMenu(localization, dayName, mealType);
    if (override != null) return override;

    // Use AI-powered menu service for rich, varied daily meals
    final dayIndex = _dayIndex(dayName);

    // Generate AI-powered menu for this specific day
    final dailyMenu = _aiMenuService.generateDailyMenu(
      riskTag: program.riskTag,
      dayIndex: dayIndex,
      hemogramValues: values,
    );

    // Get items for this meal type
    final mealItems = dailyMenu[mealType] ?? [];

    // Localize and format the menu items
    final localizedItems = mealItems
        .map((key) => _localizeDietItem(localization, key))
        .where((item) => item.isNotEmpty)
        .toList();

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
  String _baseMenuForDay(
      LocalizationService localization, String mealType, String dayName) {
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

  // Determine a priority tag for a given day based on abnormal values; rotate across tags for variety
  String _tagForDay(Map<String, double> values, String dayName) {
    final prioritized = _priorityTags(values);
    final pool = <String>[
      ...prioritized,
      ..._fallbackTags().where((t) => !prioritized.contains(t))
    ];
    final index = _dayIndex(dayName) % pool.length;
    return pool[index];
  }

  List<String> _fallbackTags() => const [
        'glucose',
        'liver',
        'bilirubin',
        'crp',
        'thyroid',
        'vitamin_d3',
        'vitamin_b12',
        'electrolytes',
        'calcium',
        'hemoglobin',
        'iron',
        'white_blood_cells'
      ];

  List<String> _availableFocusTags() {
    final values = _latestDietData?.values ?? {};
    final tags = <String>[];
    void addTag(String tag) {
      if (tag.isEmpty) return;
      if (!tags.contains(tag)) tags.add(tag);
    }

    for (final tag in _priorityTags(values)) {
      addTag(tag);
    }
    for (final tag in _fallbackTags()) {
      addTag(tag);
    }
    addTag('general');
    return tags;
  }

  _AiPlanPreview _buildAiPlanPreview(
      String focusTag, bool dynamicByDay, Map<String, double> values) {
    final menus = <String, Map<String, List<String>>>{};
    final tags = <String, String>{};
    for (var i = 0; i < _weekdayKeys.length; i++) {
      final dayKey = _weekdayKeys[i];
      String tag = focusTag.isEmpty ? 'general' : focusTag;
      if (dynamicByDay) {
        final computed = _tagForDay(values, dayKey);
        if (computed.isNotEmpty) {
          tag = computed;
        }
      }
      if (tag.isEmpty) tag = 'general';
      menus[dayKey] = _aiMenuService.generateDailyMenu(
        riskTag: tag,
        dayIndex: i,
        hemogramValues: values.isEmpty ? null : values,
      );
      tags[dayKey] = tag;
    }
    final safety = _aiMenuService.evaluatePlanSafety(
      focusTags: tags.values,
      hemogramValues: values.isEmpty ? null : values,
    );
    return _AiPlanPreview(menus: menus, tags: tags, safety: safety);
  }

  void _commitAiPlan(_AiPlanPreview plan, String focusTag, bool dynamicByDay) {
    if (!mounted) return;
    setState(() {
      _aiWeeklyPlan = plan.menus;
      _aiPlanDayTags = plan.tags;
      _aiPlanFocusTag = focusTag;
      _aiPlanDynamic = dynamicByDay;
      _aiPlanGeneratedAt = DateTime.now();
      _aiPlanSafetyReport = plan.safety;
    });
  }

  void _clearAiPlan() {
    if (_aiWeeklyPlan.isEmpty) return;
    final localization =
        Provider.of<LocalizationService>(context, listen: false);
    setState(() {
      _aiWeeklyPlan = {};
      _aiPlanDayTags = {};
      _aiPlanFocusTag = null;
      _aiPlanGeneratedAt = null;
      _aiPlanDynamic = true;
      _aiPlanSafetyReport = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localization.getString('ai_plan_cleared'))),
    );
  }

  List<Widget> _buildPlanPreviewWidgets(
    LocalizationService localization,
    _AiPlanPreview preview,
    ColorScheme cs,
    int? waterGoalMl,
  ) {
    final mealOrder = const ['breakfast', 'lunch', 'snack', 'dinner'];
    final mealIcons = {
      'breakfast': Icons.wb_sunny_outlined,
      'lunch': Icons.restaurant,
      'snack': Icons.coffee,
      'dinner': Icons.dinner_dining,
    };
    final widgets = <Widget>[];

    for (var i = 0; i < _weekdayKeys.length; i++) {
      final dayKey = _weekdayKeys[i];
      final meals = preview.menus[dayKey] ?? const <String, List<String>>{};
      final dayTag = preview.tags[dayKey] ?? 'general';
      final availableMeals = mealOrder
          .where((key) => (meals[key] ?? const []).isNotEmpty)
          .toList();
      final insights = _aiMenuService.generateDayInsights(
        riskTag: dayTag,
        dayIndex: i,
        hemogramValues: _latestDietData?.values,
        waterGoalMl: waterGoalMl,
      );
      final tipMessages = _composeAiTipMessages(localization, insights);

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    localization.getString(dayKey),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      localization.getString(_labelKeyFor(dayTag)),
                      style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (var idx = 0; idx < availableMeals.length; idx++) ...[
                Builder(builder: (context) {
                  final mealKey = availableMeals[idx];
                  final items = meals[mealKey] ?? const <String>[];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(mealIcons[mealKey], size: 18, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localization.getString('meal_$mealKey'),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface),
                            ),
                            const SizedBox(height: 4),
                            ...items.map((itemKey) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '• ${_localizeDietItem(localization, itemKey)}',
                                    style: TextStyle(
                                        color: cs.onSurface
                                            .withValues(alpha: 0.8)),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
                if (idx < availableMeals.length - 1) const SizedBox(height: 12),
              ],
              if (tipMessages.isNotEmpty) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tipMessages.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(m.icon, size: 16, color: cs.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              m.text,
                              style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.8),
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text(
          localization.getString('ai_plan_no_preview'),
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.85)),
        ),
      );
    }

    return widgets;
  }

  String _serializePlanForShare(LocalizationService localization,
      _AiPlanPreview preview, int? waterGoalMl) {
    final mealOrder = const ['breakfast', 'lunch', 'snack', 'dinner'];
    final buffer = StringBuffer()
      ..writeln(localization.getString('ai_diet_assistant_title'))
      ..writeln();

    for (final dayKey in _weekdayKeys) {
      buffer.writeln(localization.getString(dayKey));
      final meals = preview.menus[dayKey] ?? const <String, List<String>>{};
      for (final mealKey in mealOrder) {
        final items = meals[mealKey] ?? const <String>[];
        if (items.isEmpty) continue;
        buffer.writeln('  ${localization.getString('meal_$mealKey')}:');
        for (final item in items) {
          buffer.writeln('    - ${_localizeDietItem(localization, item)}');
        }
      }
      final insights = _aiMenuService.generateDayInsights(
        riskTag: preview.tags[dayKey] ?? 'general',
        dayIndex: _weekdayKeys.indexOf(dayKey),
        hemogramValues: _latestDietData?.values,
        waterGoalMl: waterGoalMl,
      );
      final tips = _composeAiTipMessages(localization, insights);
      if (tips.isNotEmpty) {
        buffer.writeln('  ${localization.getString('ai_tip_section_title')}:');
        for (final tip in tips) {
          buffer.writeln('    • ${tip.text}');
        }
      }
      buffer.writeln();
    }

    buffer
      ..writeln(localization.getString('medical_disclaimer_desc'))
      ..writeln(localization.getString('medical_disclaimer_body'))
      ..writeln(localization.getString('medical_consult_prompt'))
      ..writeln(localization.getString('medical_emergency_cta'));

    final safety = preview.safety;
    if (safety.shouldDisplay) {
      buffer
        ..writeln()
        ..writeln(localization.getString('medical_review_required_title'));
      for (final warningKey in safety.warningKeys) {
        buffer.writeln('• ${localization.getString(warningKey)}');
      }
      if (safety.guidelineKeys.isNotEmpty) {
        buffer.writeln();
        buffer.writeln(
            localization.getString('medical_guideline_reference_title'));
        for (final guidelineKey in safety.guidelineKeys) {
          buffer.writeln('• ${localization.getString(guidelineKey)}');
        }
      }
    }

    return buffer.toString().trim();
  }

  void _openAiAssistantDialog(LocalizationService localization) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;
    final values = Map<String, double>.from(_latestDietData?.values ?? {});
    final tags = _availableFocusTags();
    String selectedTag =
        _aiPlanFocusTag ?? (tags.isNotEmpty ? tags.first : 'general');
    if (!tags.contains(selectedTag) && tags.isNotEmpty) {
      selectedTag = tags.first;
    }
    bool canAdaptive =
        (_latestDietData?.hasMeasuredValues ?? false) && values.isNotEmpty;
    bool dynamicByDay = canAdaptive ? _aiPlanDynamic : false;
    var preview = _buildAiPlanPreview(selectedTag, dynamicByDay, values);
    final waterGoalMl = _currentWaterGoalMl();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final shareText =
                _serializePlanForShare(localization, preview, waterGoalMl);
            final availableTags = tags.isEmpty ? ['general'] : tags;
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.82,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          localization.getString('ai_plan_builder_title'),
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getFontSize(context, 18),
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      localization.getString('ai_plan_builder_desc'),
                      style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.85)),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      localization.getString('ai_plan_focus_title'),
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in availableTags)
                          ChoiceChip(
                            label:
                                Text(localization.getString(_labelKeyFor(tag))),
                            selected: selectedTag == tag,
                            onSelected: (selected) {
                              if (!selected) return;
                              setSheetState(() {
                                selectedTag = tag;
                                preview = _buildAiPlanPreview(
                                    selectedTag, dynamicByDay, values);
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: dynamicByDay && canAdaptive,
                      onChanged: canAdaptive
                          ? (value) {
                              setSheetState(() {
                                dynamicByDay = value;
                                preview = _buildAiPlanPreview(
                                    selectedTag, dynamicByDay, values);
                              });
                            }
                          : null,
                      title: Text(
                          localization.getString('ai_plan_adapt_each_day')),
                      subtitle: Text(
                        localization.getString(
                          canAdaptive
                              ? 'ai_plan_adapt_each_day_hint'
                              : 'ai_plan_adapt_each_day_disabled',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Scrollbar(
                        child: ListView(
                          children: [
                            const MedicalDisclaimerBanner(
                              margin: EdgeInsets.only(bottom: 12),
                            ),
                            DietPlanSafetyAlert(
                              report: preview.safety,
                              margin: const EdgeInsets.only(bottom: 12),
                            ),
                            ..._buildPlanPreviewWidgets(
                              localization,
                              preview,
                              cs,
                              waterGoalMl,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                                ClipboardData(text: shareText));
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                  content: Text(localization
                                      .getString('ai_plan_copied'))),
                            );
                          },
                          icon: const Icon(Icons.copy_all),
                          label: Text(localization.getString('ai_plan_copy')),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => Share.share(shareText),
                          icon: const Icon(Icons.ios_share),
                          label: Text(localization.getString('ai_plan_share')),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () {
                            final planToApply = preview;
                            Navigator.of(sheetContext).pop();
                            _commitAiPlan(planToApply, selectedTag,
                                dynamicByDay && canAdaptive);
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                    content: Text(localization
                                        .getString('ai_plan_applied'))),
                              );
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: Text(localization.getString('ai_plan_apply')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
        final severity = v < min
            ? (min - v) / (min == 0 ? 1 : min)
            : (v - max) / (max == 0 ? 1 : max);
        final tag = _riskTagForKey(k);
        entries.add({'tag': tag, 'severity': severity});
      }
    });
    // Group by tag and take max severity per tag
    final Map<String, double> byTag = {};
    for (final e in entries) {
      final t = e['tag'] as String;
      final s = e['severity'] as double;
      byTag[t] =
          (byTag[t] ?? 0).clamp(0.0, double.infinity) < s ? s : byTag[t]!;
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

  Future<String> _buildSelectedDayShareTextAsync(
      LocalizationService localization, int dayIndex) async {
    // Load latest data to ensure dynamic menus reflect current values
    final data = await _loadData();
    return _buildSelectedDayShareTextFromData(localization, data, dayIndex);
  }

  String _buildSelectedDayShareTextFromData(
      LocalizationService localization, _DietData data, int dayIndex) {
    final dayNames = [
      'sunday',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday'
    ];
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
    final hemoaiPrimary = const Color(0xFFE53E3E);

    // Calculate streak and completion stats
    int streak = 0;
    int totalMeals = 0;
    int completedMeals = 0;

    for (var day in _weeklyProgress!) {
      final breakfast = (day['breakfast'] ?? 0) == 1;
      final lunch = (day['lunch'] ?? 0) == 1;
      final dinner = (day['dinner'] ?? 0) == 1;
      final snack = (day['snack'] ?? 0) == 1;

      final dayTotal = (breakfast ? 1 : 0) +
          (lunch ? 1 : 0) +
          (dinner ? 1 : 0) +
          (snack ? 1 : 0);
      completedMeals += dayTotal;
      totalMeals += 4;

      if (dayTotal == 4) streak++;
    }

    final completionPercent =
        totalMeals > 0 ? (completedMeals / totalMeals * 100).round() : 0;
    
    // Modern streak emoji and message
    final streakEmoji = streak >= 7
        ? '🔥'
        : streak >= 4
            ? '⭐'
            : streak >= 1
                ? '✨'
                : '🌱';
    final streakMessage = streak >= 7
        ? loc.getString('diet_streak_fire')
        : streak >= 4
            ? loc.getString('diet_streak_great')
            : streak >= 1
                ? loc.getString('diet_streak_good')
                : loc.getString('diet_streak_start');

    // Calculate current day completion
    final today = DateTime.now();
    final todayKey = today.toIso8601String().split('T')[0];
    final todayData = _weeklyProgress!
        .firstWhere((d) => d['date'] == todayKey, orElse: () => {});
    final todayBreakfast = (todayData['breakfast'] ?? 0) == 1;
    final todayLunch = (todayData['lunch'] ?? 0) == 1;
    final todayDinner = (todayData['dinner'] ?? 0) == 1;
    final todaySnack = (todayData['snack'] ?? 0) == 1;
    final todayCompleted = (todayBreakfast ? 1 : 0) +
        (todayLunch ? 1 : 0) +
        (todayDinner ? 1 : 0) +
        (todaySnack ? 1 : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            hemoaiPrimary.withValues(alpha: 0.1),
            hemoaiPrimary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: hemoaiPrimary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hemoaiPrimary.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streak header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hemoaiPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: hemoaiPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          streakEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$streak ${loc.getString("days_streak")}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      streakMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Today's progress with modern design
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.getString('today_progress'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hemoaiPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$todayCompleted / 4',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: hemoaiPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: todayCompleted / 4,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(hemoaiPrimary),
              minHeight: 14,
            ),
          ),
          const SizedBox(height: 20),

          // Weekly stats in modern cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.getString('weekly_completion'),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$completionPercent%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: hemoaiPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.getString('total_meals'),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _DietCard extends StatelessWidget {
  final DietProgram program;
  const _DietCard({required this.program});

  @override
  Widget build(BuildContext context) {
    final localization =
        Provider.of<LocalizationService>(context, listen: false);
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
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4)),
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
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      localization.getString(tagKey),
                      style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 6),
              Text(
                localization.getString(program.descriptionKey),
                style: TextStyle(
                    fontSize: 14, color: cs.onSurface.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 12),
              if (program.macrosKey != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.pie_chart_outline,
                        color: Colors.deepPurple.shade400),
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
                        ..writeln(
                            localization.getString(program.descriptionKey))
                        ..writeln(localization.getString(program.includeKey))
                        ..writeln(localization.getString(program.limitKey));
                      if (program.macrosKey != null) {
                        text.writeln(
                            localization.getString(program.macrosKey!));
                      }
                      if (program.sampleMenuKey != null) {
                        text.writeln(
                            localization.getString(program.sampleMenuKey!));
                      }
                      await Clipboard.setData(
                          ClipboardData(text: text.toString()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  localization.getString('diet_copy_plan'))),
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
                        ..writeln(
                            localization.getString(program.descriptionKey))
                        ..writeln(localization.getString(program.includeKey))
                        ..writeln(localization.getString(program.limitKey));
                      if (program.macrosKey != null) {
                        text.writeln(
                            localization.getString(program.macrosKey!));
                      }
                      if (program.sampleMenuKey != null) {
                        text.writeln(
                            localization.getString(program.sampleMenuKey!));
                      }
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
      a = Colors.orange.withValues(alpha: 0.25);
      b = Colors.orange.withValues(alpha: 0.05);
      break;
    case 'liver':
      a = Colors.green.withValues(alpha: 0.25);
      b = Colors.green.withValues(alpha: 0.05);
      break;
    case 'bilirubin':
      a = Colors.amber.withValues(alpha: 0.25);
      b = Colors.amber.withValues(alpha: 0.05);
      break;
    case 'crp':
      a = Colors.deepPurple.withValues(alpha: 0.25);
      b = Colors.deepPurple.withValues(alpha: 0.05);
      break;
    case 'thyroid':
      a = Colors.purple.withValues(alpha: 0.25);
      b = Colors.purple.withValues(alpha: 0.05);
      break;
    case 'vitamin_d3':
      a = Colors.orangeAccent.withValues(alpha: 0.25);
      b = Colors.orangeAccent.withValues(alpha: 0.05);
      break;
    case 'vitamin_b12':
      a = Colors.blueGrey.withValues(alpha: 0.25);
      b = Colors.blueGrey.withValues(alpha: 0.05);
      break;
    case 'electrolytes':
      a = Colors.lightBlue.withValues(alpha: 0.25);
      b = Colors.lightBlue.withValues(alpha: 0.05);
      break;
    case 'calcium':
      a = Colors.teal.withValues(alpha: 0.25);
      b = Colors.teal.withValues(alpha: 0.05);
      break;
    case 'hemoglobin':
      a = Colors.red.withValues(alpha: 0.25);
      b = Colors.red.withValues(alpha: 0.05);
      break;
    case 'iron':
      a = Colors.brown.withValues(alpha: 0.25);
      b = Colors.brown.withValues(alpha: 0.05);
      break;
    case 'white_blood_cells':
      a = Colors.indigo.withValues(alpha: 0.25);
      b = Colors.indigo.withValues(alpha: 0.05);
      break;
  }
  return LinearGradient(
      colors: [a, b], begin: Alignment.topLeft, end: Alignment.bottomRight);
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

class _AiTipMessage {
  final IconData icon;
  final String text;

  const _AiTipMessage({
    required this.icon,
    required this.text,
  });
}

class _AiPlanPreview {
  final Map<String, Map<String, List<String>>> menus;
  final Map<String, String> tags;
  final DietPlanSafetyReport safety;

  const _AiPlanPreview({
    required this.menus,
    required this.tags,
    required this.safety,
  });
}

class _DietData {
  final int age;
  final String ageGroupKey;
  final List<DietProgram> programs;
  final bool hasMeasuredValues;
  final Map<String, double> values;
  final DateTime? latestTestDate;

  _DietData({
    required this.age,
    required this.ageGroupKey,
    required this.programs,
    required this.hasMeasuredValues,
    required this.values,
    this.latestTestDate,
  });
}
