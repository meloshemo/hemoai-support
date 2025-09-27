import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../services/web_database_helper.dart';
import '../services/preferences_service.dart';
import '../services/localization_service.dart';

class AlternativeMedicineScreen extends StatefulWidget {
  const AlternativeMedicineScreen({Key? key}) : super(key: key);

  @override
  State<AlternativeMedicineScreen> createState() => _AlternativeMedicineScreenState();
}

class _AlternativeMedicineScreenState extends State<AlternativeMedicineScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late final WebDatabaseHelper _databaseHelper;
  final PreferencesService _preferencesService = PreferencesService();
  
  Map<String, double> userValues = {};
  List<String> recommendedCategories = [];
  bool isLoading = true;

  // Bitkisel çözümler verisi (localized)
  final Map<String, Map<String, dynamic>> herbalSolutions = {
    'herbal_cat_iron_deficiency': {
      'icon': '🩸',
      'color': Colors.red,
      'herbs': [
        {
          'name': 'herb_stinging_nettle_name',
          'usage': 'herb_stinging_nettle_usage',
          'benefits': 'herb_stinging_nettle_benefits',
          'preparation': 'herb_stinging_nettle_preparation',
          'warning': 'herb_stinging_nettle_warning',
        },
        {
          'name': 'herb_molasses_name',
          'usage': 'herb_molasses_usage',
          'benefits': 'herb_molasses_benefits',
          'preparation': 'herb_molasses_preparation',
          'warning': 'herb_molasses_warning',
        },
        {
          'name': 'herb_thyme_tea_name',
          'usage': 'herb_thyme_tea_usage',
          'benefits': 'herb_thyme_tea_benefits',
          'preparation': 'herb_thyme_tea_preparation',
          'warning': 'herb_thyme_tea_warning',
        },
      ]
    },
    'herbal_cat_anemia': {
      'icon': '🌿',
      'color': Colors.green,
      'herbs': [
        {
          'name': 'herb_carob_name',
          'usage': 'herb_carob_usage',
          'benefits': 'herb_carob_benefits',
          'preparation': 'herb_carob_preparation',
          'warning': 'herb_carob_warning',
        },
        {
          'name': 'herb_pomegranate_juice_name',
          'usage': 'herb_pomegranate_juice_usage',
          'benefits': 'herb_pomegranate_juice_benefits',
          'preparation': 'herb_pomegranate_juice_preparation',
          'warning': 'herb_pomegranate_juice_warning',
        },
        {
          'name': 'herb_beetroot_name',
          'usage': 'herb_beetroot_usage',
          'benefits': 'herb_beetroot_benefits',
          'preparation': 'herb_beetroot_preparation',
          'warning': 'herb_beetroot_warning',
        },
      ]
    },
    'herbal_cat_immunity': {
      'icon': '🛡️',
      'color': Colors.blue,
      'herbs': [
        {
          'name': 'herb_propolis_name',
          'usage': 'herb_propolis_usage',
          'benefits': 'herb_propolis_benefits',
          'preparation': 'herb_propolis_preparation',
          'warning': 'herb_propolis_warning',
        },
        {
          'name': 'herb_echinacea_name',
          'usage': 'herb_echinacea_usage',
          'benefits': 'herb_echinacea_benefits',
          'preparation': 'herb_echinacea_preparation',
          'warning': 'herb_echinacea_warning',
        },
        {
          'name': 'herb_ginger_name',
          'usage': 'herb_ginger_usage',
          'benefits': 'herb_ginger_benefits',
          'preparation': 'herb_ginger_preparation',
          'warning': 'herb_ginger_warning',
        },
      ]
    },
    'herbal_cat_platelets': {
      'icon': '🩹',
      'color': Colors.orange,
      'herbs': [
        {
          'name': 'herb_papaya_leaf_name',
          'usage': 'herb_papaya_leaf_usage',
          'benefits': 'herb_papaya_leaf_benefits',
          'preparation': 'herb_papaya_leaf_preparation',
          'warning': 'herb_papaya_leaf_warning',
        },
        {
          'name': 'herb_ginkgo_biloba_name',
          'usage': 'herb_ginkgo_biloba_usage',
          'benefits': 'herb_ginkgo_biloba_benefits',
          'preparation': 'herb_ginkgo_biloba_preparation',
          'warning': 'herb_ginkgo_biloba_warning',
        },
      ]
    },
  };

  // Yöresel tedavi yöntemleri (localized)
  final List<Map<String, dynamic>> traditionalMethods = [
    {
      'title': 'trad_cupping_title',
      'icon': '🩸',
      'description': 'trad_cupping_description',
      'benefits': 'trad_cupping_benefits',
      'procedure': 'trad_cupping_procedure',
      'frequency': 'trad_cupping_frequency',
      'warning': 'trad_cupping_warning',
      'color': Colors.red,
    },
    {
      'title': 'trad_leech_title',
      'icon': '🐛',
      'description': 'trad_leech_description',
      'benefits': 'trad_leech_benefits',
      'procedure': 'trad_leech_procedure',
      'frequency': 'trad_leech_frequency',
      'warning': 'trad_leech_warning',
      'color': Colors.green,
    },
    {
      'title': 'trad_dry_cupping_title',
      'icon': '🥤',
      'description': 'trad_dry_cupping_description',
      'benefits': 'trad_dry_cupping_benefits',
      'procedure': 'trad_dry_cupping_procedure',
      'frequency': 'trad_dry_cupping_frequency',
      'warning': 'trad_dry_cupping_warning',
      'color': Colors.blue,
    },
    {
      'title': 'trad_reflexology_title',
      'icon': '🦶',
      'description': 'trad_reflexology_description',
      'benefits': 'trad_reflexology_benefits',
      'procedure': 'trad_reflexology_procedure',
      'frequency': 'trad_reflexology_frequency',
      'warning': 'trad_reflexology_warning',
      'color': Colors.purple,
    },
    {
      'title': 'trad_aromatherapy_title',
      'icon': '🌸',
      'description': 'trad_aromatherapy_description',
      'benefits': 'trad_aromatherapy_benefits',
      'procedure': 'trad_aromatherapy_procedure',
      'frequency': 'trad_aromatherapy_frequency',
      'warning': 'trad_aromatherapy_warning',
      'color': Colors.pink,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _databaseHelper = WebDatabaseHelper.instance;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildHerbalCard(String category, Map<String, dynamic> categoryData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: categoryData['color'].withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: categoryData['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            categoryData['icon'],
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Text(
          Provider.of<LocalizationService>(context, listen: false).getString(category),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: categoryData['color'],
          ),
        ),
        subtitle: Text(
          Provider.of<LocalizationService>(context, listen: false)
              .getString('herbal_solutions_count')
              .replaceFirst('{count}', categoryData['herbs'].length.toString()),
          style: const TextStyle(color: Colors.grey),
        ),
        children: categoryData['herbs'].map<Widget>((herb) {
          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryData['color'].withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Provider.of<LocalizationService>(context, listen: false).getString(herb['name']),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildInfoRow(Provider.of<LocalizationService>(context, listen: false).getString('usage_label'), Provider.of<LocalizationService>(context, listen: false).getString(herb['usage']), Icons.schedule),
                _buildInfoRow(Provider.of<LocalizationService>(context, listen: false).getString('benefits_label'), Provider.of<LocalizationService>(context, listen: false).getString(herb['benefits']), Icons.favorite),
                _buildInfoRow(Provider.of<LocalizationService>(context, listen: false).getString('preparation_label'), Provider.of<LocalizationService>(context, listen: false).getString(herb['preparation']), Icons.build),
                
                if (herb['warning'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${Provider.of<LocalizationService>(context, listen: false).getString('warning_label')}: ${Provider.of<LocalizationService>(context, listen: false).getString(herb['warning'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraditionalCard(Map<String, dynamic> method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: method['color'].withOpacity(0.3)),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: method['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  method['icon'],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Provider.of<LocalizationService>(context, listen: false).getString(method['title']),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: method['color'],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Provider.of<LocalizationService>(context, listen: false).getString(method['description']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: method['color'].withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildMethodInfo(Provider.of<LocalizationService>(context, listen: false).getString('benefits_label'), Provider.of<LocalizationService>(context, listen: false).getString(method['benefits']), Icons.check_circle),
                _buildMethodInfo(Provider.of<LocalizationService>(context, listen: false).getString('application_label'), Provider.of<LocalizationService>(context, listen: false).getString(method['procedure']), Icons.build),
                _buildMethodInfo(Provider.of<LocalizationService>(context, listen: false).getString('frequency_label'), Provider.of<LocalizationService>(context, listen: false).getString(method['frequency']), Icons.schedule),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${Provider.of<LocalizationService>(context, listen: false).getString('warning_label')}: ${Provider.of<LocalizationService>(context, listen: false).getString(method['warning'])}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodInfo(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralAdvice() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // General warning (localized)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53E3E), Color(0xFFFF6B6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  Provider.of<LocalizationService>(context, listen: false).getString('important_reminder_title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Provider.of<LocalizationService>(context, listen: false).getString('important_reminder_body'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Basic rules (localized)
          Text(
            Provider.of<LocalizationService>(context, listen: false).getString('basic_rules_title'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE53E3E),
            ),
          ),
          const SizedBox(height: 16),
          
          ...Provider.of<LocalizationService>(context, listen: false)
              .getString('basic_rules_list')
              .split('\n')
              .map((rule) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rule,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          )).toList(),
          
          const SizedBox(height: 24),
          
          // Expert support (localized)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medical_services, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      Provider.of<LocalizationService>(context, listen: false).getString('expert_support_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  Provider.of<LocalizationService>(context, listen: false).getString('expert_support_body'),
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(currentRoute: '/alternative_medicine'),
      appBar: AppBar(
        title: Text(localizationService.getString('alternative_medicine')),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE53E3E),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE53E3E),
          tabs: [
            Tab(icon: const Icon(Icons.local_florist), text: localizationService.getString('herbal_solutions_tab')),
            Tab(icon: const Icon(Icons.healing), text: localizationService.getString('traditional_methods_tab')),
            Tab(icon: const Icon(Icons.info), text: localizationService.getString('general_info_tab')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Bitkisel Çözümler
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizationService.getString('herbal_solutions_for_hemogram'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizationService.getString('support_blood_values_naturally'),
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 24),
                
                ...herbalSolutions.entries.map((entry) => 
                  _buildHerbalCard(entry.key, entry.value)
                ).toList(),
              ],
            ),
          ),
          
          // Yöresel Tedaviler
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizationService.getString('traditional_treatments_title'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53E3E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizationService.getString('traditional_treatments_subtitle'),
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 24),
                
                ...traditionalMethods.map((method) => 
                  _buildTraditionalCard(method)
                ).toList(),
              ],
            ),
          ),
          
          // Genel Bilgi
          _buildGeneralAdvice(),
        ],
      ),
    );
  }
}