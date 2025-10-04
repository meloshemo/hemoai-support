// Restored rich Family Panel with tabs, sample data, and localized labels
// Simplified and adapted from the previous full-featured implementation
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/active_profile_service.dart';
import '../services/database_helper.dart';

class FamilyPanelScreen extends StatefulWidget {
  const FamilyPanelScreen({super.key});

  @override
  State<FamilyPanelScreen> createState() => _FamilyPanelScreenState();
}

class _FamilyPanelScreenState extends State<FamilyPanelScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> familyMembers = [];
  final Map<String, List<double>> referenceRanges = const {
    'hemoglobin': [12.0, 17.0],
    'iron': [60.0, 170.0],
    'white_blood_cells': [4.0, 10.0],
    'platelets': [150.0, 400.0],
    'hematocrit': [38.0, 50.0],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSampleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSampleData() {
    familyMembers.addAll([
      {
        'id': '1',
        'name': 'Ahmet Yilmaz',
        'relation': 'father',
        'age': 45,
        'gender': 'male',
        'avatar': '👨',
        'lastTest': '2024-09-15',
        'riskLevel': 'medium',
        'hemogram': {
          'hemoglobin': 13.2,
          'iron': 85.0,
          'white_blood_cells': 9.2,
          'platelets': 280.0,
          'hematocrit': 42.0,
        },
        'trends': {
          'hemoglobin': [12.8, 13.0, 13.2],
          'iron': [75.0, 80.0, 85.0],
        },
        'testHistory': [
          {
            'date': '2024-09-15',
            'hemogram': {
              'hemoglobin': 13.2,
              'iron': 85.0,
              'white_blood_cells': 9.2,
              'platelets': 280.0,
              'hematocrit': 42.0,
            },
            'riskLevel': 'medium',
            'doctorNotesKey': 'doctor_notes_generated_by_hemoai',
          },
          {
            'date': '2024-06-15',
            'hemogram': {
              'hemoglobin': 13.0,
              'iron': 80.0,
              'white_blood_cells': 8.8,
              'platelets': 270.0,
              'hematocrit': 41.0,
            },
            'riskLevel': 'low',
            'doctorNotesKey': 'doctor_notes_generated_by_hemoai',
          },
        ]
      },
      {
        'id': '2',
        'name': 'Ayse Yilmaz',
        'relation': 'mother',
        'age': 42,
        'gender': 'female',
        'avatar': '👩',
        'lastTest': '2024-09-10',
        'riskLevel': 'high',
        'hemogram': {
          'hemoglobin': 10.8,
          'iron': 45.0,
          'white_blood_cells': 7.5,
          'platelets': 180.0,
          'hematocrit': 35.0,
        },
        'trends': {
          'hemoglobin': [11.2, 11.0, 10.8],
          'iron': [50.0, 47.0, 45.0],
        },
        'testHistory': [
          {
            'date': '2024-09-10',
            'hemogram': {
              'hemoglobin': 10.8,
              'iron': 45.0,
              'white_blood_cells': 7.5,
              'platelets': 180.0,
              'hematocrit': 35.0,
            },
            'riskLevel': 'high',
            'doctorNotesKey': 'doctor_notes_generated_by_hemoai',
          },
        ]
      },
    ]);
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _localizedRelation(String code) {
    final loc = LocalizationService();
    switch (code) {
      case 'father':
        return loc.getString('family_relation_father');
      case 'mother':
        return loc.getString('family_relation_mother');
      case 'child':
        return loc.getString('family_relation_child');
      case 'spouse':
        return loc.getString('family_relation_spouse');
      case 'sibling':
        return loc.getString('family_relation_sibling');
      default:
        return loc.getString('family_relation_other');
    }
  }

  String _localizedParamName(String key) => LocalizationService().getString(key);

  Color _getStatusColor(double value, double min, double max) {
    if (value < min || value > max) return Colors.red;
    if (value < min + (max - min) * 0.2 || value > max - (max - min) * 0.2) return Colors.orange;
    return Colors.green;
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final loc = LocalizationService();
    String lastTestText = member['lastTest'] ?? '';
    try {
      lastTestText = loc.formatDate(DateTime.parse(member['lastTest']));
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _riskColor(member['riskLevel']), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _riskColor(member['riskLevel']).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _riskColor(member['riskLevel']), width: 2),
                ),
                child: Center(child: Text(member['avatar'], style: const TextStyle(fontSize: 30))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member['name'], style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${_localizedRelation(member['relation'])} • ${loc.getString('age')}: ${member['age']}', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text('${loc.getString('last_test')}: $lastTestText', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _riskColor(member['riskLevel']), borderRadius: BorderRadius.circular(20)),
                child: Text(_localizedRiskLabel(member['riskLevel']), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(loc.getString('latest_hemogram_values'), style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: member['hemogram'].entries.take(3).map<Widget>((entry) {
                    final double value = entry.value;
                    final List<double> range = referenceRanges[entry.key] ?? [0, 0];
                    final Color statusColor = _getStatusColor(value, range[0], range[1]);
                    return Column(
                      children: [
                        Text(_localizedParamName(entry.key), style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 2),
                        Text(value.toStringAsFixed(1), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _localizedRiskLabel(String risk) {
    final loc = LocalizationService();
    switch (risk) {
      case 'high':
        return loc.getString('high_risk');
      case 'medium':
        return loc.getString('moderate_risk');
      case 'low':
        return loc.getString('low_risk');
      default:
        return loc.getString('unknown_risk');
    }
  }

  Widget _buildFamilyStats() {
    final loc = LocalizationService();
    final totalMembers = familyMembers.length;
    final highRisk = familyMembers.where((m) => m['riskLevel'] == 'high').length;
    final mediumRisk = familyMembers.where((m) => m['riskLevel'] == 'medium').length;
    final lowRisk = familyMembers.where((m) => m['riskLevel'] == 'low').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statChip(loc.getString('total'), totalMembers.toString()),
          _statChip(loc.getString('high_risk'), highRisk.toString()),
          _statChip(loc.getString('moderate_risk'), mediumRisk.toString()),
          _statChip(loc.getString('low_risk'), lowRisk.toString()),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85)))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.getString('family_health_panel')),
        actions: [
          IconButton(
            tooltip: loc.getString('family_add_member'),
            icon: const Icon(Icons.person_add),
            onPressed: _showAddMemberDialog,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: loc.getString('overview'), icon: const Icon(Icons.dashboard)),
            Tab(text: loc.getString('members'), icon: const Icon(Icons.people)),
            Tab(text: loc.getString('compare'), icon: const Icon(Icons.compare)),
            Tab(text: loc.getString('reminder'), icon: const Icon(Icons.notifications)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFamilyStats(),
                const SizedBox(height: 16),
                ...familyMembers.take(2).map(_buildMemberCard),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: familyMembers.map(_buildMemberCard).toList()),
          ),
          Center(child: Text(loc.getString('family_hemogram_comparison'))),
          Center(child: Text(loc.getString('lab_reminders'))),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    final loc = LocalizationService();
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String gender = 'male';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.getString('family_add_member')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: loc.getString('name_label')), controller: nameCtrl),
            const SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: loc.getString('relation_label')), controller: relationCtrl),
            const SizedBox(height: 8),
            TextField(decoration: InputDecoration(labelText: loc.getString('age')), controller: ageCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: gender,
              items: [
                DropdownMenuItem(value: 'male', child: Text(loc.getString('male'))),
                DropdownMenuItem(value: 'female', child: Text(loc.getString('female'))),
              ],
              onChanged: (v) => gender = (v ?? 'male'),
              decoration: InputDecoration(labelText: loc.getString('gender')),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.getString('cancel'))),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final relation = relationCtrl.text.trim();
              final age = int.tryParse(ageCtrl.text.trim()) ?? 0;
              if (name.isEmpty || relation.isEmpty || age <= 0) return;

              // Try persist to database if we have an active user
              int? id;
              final activeProfile = context.read<ActiveProfileService>();
              final userId = activeProfile.activeUserId;
              if (userId != null) {
                try {
                  id = await DatabaseHelper.instance.insertFamilyMember({
                    'user_id': userId,
                    'name': name,
                    'relation': relation,
                    'age': age,
                    'gender': gender,
                    'avatar': gender == 'female' ? '👩' : '👨',
                  });
                } catch (_) {
                  // ignore DB error and continue with in-memory add
                }
              }

              // Add to in-memory list immediately so UI reflects the change
              setState(() {
                familyMembers.add({
                  'id': id ?? DateTime.now().millisecondsSinceEpoch,
                  'name': name,
                  'relation': relation,
                  'age': age,
                  'gender': gender,
                  'avatar': gender == 'female' ? '👩' : '👨',
                  'lastTest': DateTime.now().toIso8601String().split('T').first,
                  'riskLevel': 'low',
                  'hemogram': {
                    'hemoglobin': 12.5,
                    'iron': 90.0,
                    'white_blood_cells': 6.5,
                    'platelets': 250.0,
                    'hematocrit': 40.0,
                  },
                  'trends': {},
                  'testHistory': [],
                });
              });
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.getString('family_member_added'))),
              );
            },
            child: Text(loc.getString('add')),
          )
        ],
      ),
    );
  }
}
