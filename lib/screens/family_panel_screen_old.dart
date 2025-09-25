import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';

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
    {
      'id': '1',
      'name': 'Ahmet Yılmaz',
      'relation': 'Baba',
      'age': 45,
      'gender': 'Erkek',
      'avatar': '👨',
      'lastTest': '2024-09-15',
      'riskLevel': 'Orta',
      'riskColor': Colors.orange,
      'hemogram': {
        'Hemoglobin (g/dL)': 13.2,
        'Demir (mcg/dL)': 85.0,
        'Lökosit (K/uL)': 9.2,
        'Trombosit (K/uL)': 280.0,
        'Hematokrit (%)': 42.0,
      },
      'trends': {
        'Hemoglobin (g/dL)': [12.8, 13.0, 13.2], // Son 3 ay
        'Demir (mcg/dL)': [75.0, 80.0, 85.0],
      },
      'testHistory': [
        {
          'date': '2024-09-15',
          'hemogram': {
            'Hemoglobin (g/dL)': 13.2,
            'Demir (mcg/dL)': 85.0,
            'Lökosit (K/uL)': 9.2,
            'Trombosit (K/uL)': 280.0,
            'Hematokrit (%)': 42.0,
          },
          'riskLevel': 'Orta',
          'doctorNotes': 'Genel sağlık durumu iyi, demir seviyesi takip edilmeli.',
        },
        {
          'date': '2024-06-15',
          'hemogram': {
            'Hemoglobin (g/dL)': 13.0,
            'Demir (mcg/dL)': 80.0,
            'Lökosit (K/uL)': 8.8,
            'Trombosit (K/uL)': 270.0,
            'Hematokrit (%)': 41.0,
          },
          'riskLevel': 'Düşük',
          'doctorNotes': 'İyileşme var, diyet programına devam.',
        },
        {
          'date': '2024-03-15',
          'hemogram': {
            'Hemoglobin (g/dL)': 12.8,
            'Demir (mcg/dL)': 75.0,
            'Lökosit (K/uL)': 8.5,
            'Trombosit (K/uL)': 260.0,
            'Hematokrit (%)': 40.0,
          },
          'riskLevel': 'Orta',
          'doctorNotes': 'Demir eksikliği başlangıcı, beslenme düzenlenmeli.',
        },
      ]
    },
    {
      'id': '2',
      'name': 'Ayşe Yılmaz',
      'relation': 'Anne',
      'age': 42,
      'gender': 'Kadın',
      'avatar': '👩',
      'lastTest': '2024-09-10',
      'riskLevel': 'Yüksek',
      'riskColor': Colors.red,
      'hemogram': {
        'Hemoglobin (g/dL)': 10.8,
        'Demir (mcg/dL)': 45.0,
        'Lökosit (K/uL)': 7.5,
        'Trombosit (K/uL)': 180.0,
        'Hematokrit (%)': 35.0,
      },
      'trends': {
        'Hemoglobin (g/dL)': [11.2, 11.0, 10.8],
        'Demir (mcg/dL)': [50.0, 47.0, 45.0],
      },
      'testHistory': [
        {
          'date': '2024-09-10',
          'hemogram': {
            'Hemoglobin (g/dL)': 10.8,
            'Demir (mcg/dL)': 45.0,
            'Lökosit (K/uL)': 7.5,
            'Trombosit (K/uL)': 180.0,
            'Hematokrit (%)': 35.0,
          },
          'riskLevel': 'Yüksek',
          'doctorNotes': 'Şiddetli demir eksikliği anemisi, acil müdahale gerekli.',
        },
        {
          'date': '2024-06-10',
          'hemogram': {
            'Hemoglobin (g/dL)': 11.0,
            'Demir (mcg/dL)': 47.0,
            'Lökosit (K/uL)': 7.2,
            'Trombosit (K/uL)': 175.0,
            'Hematokrit (%)': 36.0,
          },
          'riskLevel': 'Yüksek',
          'doctorNotes': 'Anemi devam ediyor, tedavi planı revize edilmeli.',
        },
        {
          'date': '2024-03-10',
          'hemogram': {
            'Hemoglobin (g/dL)': 11.2,
            'Demir (mcg/dL)': 50.0,
            'Lökosit (K/uL)': 7.0,
            'Trombosit (K/uL)': 170.0,
            'Hematokrit (%)': 37.0,
          },
          'riskLevel': 'Orta',
          'doctorNotes': 'Hafif anemi tespit edildi, beslenme düzeni önemli.',
        },
      ]
    },
    {
      'id': '3',
      'name': 'Zeynep Yılmaz',
      'relation': 'Kız',
      'age': 16,
      'gender': 'Kadın',
      'avatar': '👧',
      'lastTest': '2024-09-20',
      'riskLevel': 'Düşük',
      'riskColor': Colors.green,
      'hemogram': {
        'Hemoglobin (g/dL)': 12.5,
        'Demir (mcg/dL)': 95.0,
        'Lökosit (K/uL)': 6.8,
        'Trombosit (K/uL)': 250.0,
        'Hematokrit (%)': 38.0,
      },
      'trends': {
        'Hemoglobin (g/dL)': [12.2, 12.3, 12.5],
        'Demir (mcg/dL)': [88.0, 92.0, 95.0],
      },
      'testHistory': [
        {
          'date': '2024-09-20',
          'hemogram': {
            'Hemoglobin (g/dL)': 12.5,
            'Demir (mcg/dL)': 95.0,
            'Lökosit (K/uL)': 6.8,
            'Trombosit (K/uL)': 250.0,
            'Hematokrit (%)': 38.0,
          },
          'riskLevel': 'Düşük',
          'doctorNotes': 'Mükemmel sağlık durumu, yaşına uygun değerler.',
        },
        {
          'date': '2024-06-20',
          'hemogram': {
            'Hemoglobin (g/dL)': 12.3,
            'Demir (mcg/dL)': 92.0,
            'Lökosit (K/uL)': 6.5,
            'Trombosit (K/uL)': 240.0,
            'Hematokrit (%)': 37.5,
          },
          'riskLevel': 'Düşük',
          'doctorNotes': 'Sağlıklı gelişim süreci, değerlerde iyileşme var.',
        },
        {
          'date': '2024-03-20',
          'hemogram': {
            'Hemoglobin (g/dL)': 12.2,
            'Demir (mcg/dL)': 88.0,
            'Lökosit (K/uL)': 6.2,
            'Trombosit (K/uL)': 230.0,
            'Hematokrit (%)': 37.0,
          },
          'riskLevel': 'Düşük',
          'doctorNotes': 'Yaşına uygun normal değerler, dengeli beslenme sürdürülmeli.',
        },
      ]
    },
  ];

  final Map<String, List<double>> referenceRanges = {
    'Hemoglobin (g/dL)': [12.0, 17.0],
    'Demir (mcg/dL)': [60.0, 170.0],
    'Lökosit (K/uL)': [4.0, 10.0],
    'Trombosit (K/uL)': [150.0, 400.0],
    'Hematokrit (%)': [38.0, 50.0],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: member['riskColor'], width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                  color: member['riskColor'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: member['riskColor'], width: 2),
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
                      '${member['relation']} • ${member['age']} yaş',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Son tahlil: ${member['lastTest']}',
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
                  color: member['riskColor'],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  member['riskLevel'],
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
                const Text(
                  'Son Hemogram Değerleri',
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
                          entry.key.split(' ')[0],
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
                  label: const Text('Detaylar', style: TextStyle(fontSize: 12)),
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
                  label: const Text('Trend', style: TextStyle(fontSize: 12)),
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
                          '${member['name']} - Sağlık Geçmişi',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53E3E),
                          ),
                        ),
                        Text(
                          '${member['relation']} • ${member['age']} yaş',
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
                      const TabBar(
                        labelColor: Color(0xFFE53E3E),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Color(0xFFE53E3E),
                        tabs: [
                          Tab(icon: Icon(Icons.analytics), text: 'Son Durum'),
                          Tab(icon: Icon(Icons.history), text: 'Geçmiş'),
                          Tab(icon: Icon(Icons.compare_arrows), text: 'Karşılaştır'),
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
                      label: const Text('Kişisel Diyet'),
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
                      label: const Text('Hatırlatıcı'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member['name']} - Trend Analizi'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: member['trends'].entries.map<Widget>((entry) {
              List<double> values = entry.value;
              String trend = values.last > values.first ? '📈 Yükselişte' : 
                            values.last < values.first ? '📉 Düşüşte' : '➡️ Stabil';
              
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
                      entry.key,
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
                        Text('Son 3 ay: ${values.join(' → ')}'),
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
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyStats() {
    int totalMembers = familyMembers.length;
    int highRisk = familyMembers.where((m) => m['riskLevel'] == 'Yüksek').length;
    int mediumRisk = familyMembers.where((m) => m['riskLevel'] == 'Orta').length;
    int lowRisk = familyMembers.where((m) => m['riskLevel'] == 'Düşük').length;

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
          const Row(
            children: [
              Icon(Icons.family_restroom, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text(
                'Aile Sağlık Durumu',
                style: TextStyle(
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
              _buildStatItem('Toplam', totalMembers.toString(), Colors.white),
              _buildStatItem('Yüksek Risk', highRisk.toString(), Colors.red[100]!),
              _buildStatItem('Orta Risk', mediumRisk.toString(), Colors.orange[100]!),
              _buildStatItem('Düşük Risk', lowRisk.toString(), Colors.green[100]!),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Aile Hemogram Karşılaştırması',
            style: TextStyle(
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
                  color: Colors.grey.withOpacity(0.1),
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
                  parameter,
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
                            color: statusColor.withOpacity(0.1),
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
                }).toList(),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Aile Sağlık Paneli'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddMemberDialog(),
            icon: const Icon(Icons.person_add),
            tooltip: 'Aile Üyesi Ekle',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE53E3E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE53E3E),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Genel'),
            Tab(icon: Icon(Icons.people), text: 'Üyeler'),
            Tab(icon: Icon(Icons.compare), text: 'Karşılaştır'),
            Tab(icon: Icon(Icons.notifications), text: 'Hatırlatıcı'),
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Son Tahlil Sonuçları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53E3E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...familyMembers.take(2).map((member) => _buildMemberCard(member)).toList(),
              ],
            ),
          ),
          
          // Üyeler Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Aile Üyeleri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 16),
                ...familyMembers.map((member) => _buildMemberCard(member)).toList(),
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
                const Text(
                  'Tahlil Hatırlatıcıları',
                  style: TextStyle(
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
                  child: const Column(
                    children: [
                      Icon(Icons.schedule, size: 40, color: Color(0xFFE53E3E)),
                      SizedBox(height: 16),
                      Text(
                        'Tahlil Hatırlatıcıları',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53E3E),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Aile üyelerinizin düzenli tahlil hatırlatıcılarını burada yönetebileceksiniz.',
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Aile Üyesi Ekle'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Yakınlık Derecesi',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Yaş',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Aile üyesi başarıyla eklendi!'),
                  backgroundColor: Color(0xFFE53E3E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53E3E)),
            child: const Text('Ekle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(Map<String, dynamic> member) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Risk durumu kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: member['riskColor'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: member['riskColor']),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: member['riskColor'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        member['riskLevel'] == 'Yüksek' ? Icons.warning :
                        member['riskLevel'] == 'Orta' ? Icons.info : Icons.check_circle,
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
                            'Risk Seviyesi: ${member['riskLevel']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: member['riskColor'],
                            ),
                          ),
                          Text(
                            'Son tahlil: ${member['lastTest']}',
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
                    member['testHistory'][0]['doctorNotes'] ?? '',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Güncel değerler
          const Text(
            'Güncel Hemogram Değerleri',
            style: TextStyle(
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
                      entry.key,
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
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTestHistory(Map<String, dynamic> member) {
    List<dynamic> history = member['testHistory'] ?? [];
    
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Henüz geçmiş test sonucu yok', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> test = history[index];
        Color riskColor = test['riskLevel'] == 'Yüksek' ? Colors.red :
                         test['riskLevel'] == 'Orta' ? Colors.orange : Colors.green;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: riskColor.withOpacity(0.3)),
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
                      color: riskColor.withOpacity(0.1),
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
                          test['date'],
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
                            test['riskLevel'],
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
              if (test['doctorNotes'] != null) ...[
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
                          test['doctorNotes'],
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
                  color: riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Hemogram Özeti',
                      style: TextStyle(
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
                              entry.key.split(' ')[0],
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
    List<dynamic> history = member['testHistory'] ?? [];
    
    if (history.length < 2) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Karşılaştırma için en az 2 test sonucu gerekli',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    Map<String, dynamic> latest = history[0];
    Map<String, dynamic> previous = history[1];
    
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
                      const Text(
                        'Test Karşılaştırması',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${previous['date']} → ${latest['date']}',
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
                    param,
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
                            color: previousColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                previous['date'],
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
                            color: latestColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                latest['date'],
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
                    'Normal: ${range[0].toStringAsFixed(1)}-${range[1].toStringAsFixed(1)}',
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
                const Row(
                  children: [
                    Icon(Icons.analytics, color: Color(0xFFE53E3E), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Genel Değerlendirme',
                      style: TextStyle(
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
    String latestRisk = latest['riskLevel'];
    String previousRisk = previous['riskLevel'];
    
    if (latestRisk == previousRisk) {
      return 'Sağlık durumunuz $latestRisk risk seviyesinde stabil kalıyor. Mevcut tedavi ve beslenme planınıza devam edin.';
    } else {
      Map<String, int> riskValues = {'Düşük': 1, 'Orta': 2, 'Yüksek': 3};
      int latestValue = riskValues[latestRisk] ?? 0;
      int previousValue = riskValues[previousRisk] ?? 0;
      
      if (latestValue < previousValue) {
        return 'Tebrikler! Sağlık durumunuzda iyileşme var. $previousRisk riskten $latestRisk riske düştünüz. Mevcut programınıza devam edin.';
      } else {
        return 'Dikkat! Risk seviyeniz $previousRisk\'tan $latestRisk\'a yükseldi. Doktor kontrolü ve tedavi planı revizyonu gerekli olabilir.';
      }
    }
  }
}
