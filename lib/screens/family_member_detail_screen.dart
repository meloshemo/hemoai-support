import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import '../services/localization_service.dart';
import '../services/database_helper.dart';
import '../services/preferences_service.dart';
import '../services/premium_alerts_service.dart';
import '../services/fhir_service.dart';
import '../services/premium_service.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class FamilyMemberDetailScreen extends StatefulWidget {
  final Map<String, dynamic> member;
  const FamilyMemberDetailScreen({super.key, required this.member});

  @override
  State<FamilyMemberDetailScreen> createState() => _FamilyMemberDetailScreenState();
}

class _FamilyMemberDetailScreenState extends State<FamilyMemberDetailScreen> with TickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;
  List<Map<String, dynamic>> _tests = [];
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _reminders = [];
  int? _userId;
  bool _consentGranted = true; // Assume granted; ideally read consent flag
  String _selectedMetric = 'HB';

  // Quick access to localization service across methods
  LocalizationService get loc => Provider.of<LocalizationService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _init();
  }

  Future<void> _init() async {
    try {
      _userId = widget.member['id'] as int?;
      if (_userId != null) {
        final db = DatabaseHelper.instance;
        try {
          _tests = await db.getHemogramTests(_userId!);
        } catch (_) {}
        // Medications and reminders by user
        try {
          _medications = await db.getMedications(_userId!);
        } catch (_) {
          try {
            final prefs = await PreferencesService.getInstance();
            _medications = prefs.getMedications();
          } catch (_) {}
        }
        try {
          _reminders = await db.getActiveReminders(_userId!);
        } catch (_) {}
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.getString('family_member') == 'family_member' ? 'Family Member' : loc.getString('family_member'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member['name'] ?? loc.getString('family_member')),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.health_and_safety), text: 'Overview'),
            Tab(icon: Icon(Icons.assignment), text: 'Tests'),
            Tab(icon: Icon(Icons.medication), text: 'Medications'),
            Tab(icon: Icon(Icons.event_note), text: 'Reminders'),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Diet'),
          ],
        ),
      ),
      body: _consentGranted
          ? TabBarView(
              controller: _tabs,
              children: [
                _buildOverview(theme),
                _buildTests(theme),
                _buildMedications(theme),
                _buildReminders(theme),
                _buildDiet(theme, loc),
              ],
            )
          : _buildConsentRequired(loc),
    );
  }

  Widget _buildConsentRequired(LocalizationService loc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          loc.getString('family_consent_required') == 'family_consent_required'
              ? 'This member has not granted permission to view data.'
              : loc.getString('family_consent_required'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildOverview(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoTile('Relation', widget.member['relation'] ?? '—'),
        _infoTile('Age', (widget.member['age'] ?? '—').toString()),
        _infoTile('Phone', widget.member['phone'] ?? '—'),
        const SizedBox(height: 12),
        // Smart Alerts (Premium)
        if (_tests.isNotEmpty) _buildSmartAlerts(theme),
        const SizedBox(height: 12),
        Text(loc.getString('latest_test'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_tests.isEmpty)
          Text(loc.getString('no_tests_yet'))
        else
          _testCard(_tests.first),
        const SizedBox(height: 16),
        if (_tests.length >= 1) ...[
          Row(
            children: [
              Text(loc.getString('trend_label')),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(loc.getString('hemoglobin')),
                selected: _selectedMetric == 'HB',
                onSelected: (_) => setState(() => _selectedMetric = 'HB'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text(loc.getString('crp')),
                selected: _selectedMetric == 'CRP',
                onSelected: (_) => setState(() => _selectedMetric = 'CRP'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text(loc.getString('glucose')),
                selected: _selectedMetric == 'Glucose',
                onSelected: (_) => setState(() => _selectedMetric = 'Glucose'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: const Border(bottom: BorderSide(), left: BorderSide())),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    spots: _buildSpots(),
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmartAlerts(ThemeData theme) {
    final latest = _tests.first;
    final isPremium = Provider.of<PremiumService>(context, listen: false).isPremium;
    if (!isPremium) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.lock),
          title: Text(loc.getString('smart_alerts_premium')),
          subtitle: Text(loc.getString('unlock_personalized_alerts')),
          trailing: TextButton(onPressed: () => Navigator.pushNamed(context, '/premium'), child: Text(loc.getString('upgrade'))),
        ),
      );
    }
    final result = PremiumAlertsService.analyzeLatest(latest);
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Smart Alerts (Premium)', style: theme.textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () async {
                    final bundle = FhirService.buildObservationBundle(user: widget.member, test: latest);
                    final jsonStr = const JsonEncoder.withIndent('  ').convert(bundle);
                    await Clipboard.setData(ClipboardData(text: jsonStr));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.getString('fhir_json_copied'))));
                    }
                  },
                  icon: const Icon(Icons.share),
                  label: Text(loc.getString('export_fhir_json')),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (result.alerts.isEmpty)
              Text(loc.getString('all_key_markers_normal'))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.alerts.map((a) {
                  final dist = a.distanceToTarget;
                  return Chip(
                    backgroundColor: a.color.withOpacity(.12),
                    label: Text('${a.message}${dist != null ? ' (Δ$dist)' : ''}'),
                    avatar: Icon(Icons.warning, color: a.color),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            if (result.nextTestDate != null)
              Text('Next test suggested: ${result.nextTestDate!.toLocal().toString().substring(0, 10)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.primary)),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    final List<FlSpot> spots = [];
    for (int i = 0; i < _tests.length; i++) {
      final t = _tests[_tests.length - 1 - i];
      double? v;
      switch (_selectedMetric) {
        case 'HB':
          v = _num(t['hemoglobin']);
          break;
        case 'CRP':
          v = _num(t['crp']);
          break;
        case 'Glucose':
          v = _num(t['glucose']);
          break;
      }
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }
    if (spots.isEmpty) spots.add(const FlSpot(0, 0));
    return spots;
  }

  Widget _buildTests(ThemeData theme) {
    if (_tests.isEmpty) return const Center(child: Text('No tests'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tests.length,
      itemBuilder: (_, i) => _testCard(_tests[i]),
    );
  }

  Widget _testCard(Map<String, dynamic> t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((t['test_date'] ?? t['created_at'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _kv('HB', t['hemoglobin']),
                _kv('WBC', t['leukocyte']),
                _kv('RBC', t['erythrocyte']),
                _kv('PLT', t['platelet']),
                _kv('Glucose', t['glucose']),
                _kv('CRP', t['crp']),
                _kv('ALT', t['alt']),
                _kv('AST', t['ast']),
              ].whereType<Widget>().toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _kv(String k, Object? v) {
    if (v == null) return null;
    return Chip(label: Text('$k: $v'));
  }

  Widget _buildMedications(ThemeData theme) {
    if (_medications.isEmpty) return Center(child: Text(loc.getString('no_medications')));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _medications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final m = _medications[i];
        return ListTile(
          leading: const Icon(Icons.medication),
          title: Text(m['name'] ?? ''),
          subtitle: Text('${m['dosage']} • ${m['frequency']} • ${m['time'] ?? m['time_to_take'] ?? ''}'),
        );
      },
    );
  }

  Widget _buildReminders(ThemeData theme) {
    if (_reminders.isEmpty) return const Center(child: Text('No reminders'));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _reminders.map((r) => ListTile(leading: const Icon(Icons.alarm), title: Text(r['title'] ?? ''), subtitle: Text(r['time'] ?? ''))).toList(),
    );
  }

  Widget _buildDiet(ThemeData theme, LocalizationService loc) {
    final age = (widget.member['age'] ?? 0) as int;
    final latest = _tests.isNotEmpty ? _tests.first : <String, dynamic>{};
    final double? hb = _num(latest['hemoglobin']);
    final double? mch = _num(latest['mch']);
    final double? mchc = _num(latest['mchc']);
    final double? crp = _num(latest['crp']);
    final double? glucose = _num(latest['glucose']);

    // Heuristic deficiency detections
    final bool possibleIronDef = (hb != null && hb < 12) || (mch != null && mch < 27) || (mchc != null && mchc < 32);
    final bool inflammation = crp != null && crp > 5;
    final bool highGlucose = glucose != null && glucose >= 126;

    List<_DietPlan> plans = [];

    // Age baseline
    if (age < 18) {
      plans.addAll([
        _DietPlan('Balanced teen plan', 'Adequate protein, fruits/veggies, hydration'),
        _DietPlan('Iron-friendly snacks', 'Nuts, seeds, dried fruits, yogurt'),
      ]);
    } else if (age < 40) {
      plans.addAll([
        _DietPlan('Mediterranean core', 'Olive oil, fish 2x/week, legumes, whole grains'),
        _DietPlan('Lean protein focus', 'Chicken, turkey, eggs, legumes'),
      ]);
    } else if (age < 65) {
      plans.addAll([
        _DietPlan('Cardio-friendly', 'Low saturated fat, high fiber, more omega-3'),
        _DietPlan('Low-sodium plan', 'Limit processed foods, use herbs/spices'),
      ]);
    } else {
      plans.addAll([
        _DietPlan('Senior soft menu', 'Easier-to-chew meals, soups, stews'),
        _DietPlan('Bone health', 'Calcium+D3, dairy/fortified alternatives'),
      ]);
    }

    // Lab-personalization (Premium)
    if (possibleIronDef) {
      plans.insert(0, _DietPlan('Iron-Boost Plan (Premium)', 'Red meat 2-3x/week, legumes, spinach, vitamin C with meals; limit tea/coffee with iron meals'));
    }
    if (inflammation) {
      plans.insert(0, _DietPlan('Anti-inflammatory Plan (Premium)', 'Omega-3 (salmon, walnuts), turmeric/ginger, berries; reduce ultra-processed, trans fat, added sugars'));
    }
    if (highGlucose) {
      plans.insert(0, _DietPlan('Low-GI Plan (Premium)', 'Whole grains, legumes, non-starchy veggies; avoid sugary drinks; balanced carb portions'));
    }

    final weekly = _buildWeeklyMenu(plans);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.amber),
            const SizedBox(width: 8),
            Text(loc.getString('professional_diet_suggestions')),
          ],
        ),
        const SizedBox(height: 8),
        ...plans.map((p) => Card(
              child: ListTile(
                leading: const Icon(Icons.restaurant_menu),
                title: Text(p.title),
                subtitle: Text(p.subtitle),
              ),
            )),
        const SizedBox(height: 16),
        Text(loc.getString('weekly_plan'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _weeklyTable(weekly, loc),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _exportWeeklyPdf(weekly, loc),
          icon: const Icon(Icons.picture_as_pdf),
          label: Text(loc.getString('export_pdf')),
        ),
        const SizedBox(height: 12),
        Text(loc.getString('educational_suggestions_disclaimer')),
      ],
    );
  }

  Map<String, List<String>> _buildWeeklyMenu(List<_DietPlan> plans) {
    final base = plans.take(3).map((e) => e.title).toList();
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return {
      for (final d in days)
        d: [
          base[(days.indexOf(d)+0)%base.length],
          base[(days.indexOf(d)+1)%base.length],
          base[(days.indexOf(d)+2)%base.length],
        ]
    };
  }

  Widget _weeklyTable(Map<String, List<String>> weekly, LocalizationService loc) {
    final headerStyle = const TextStyle(fontWeight: FontWeight.w600);
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {0: FixedColumnWidth(64)},
      children: [
        TableRow(children: [
          Padding(padding: const EdgeInsets.all(8), child: Text(loc.getString('day'), style: const TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: const EdgeInsets.all(8), child: Text(loc.getString('breakfast'), style: const TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: const EdgeInsets.all(8), child: Text(loc.getString('lunch'), style: const TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: const EdgeInsets.all(8), child: Text(loc.getString('dinner'), style: const TextStyle(fontWeight: FontWeight.bold))),
        ]),
        ...weekly.entries.map((e) => TableRow(children: [
              Padding(padding: const EdgeInsets.all(8), child: Text(e.key, style: headerStyle)),
              Padding(padding: const EdgeInsets.all(8), child: Text(e.value[0])),
              Padding(padding: const EdgeInsets.all(8), child: Text(e.value[1])),
              Padding(padding: const EdgeInsets.all(8), child: Text(e.value[2])),
            ])),
      ],
    );
  }

  Future<void> _exportWeeklyPdf(Map<String, List<String>> weekly, LocalizationService loc) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(loc.getString('weekly_diet_plan'), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: const {0: pw.FixedColumnWidth(60)},
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(loc.getString('day'))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(loc.getString('breakfast'))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(loc.getString('lunch'))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(loc.getString('dinner'))),
                ]),
                ...weekly.entries.map((e) => pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.key)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.value[0])),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.value[1])),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.value[2])),
                    ])),
              ],
            ),
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  double? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Widget _infoTile(String k, String v) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(v),
    );
  }
}

class _DietPlan {
  final String title;
  final String subtitle;
  const _DietPlan(this.title, this.subtitle);
}

