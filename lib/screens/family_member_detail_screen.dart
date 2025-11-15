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
  final bool _consentGranted = true; // Assume granted; ideally read consent flag
  String _selectedMetric = 'HB';

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
          tabs: [
            Tab(icon: const Icon(Icons.health_and_safety), text: loc.getString('tab_overview')),
            Tab(icon: const Icon(Icons.assignment), text: loc.getString('tab_tests')),
            Tab(icon: const Icon(Icons.medication), text: loc.getString('tab_medications')),
            Tab(icon: const Icon(Icons.event_note), text: loc.getString('tab_reminders')),
            Tab(icon: const Icon(Icons.restaurant_menu), text: loc.getString('diet')),
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
          loc.getString('family_consent_required'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildOverview(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
  _infoTile(Provider.of<LocalizationService>(context, listen: false).getString('relation_label'), widget.member['relation']?.toString() ?? '—'),
  _infoTile(Provider.of<LocalizationService>(context, listen: false).getString('age_label'), (widget.member['age'] ?? '—').toString()),
  _infoTile(Provider.of<LocalizationService>(context, listen: false).getString('phone_label'), widget.member['phone']?.toString() ?? '—'),
        const SizedBox(height: 12),
        // Smart Alerts (Premium)
        if (_tests.isNotEmpty) _buildSmartAlerts(theme),
        const SizedBox(height: 12),
  Text(Provider.of<LocalizationService>(context, listen: false).getString('latest_test'), style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_tests.isEmpty)
          Text(Provider.of<LocalizationService>(context, listen: false).getString('no_tests_yet'))
        else
          _testCard(_tests.first),
        const SizedBox(height: 16),
        if (_tests.isNotEmpty) ...[
          Row(
            children: [
              Text(Provider.of<LocalizationService>(context, listen: false).getString('trend_label') + ' '),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(Provider.of<LocalizationService>(context, listen: false).getString('metric_hb')),
                selected: _selectedMetric == 'HB',
                onSelected: (_) => setState(() => _selectedMetric = 'HB'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text(Provider.of<LocalizationService>(context, listen: false).getString('metric_crp')),
                selected: _selectedMetric == 'CRP',
                onSelected: (_) => setState(() => _selectedMetric = 'CRP'),
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                label: Text(Provider.of<LocalizationService>(context, listen: false).getString('metric_glucose')),
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
          title: Text(Provider.of<LocalizationService>(context, listen: false).getString('smart_alerts_premium_title')),
          subtitle: Text(Provider.of<LocalizationService>(context, listen: false).getString('smart_alerts_premium_subtitle')),
          trailing: TextButton(onPressed: () => Navigator.pushNamed(context, '/premium'), child: Text(Provider.of<LocalizationService>(context, listen: false).getString('upgrade'))),
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
                Text(Provider.of<LocalizationService>(context, listen: false).getString('smart_alerts_premium_title'), style: theme.textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () async {
                    final bundle = FhirService.buildObservationBundle(user: widget.member, test: latest);
                    final jsonStr = const JsonEncoder.withIndent('  ').convert(bundle);
                    await Clipboard.setData(ClipboardData(text: jsonStr));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Provider.of<LocalizationService>(context, listen: false).getString('fhir_json_copied'))));
                    }
                  },
                  icon: const Icon(Icons.share),
                  label: Text(Provider.of<LocalizationService>(context, listen: false).getString('export_fhir_json')),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (result.alerts.isEmpty)
              Text(Provider.of<LocalizationService>(context, listen: false).getString('all_markers_normal'))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.alerts.map((a) {
                  final dist = a.distanceToTarget;
                  return Chip(
                    backgroundColor: a.color.withValues(alpha: 0.12),
                    label: Text('${a.message}${dist != null ? ' (Δ$dist)' : ''}'),
                    avatar: Icon(Icons.warning, color: a.color),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            if (result.nextTestDate != null)
              Text('${Provider.of<LocalizationService>(context, listen: false).getString('next_test_suggested_prefix')} ${result.nextTestDate!.toLocal().toString().substring(0, 10)}',
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
    if (_tests.isEmpty) return Center(child: Text(Provider.of<LocalizationService>(context, listen: false).getString('no_tests')));
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
    if (_medications.isEmpty) return Center(child: Text(Provider.of<LocalizationService>(context, listen: false).getString('no_medications')));
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
    if (_reminders.isEmpty) return Center(child: Text(Provider.of<LocalizationService>(context, listen: false).getString('no_reminders')));
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
        _DietPlan(loc.getString('plan_balanced_teen'), loc.getString('subtitle_balanced_teen')),
        _DietPlan(loc.getString('plan_iron_friendly_snacks'), loc.getString('subtitle_iron_friendly_snacks')),
      ]);
    } else if (age < 40) {
      plans.addAll([
        _DietPlan(loc.getString('plan_mediterranean_core'), loc.getString('subtitle_mediterranean_core')),
        _DietPlan(loc.getString('plan_lean_protein_focus'), loc.getString('subtitle_lean_protein_focus')),
      ]);
    } else if (age < 65) {
      plans.addAll([
        _DietPlan(loc.getString('plan_cardio_friendly'), loc.getString('subtitle_cardio_friendly')),
        _DietPlan(loc.getString('plan_low_sodium_plan'), loc.getString('subtitle_low_sodium_plan')),
      ]);
    } else {
      plans.addAll([
        _DietPlan(loc.getString('plan_senior_soft_menu'), loc.getString('subtitle_senior_soft_menu')),
        _DietPlan(loc.getString('plan_bone_health'), loc.getString('subtitle_bone_health')),
      ]);
    }

    // Lab-personalization (Premium)
    if (possibleIronDef) {
      plans.insert(0, _DietPlan(loc.getString('premium_plan_iron_boost'), loc.getString('subtitle_premium_plan_iron_boost')));
    }
    if (inflammation) {
      plans.insert(0, _DietPlan(loc.getString('premium_plan_anti_inflammatory'), loc.getString('subtitle_premium_plan_anti_inflammatory')));
    }
    if (highGlucose) {
      plans.insert(0, _DietPlan(loc.getString('premium_plan_low_gi'), loc.getString('subtitle_premium_plan_low_gi')));
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
        _weeklyTable(weekly),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _exportWeeklyPdf(weekly),
          icon: const Icon(Icons.picture_as_pdf),
          label: Text(loc.getString('export_pdf')),
        ),
        const SizedBox(height: 12),
        Text(loc.getString('diet_disclaimer')),
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

  Widget _weeklyTable(Map<String, List<String>> weekly) {
    final headerStyle = const TextStyle(fontWeight: FontWeight.w600);
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {0: FixedColumnWidth(64)},
      children: [
        TableRow(children: [
          Padding(padding: const EdgeInsets.all(8), child: Text(Provider.of<LocalizationService>(context, listen: false).getString('table_header_day'), style: const TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: const EdgeInsets.all(8), child: Text(Provider.of<LocalizationService>(context, listen: false).getString('table_header_breakfast'), style: const TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: const EdgeInsets.all(8), child: Text(Provider.of<LocalizationService>(context, listen: false).getString('table_header_lunch'), style: const TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: const EdgeInsets.all(8), child: Text(Provider.of<LocalizationService>(context, listen: false).getString('table_header_dinner'), style: const TextStyle(fontWeight: FontWeight.bold))),
        ]),
        ...weekly.entries.map((e) => TableRow(children: [
              Padding(padding: const EdgeInsets.all(8), child: Text(_localizedDay(e.key), style: headerStyle)),
              Padding(padding: const EdgeInsets.all(8), child: Text(e.value[0])),
              Padding(padding: const EdgeInsets.all(8), child: Text(e.value[1])),
              Padding(padding: const EdgeInsets.all(8), child: Text(e.value[2])),
            ])),
      ],
    );
  }

  String _localizedDay(String engShort) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    switch (engShort) {
      case 'Mon':
        return loc.getString('day_mon');
      case 'Tue':
        return loc.getString('day_tue');
      case 'Wed':
        return loc.getString('day_wed');
      case 'Thu':
        return loc.getString('day_thu');
      case 'Fri':
        return loc.getString('day_fri');
      case 'Sat':
        return loc.getString('day_sat');
      case 'Sun':
        return loc.getString('day_sun');
    }
    return engShort;
  }

  Future<void> _exportWeeklyPdf(Map<String, List<String>> weekly) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(Provider.of<LocalizationService>(context, listen: false).getString('weekly_diet_plan_pdf'), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: const {0: pw.FixedColumnWidth(60)},
              children: [
                pw.TableRow(children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(Provider.of<LocalizationService>(context, listen: false).getString('table_header_day'))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(Provider.of<LocalizationService>(context, listen: false).getString('table_header_breakfast'))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(Provider.of<LocalizationService>(context, listen: false).getString('table_header_lunch'))),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(Provider.of<LocalizationService>(context, listen: false).getString('table_header_dinner'))),
                ]),
                ...weekly.entries.map((e) => pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_localizedDay(e.key))),
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


