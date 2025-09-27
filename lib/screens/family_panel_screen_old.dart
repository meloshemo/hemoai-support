import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../services/localization_service.dart';

class FamilyPanelScreen extends StatefulWidget {
  const FamilyPanelScreen({Key? key}) : super(key: key);

  @override
  State<FamilyPanelScreen> createState() => _FamilyPanelScreenState();
}

class _FamilyPanelScreenState extends State<FamilyPanelScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  PreferencesService? _prefsService;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> familyMembers = [];
  bool _isLoading = true;
  

  // Canonical parameter keys with reference ranges
  final Map<String, List<double>> referenceRanges = {
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

  // Load sample data with canonical keys (no hard-coded UI strings)
  void _loadSampleData() {
    familyMembers = [
      {
        'id': '1',
        'name': 'Ahmet Yılmaz',
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
          {
            'date': '2024-03-15',
            'hemogram': {
              'hemoglobin': 12.8,
              'iron': 75.0,
              'white_blood_cells': 8.5,
              'platelets': 260.0,
              'hematocrit': 40.0,
            },
            'riskLevel': 'medium',
            'doctorNotesKey': 'doctor_notes_generated_by_hemoai',
          },
        ]
      },
      {
        'id': '2',
        'name': 'Ayşe Yılmaz',
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
          {
            'date': '2024-06-10',
            'hemogram': {
              'hemoglobin': 11.0,
              'iron': 47.0,
              'white_blood_cells': 7.2,
              'platelets': 175.0,
              'hematocrit': 36.0,
            },
            'riskLevel': 'high',
            'doctorNotesKey': 'doctor_notes_generated_by_hemoai',
          },
          {
            'date': '2024-03-10',
            'hemogram': {
              'hemoglobin': 11.2,
              'iron': 50.0,
              'white_blood_cells': 7.0,
              'platelets': 170.0,
              'hematocrit': 37.0,
            },
            'riskLevel': 'medium',
            'doctorNotesKey': 'doctor_notes_generated_by_hemoai',
          },
        ]
      },
      {
        'id': '3',
        'name': 'Zeynep Yılmaz',
        'relation': 'child',
        'age': 16,
        'gender': 'female',
        'avatar': '👧',
        'lastTest': '2024-09-20',
        'riskLevel': 'low',
        'hemogram': {
          'hemoglobin': 12.5,
          'iron': 95.0,
          'white_blood_cells': 6.8,
          'platelets': 250.0,
          'hematocrit': 38.0,
        },
        'trends': {
          'hemoglobin': [12.2, 12.3, 12.5],
          'iron': [88.0, 92.0, 95.0],
        },
        'testHistory': [
          {
            'date': '2024-09-20',
            'hemogram': {
              'hemoglobin': 12.5,
              'iron': 95.0,
              'white_blood_cells': 6.8,
              'platelets': 250.0,
              'hematocrit': 38.0,
            },
            'riskLevel': 'low',
            'doctorNotesKey': 'doctor_notes_generated_by_hemoai',
          },
          {
            'date': '2024-06-20',
            'hemogram': {
              'hemoglobin': 12.3,
              'iron': 92.0,
              'white_blood_cells': 6.5,
              'platelets': 240.0,
              'hematocrit': 37.5,
            },
            'riskLevel': 'low',
            'doctorNotesKey': 'doctor_notes_generated_by_hemoai',
          },
          {
            'date': '2024-03-20',
            'hemogram': {
              'hemoglobin': 12.2,
              'iron': 88.0,
              'white_blood_cells': 6.2,
              'platelets': 230.0,
              'hematocrit': 37.0,
            },
            'riskLevel': 'low',
            'doctorNotesKey': 'doctor_notes_generated_by_hemoai',
          },
        ]
      },
    ];

    setState(() {
      _isLoading = false;
    });
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

  String _localizedParamName(String key) {
    final loc = LocalizationService();
    switch (key) {
      case 'hemoglobin':
        return loc.getString('hemoglobin');
      case 'iron':
        return loc.getString('iron');
      case 'white_blood_cells':
        return loc.getString('white_blood_cells');
      case 'platelets':
        return loc.getString('platelets');
      case 'hematocrit':
        return loc.getString('hematocrit');
      default:
        return key;
    }
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _riskColor(member['riskLevel']), width: 2),
        boxShadow: [
          BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Üst kısım - Profil bilgileri
          Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _riskColor(member['riskLevel']).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _riskColor(member['riskLevel']), width: 2),
                ),
                child: Center(
                  child: Text(
                    member['avatar'],
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Bilgiler
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                    const SizedBox(height: 4),
                      Text(
                        '${_localizedRelation(member['relation'])} • ${loc.getString('age')}: ${member['age']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${loc.getString('last_test')}: $lastTestText',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Risk seviyesi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _riskColor(member['riskLevel']),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _localizedRiskLabel(member['riskLevel']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Alt kısım - Hemogram özeti
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  loc.getString('latest_hemogram_values'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: member['hemogram'].entries.take(3).map<Widget>((entry) {
                    double value = entry.value;
                    List<double> range = referenceRanges[entry.key] ?? [0, 0];
                    Color statusColor = _getStatusColor(value, range[0], range[1]);
                    
                    return Column(
                      children: [
                        Text(
                          _localizedParamName(entry.key),
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Aksiyonlar
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showMemberDetails(member),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: Text(loc.getString('details'), style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showTrends(member),
                  icon: const Icon(Icons.trending_up, size: 16),
                  label: Text(loc.getString('trend'), style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE53E3E),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFE53E3E)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(double value, double min, double max) {
    if (value < min || value > max) return Colors.red;
    if (value < min + (max - min) * 0.2 || value > max - (max - min) * 0.2) return Colors.orange;
    return Colors.green;
  }

  void _showMemberDetails(Map<String, dynamic> member) {
    final loc = LocalizationService();
    String lastTestText = member['lastTest'] ?? '';
    try {
      lastTestText = loc.formatDate(DateTime.parse(member['lastTest']));
    } catch (_) {}

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Başlık
              Row(
                children: [
                  Text(
                    member['avatar'],
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${member['name']} - ${loc.getString('medical_history')}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53E3E),
                          ),
                        ),
                        Text(
                          '${_localizedRelation(member['relation'])} • ${loc.getString('age')}: ${member['age']}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: const Color(0xFFE53E3E),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFFE53E3E),
                        tabs: [
                          Tab(icon: const Icon(Icons.analytics), text: LocalizationService().getString('current_status')),
                          Tab(icon: const Icon(Icons.history), text: LocalizationService().getString('history')),
                          Tab(icon: const Icon(Icons.compare_arrows), text: LocalizationService().getString('compare')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Son Durum Sekmesi
                            _buildCurrentStatus(member),
                            
                            // Geçmiş Sekmesi
                            _buildTestHistory(member),
                            
                            // Karşılaştırma Sekmesi
                            _buildComparison(member),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Alt butonlar
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/diet_program');
                      },
                      icon: const Icon(Icons.restaurant_menu),
                      label: Text(loc.getString('personal_diet_program')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/notifications');
                      },
                      icon: const Icon(Icons.notifications),
                      label: Text(loc.getString('reminder')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE53E3E),
                        side: const BorderSide(color: Color(0xFFE53E3E)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrends(Map<String, dynamic> member) {
    final loc = LocalizationService();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member['name']} - ${loc.getString('trend_analysis')}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: member['trends'].entries.map<Widget>((entry) {
              List<double> values = entry.value;
              String trend = values.last > values.first
                  ? '📈 ${loc.getString('trending_up')}'
                  : values.last < values.first
                      ? '📉 ${loc.getString('trending_down')}'
                      : '➡️ ${loc.getString('stable')}';
              
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localizedParamName(entry.key),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${loc.getString('last_3_months')}: ${values.join(' → ')}'),
                        Text(
                          trend,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.getString('close')),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyStats() {
    final loc = LocalizationService();
    int totalMembers = familyMembers.length;
  int highRisk = familyMembers.where((m) => m['riskLevel'] == 'high').length;
  int mediumRisk = familyMembers.where((m) => m['riskLevel'] == 'medium').length;
  int lowRisk = familyMembers.where((m) => m['riskLevel'] == 'low').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53E3E), Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.family_restroom, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                loc.getString('family_health_status'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(loc.getString('total'), totalMembers.toString(), Colors.white),
              _buildStatItem(loc.getString('high_risk'), highRisk.toString(), Colors.red[100]!),
              _buildStatItem(loc.getString('moderate_risk'), mediumRisk.toString(), Colors.orange[100]!),
              _buildStatItem(loc.getString('low_risk'), lowRisk.toString(), Colors.green[100]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE53E3E),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFE53E3E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    final loc = LocalizationService();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            loc.getString('family_hemogram_comparison'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE53E3E),
            ),
          ),
          const SizedBox(height: 24),
          
          ...referenceRanges.keys.map((parameter) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedParamName(parameter),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 12),
                ...familyMembers.map((member) {
                  double value = member['hemogram'][parameter] ?? 0.0;
                  List<double> range = referenceRanges[parameter]!;
                  Color statusColor = _getStatusColor(value, range[0], range[1]);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(member['avatar'], style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            member['name'].split(' ')[0],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(loc.getString('family_health_panel')),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddMemberDialog(),
            icon: const Icon(Icons.person_add),
            tooltip: loc.getString('family_add_member'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE53E3E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE53E3E),
          tabs: [
            Tab(icon: const Icon(Icons.dashboard), text: loc.getString('overview')),
            Tab(icon: const Icon(Icons.people), text: loc.getString('members')),
            Tab(icon: const Icon(Icons.compare), text: loc.getString('compare')),
            Tab(icon: const Icon(Icons.notifications), text: loc.getString('reminder')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Genel Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFamilyStats(),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    loc.getString('latest_test_results'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53E3E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...familyMembers.take(2).map((member) => _buildMemberCard(member)),
              ],
            ),
          ),
          
          // Üyeler Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  loc.getString('family_members'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 16),
                ...familyMembers.map((member) => _buildMemberCard(member)),
              ],
            ),
          ),
          
          // Karşılaştırma Tab
          _buildComparisonTab(),
          
          // Hatırlatıcı Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  loc.getString('lab_reminders'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.schedule, size: 40, color: Color(0xFFE53E3E)),
                      SizedBox(height: 16),
                      Text(
                        LocalizationService().getString('lab_reminders'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53E3E),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        LocalizationService().getString('family_lab_reminders_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    final loc = LocalizationService();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.getString('family_add_member')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: loc.getString('name_label'),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: loc.getString('relation_label'),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: loc.getString('age'),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.getString('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.getString('family_member_added')),
                  backgroundColor: const Color(0xFFE53E3E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
            child: Text(loc.getString('add'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(Map<String, dynamic> member) {
    final loc = LocalizationService();
    String lastTestText = member['lastTest'] ?? '';
    try {
      lastTestText = loc.formatDate(DateTime.parse(member['lastTest']));
    } catch (_) {}
    return SingleChildScrollView(
      child: Column(
        children: [
          // Risk durumu kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _riskColor(member['riskLevel']).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _riskColor(member['riskLevel'])),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _riskColor(member['riskLevel']),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        member['riskLevel'] == 'high' ? Icons.warning :
                        member['riskLevel'] == 'medium' ? Icons.info : Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${loc.getString('risk_level')}: ${_localizedRiskLabel(member['riskLevel'])}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: member['riskColor'],
                            ),
                          ),
                          Text(
                            '${loc.getString('last_test')}: $lastTestText',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (member['testHistory'] != null && member['testHistory'].isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    member['testHistory'][0]['doctorNotesKey'] != null
                        ? loc.getString(member['testHistory'][0]['doctorNotesKey'])
                        : '',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Güncel değerler
          Text(
            loc.getString('latest_hemogram_values'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE53E3E),
            ),
          ),
          const SizedBox(height: 16),
          
          ...member['hemogram'].entries.map<Widget>((entry) {
            double value = entry.value;
            List<double> range = referenceRanges[entry.key] ?? [0, 0];
            Color statusColor = _getStatusColor(value, range[0], range[1]);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _localizedParamName(entry.key),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        '(${range[0].toStringAsFixed(1)}-${range[1].toStringAsFixed(1)})',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTestHistory(Map<String, dynamic> member) {
    final loc = LocalizationService();
    List<dynamic> history = member['testHistory'] ?? [];
    
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(loc.getString('no_test_history'), style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> test = history[index];
  Color riskColor = _riskColor(test['riskLevel']);
        String dateText = test['date'];
        try {
          dateText = loc.formatDate(DateTime.parse(test['date']));
        } catch (_) {}
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: riskColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Test başlığı
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.bloodtype, color: riskColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: riskColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _localizedRiskLabel(test['riskLevel']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Doktor notları
              if (test['doctorNotesKey'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services, color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.getString(test['doctorNotesKey']),
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Özet değerler
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      loc.getString('hemogram_summary'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: test['hemogram'].entries.take(3).map<Widget>((entry) {
                        return Column(
                          children: [
                            Text(
                              _localizedParamName(entry.key),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            Text(
                              entry.value.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      },
    );
  }

  Widget _buildComparison(Map<String, dynamic> member) {
    final loc = LocalizationService();
    List<dynamic> history = member['testHistory'] ?? [];
    
    if (history.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              loc.getString('comparison_min_two_tests'),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    Map<String, dynamic> latest = history[0];
    Map<String, dynamic> previous = history[1];
    String latestDate = latest['date'];
    String previousDate = previous['date'];
    try {
      latestDate = loc.formatDate(DateTime.parse(latest['date']));
      previousDate = loc.formatDate(DateTime.parse(previous['date']));
    } catch (_) {}
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Karşılaştırma başlığı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53E3E), Color(0xFFFF6B6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.compare_arrows, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.getString('test_comparison'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$previousDate → $latestDate',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Parametre karşılaştırmaları
          ...latest['hemogram'].entries.map<Widget>((entry) {
            String param = entry.key;
            double latestValue = entry.value;
            double previousValue = previous['hemogram'][param] ?? 0.0;
            double change = latestValue - previousValue;
            double changePercent = previousValue != 0 ? (change / previousValue) * 100 : 0;
            
            List<double> range = referenceRanges[param] ?? [0, 0];
            Color latestColor = _getStatusColor(latestValue, range[0], range[1]);
            Color previousColor = _getStatusColor(previousValue, range[0], range[1]);
            
            IconData trendIcon;
            Color trendColor;
            if (change > 0) {
              trendIcon = Icons.trending_up;
              trendColor = Colors.green;
            } else if (change < 0) {
              trendIcon = Icons.trending_down;
              trendColor = Colors.red;
            } else {
              trendIcon = Icons.trending_flat;
              trendColor = Colors.grey;
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Parametre adı
                  Text(
                    _localizedParamName(param),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53E3E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Değer karşılaştırması
                  Row(
                    children: [
                      // Önceki değer
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: previousColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                previousDate,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                previousValue.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: previousColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Trend göstergesi
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Icon(trendIcon, color: trendColor, size: 30),
                            Text(
                              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: trendColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '(${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                color: trendColor,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Güncel değer
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: latestColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                latestDate,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                latestValue.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: latestColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Normal aralık
                  Text(
                    '${loc.getString('normal')}: ${range[0].toStringAsFixed(1)}-${range[1].toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }).toList(),
          
          // Genel değerlendirme
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics, color: Color(0xFFE53E3E), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      loc.getString('general_assessment'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _getComparisonSummary(latest, previous),
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getComparisonSummary(Map<String, dynamic> latest, Map<String, dynamic> previous) {
    final loc = LocalizationService();
    String latestRisk = latest['riskLevel'];
    String previousRisk = previous['riskLevel'];

    String latestRiskLabel = _localizedRiskLabel(latestRisk);
    String previousRiskLabel = _localizedRiskLabel(previousRisk);

    if (latestRisk == previousRisk) {
      return loc.getStringWithParams('comparison_stable', {
        'risk': latestRiskLabel,
      });
    } else {
  Map<String, int> riskValues = {'low': 1, 'medium': 2, 'high': 3};
      int latestValue = riskValues[latestRisk] ?? 0;
      int previousValue = riskValues[previousRisk] ?? 0;

      if (latestValue < previousValue) {
        return loc.getStringWithParams('comparison_improved', {
          'prev': previousRiskLabel,
          'curr': latestRiskLabel,
        });
      } else {
        return loc.getStringWithParams('comparison_worsened', {
          'prev': previousRiskLabel,
          'curr': latestRiskLabel,
        });
      }
    }
  }

  String _localizedRiskLabel(String riskTr) {
    final loc = LocalizationService();
    switch (riskTr) {
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
}
