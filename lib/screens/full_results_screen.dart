import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../widgets/app_drawer.dart';
import '../utils/responsive_helper.dart';

class FullResultsScreen extends StatefulWidget {
  const FullResultsScreen({super.key});

  @override
  State<FullResultsScreen> createState() => _FullResultsScreenState();
}

class _FullResultsScreenState extends State<FullResultsScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  Map<String, dynamic>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Prefer route argument if provided
      await Future.delayed(Duration.zero);
      if (!mounted) return;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['result'] is Map<String, dynamic>) {
        setState(() {
          _result = Map<String, dynamic>.from(args['result'] as Map<String, dynamic>);
          _loading = false;
        });
        return;
      }
      // Fallback: fetch latest test for current user
      final prefs = await PreferencesService.getInstance();
      final userId = prefs.getCurrentUserId();
      if (!mounted) return;
      if (userId != null) {
        final latest = await _db.getLatestHemogramTest(userId);
        if (!mounted) return;
        setState(() {
          _result = latest;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    return Scaffold(
      drawer: const AppDrawer(currentRoute: '/full_results'),
      appBar: AppBar(
        title: Text(loc.getString('full_results_title')),
      ),
      body: _loading
          ? Center(child: Text(loc.getString('loading')))
          : (_result == null)
              ? Center(child: Text(loc.getString('no_results_available')))
              : SingleChildScrollView(
                  padding: ResponsiveHelper.getScreenPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildSections(loc, Theme.of(context).colorScheme),
                  ),
                ),
    );
  }

  List<Widget> _buildSections(LocalizationService loc, ColorScheme scheme) {
    final sections = <_SectionDef>[
      _SectionDef('cbc', [
        'hemoglobin', 'hematocrit', 'red_blood_cells', 'white_blood_cells', 'platelets',
        'mcv', 'mch', 'mchc', 'rdw', 'mpv'
      ]),
      _SectionDef('wbc_diff', [
        'neutrophils', 'lymphocytes', 'monocytes', 'eosinophils', 'basophils'
      ], titleKeyOverride: 'wbc_differential'),
      _SectionDef('iron_studies', [
        'iron', 'ferritin', 'transferrin', 'tibc', 'transferrin_saturation'
      ]),
      _SectionDef('liver_function', [
        'alt', 'ast', 'alp', 'ggt', 'bilirubin', 'direct_bilirubin', 'albumin', 'total_protein'
      ]),
      _SectionDef('kidney_function', [
        'creatinine', 'urea', 'uric_acid', 'gfr'
      ]),
      _SectionDef('lipid_profile', [
        'total_cholesterol', 'ldl_cholesterol', 'hdl_cholesterol', 'triglycerides', 'non_hdl_cholesterol'
      ]),
      _SectionDef('diabetes_markers', [
        'glucose', 'hba1c', 'fructosamine'
      ]),
      _SectionDef('thyroid_function', [
        'tsh', 't3', 't4', 'free_t3', 'free_t4'
      ]),
      _SectionDef('electrolytes', [
        'sodium', 'potassium', 'chloride', 'calcium', 'magnesium', 'phosphorus'
      ]),
      _SectionDef('vitamins', [
        'vitamin_b12', 'vitamin_d', 'folate', 'vitamin_a', 'vitamin_e', 'vitamin_c'
      ]),
      _SectionDef('tumor_markers', [
        'cea', 'afp', 'ca125', 'ca199', 'ca153', 'psa'
      ]),
      _SectionDef('cardiac_markers', [
        'troponin', 'ck_mb', 'ldh', 'bnp'
      ]),
      _SectionDef('inflammatory_markers', [
        'crp', 'esr', 'procalcitonin'
      ]),
      _SectionDef('hormones', [
        'insulin', 'cortisol', 'testosterone', 'estradiol', 'progesterone', 'prolactin', 'fsh', 'lh'
      ]),
    ];

    final widgets = <Widget>[];

    // Metadata
    final meta = <String, String?>{
      'test_date': _result!['test_date']?.toString(),
      'laboratory_name': _result!['laboratory_name']?.toString(),
      'doctor_name': _result!['doctor_name']?.toString(),
      'test_type': _result!['test_type']?.toString(),
    };
    widgets.add(_metaCard(loc, scheme, meta));
    widgets.add(const SizedBox(height: 16));

    for (final sec in sections) {
      final nonNullItems = sec.keys
          .map((k) => MapEntry(k, _result![k]))
          .where((e) => e.value != null)
          .toList();
      if (nonNullItems.isEmpty) continue;
      widgets.add(_sectionCard(
        title: loc.getString(sec.titleKeyOverride ?? sec.titleKey),
        scheme: scheme,
        children: nonNullItems
            .map((e) => _row(
                  loc, _labelFor(loc, e.key), _formatValue(e.value),
                ))
            .toList(),
      ));
      widgets.add(const SizedBox(height: 16));
    }
    if (widgets.length <= 2) {
      widgets.add(Center(child: Text(loc.getString('no_results_available'))));
    }
    return widgets;
  }

  Widget _metaCard(LocalizationService loc, ColorScheme scheme, Map<String, String?> meta) {
    final items = <Widget>[];
    void addItem(String key) {
      final v = meta[key];
      if (v == null || v.isEmpty) return;
      items.add(_row(loc, loc.getString(key), v));
    }
    addItem('test_date');
    addItem('laboratory_name');
    addItem('doctor_name');
    addItem('test_type');
    if (items.isEmpty) return const SizedBox.shrink();
    return _sectionCard(title: loc.getString('results'), scheme: scheme, children: items);
  }

  Widget _sectionCard({required String title, required ColorScheme scheme, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF21262D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.analytics, color: scheme.primary),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        ...children,
      ]),
    );
  }

  Widget _row(LocalizationService loc, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  String _labelFor(LocalizationService loc, String key) {
    // Try localization first; fallback to prettified key
    final localized = loc.getString(key);
    if (localized != key) return localized;
    return key.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? w : (w[0].toUpperCase() + w.substring(1))).join(' ');
  }

  String _formatValue(dynamic v) {
    if (v is num) return v.toStringAsFixed(2);
    return v?.toString() ?? '-';
  }
}

class _SectionDef {
  final String titleKey;
  final List<String> keys;
  final String? titleKeyOverride;
  _SectionDef(this.titleKey, this.keys, {this.titleKeyOverride});
}
