import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/app_drawer.dart';
// import '../services/web_database_helper.dart';
import '../services/localization_service.dart';
import '../services/preferences_service.dart';

class AlternativeMedicineScreen extends StatefulWidget {
  const AlternativeMedicineScreen({super.key});

  @override
  State<AlternativeMedicineScreen> createState() => _AlternativeMedicineScreenState();
}

class _AlternativeMedicineScreenState extends State<AlternativeMedicineScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  
  Map<String, double> userValues = {};
  List<String> recommendedCategories = [];
  int? userAge;
  String? userGender;
  bool isLoading = true;
  
  // Search and filter functionality
  String _searchQuery = '';
  String _selectedCategory = 'all';
  Set<String> _favoriteHerbs = {};
  bool _showOnlyFavorites = false;
  final TextEditingController _searchController = TextEditingController();

  // Reference ranges (canonical keys)
  static const Map<String, Map<String, double>> _ref = {
    'hemoglobin': {'min': 12.0, 'max': 17.0},
    'iron': {'min': 60.0, 'max': 170.0},
    'white_blood_cells': {'min': 4.0, 'max': 11.0},
    'platelets': {'min': 150.0, 'max': 450.0},
    'ferritin': {'min': 15.0, 'max': 150.0},
    'red_blood_cells': {'min': 4.0, 'max': 6.0},
    'hematocrit': {'min': 35.0, 'max': 50.0},
    'mcv': {'min': 80.0, 'max': 100.0},
    'mch': {'min': 27.0, 'max': 32.0},
    'mchc': {'min': 32.0, 'max': 36.0},
    'rdw': {'min': 11.5, 'max': 14.5},
    'neutrophil': {'min': 40.0, 'max': 60.0},
    'lymphocyte': {'min': 20.0, 'max': 40.0},
    'monocyte': {'min': 2.0, 'max': 8.0},
    'eosinophil': {'min': 1.0, 'max': 4.0},
    'basophil': {'min': 0.0, 'max': 1.0},
  };

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
    'herbal_cat_ferritin_low': {
      'icon': '🧪',
      'color': Colors.brown,
      'herbs': [
        {
          'name': 'herb_molasses_name',
          'usage': 'herb_molasses_usage',
          'benefits': 'herb_molasses_benefits',
          'preparation': 'herb_molasses_preparation',
          'warning': 'herb_molasses_warning',
        },
        {
          'name': 'herb_stinging_nettle_name',
          'usage': 'herb_stinging_nettle_usage',
          'benefits': 'herb_stinging_nettle_benefits',
          'preparation': 'herb_stinging_nettle_preparation',
          'warning': 'herb_stinging_nettle_warning',
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
    'herbal_cat_rbc_support': {
      'icon': '🫁',
      'color': Colors.indigo,
      'herbs': [
        {
          'name': 'herb_beetroot_name',
          'usage': 'herb_beetroot_usage',
          'benefits': 'herb_beetroot_benefits',
          'preparation': 'herb_beetroot_preparation',
          'warning': 'herb_beetroot_warning',
        },
        {
          'name': 'herb_pomegranate_juice_name',
          'usage': 'herb_pomegranate_juice_usage',
          'benefits': 'herb_pomegranate_juice_benefits',
          'preparation': 'herb_pomegranate_juice_preparation',
          'warning': 'herb_pomegranate_juice_warning',
        },
        {
          'name': 'herb_carob_name',
          'usage': 'herb_carob_usage',
          'benefits': 'herb_carob_benefits',
          'preparation': 'herb_carob_preparation',
          'warning': 'herb_carob_warning',
        },
      ]
    },
    'herbal_cat_hematocrit_balance': {
      'icon': '🩺',
      'color': Colors.cyan,
      'herbs': [
        {
          'name': 'herb_beetroot_name',
          'usage': 'herb_beetroot_usage',
          'benefits': 'herb_beetroot_benefits',
          'preparation': 'herb_beetroot_preparation',
          'warning': 'herb_beetroot_warning',
        },
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
      ]
    },
    'herbal_cat_microcytosis_support': {
      'icon': '🧬',
      'color': Colors.deepOrange,
      'herbs': [
        {
          'name': 'herb_stinging_nettle_name',
          'usage': 'herb_stinging_nettle_usage',
          'benefits': 'herb_stinging_nettle_benefits',
          'preparation': 'herb_stinging_nettle_preparation',
          'warning': 'herb_stinging_nettle_warning',
        },
        {
          'name': 'herb_thyme_tea_name',
          'usage': 'herb_thyme_tea_usage',
          'benefits': 'herb_thyme_tea_benefits',
          'preparation': 'herb_thyme_tea_preparation',
          'warning': 'herb_thyme_tea_warning',
        },
        {
          'name': 'herb_rosehip_name',
          'usage': 'herb_rosehip_usage',
          'benefits': 'herb_rosehip_benefits',
          'preparation': 'herb_rosehip_preparation',
          'warning': 'herb_rosehip_warning',
        },
      ]
    },
    'herbal_cat_macrocytosis_support': {
      'icon': '🧫',
      'color': Colors.purple,
      'herbs': [
        {
          'name': 'herb_spirulina_name',
          'usage': 'herb_spirulina_usage',
          'benefits': 'herb_spirulina_benefits',
          'preparation': 'herb_spirulina_preparation',
          'warning': 'herb_spirulina_warning',
        },
        {
          'name': 'herb_wheatgrass_name',
          'usage': 'herb_wheatgrass_usage',
          'benefits': 'herb_wheatgrass_benefits',
          'preparation': 'herb_wheatgrass_preparation',
          'warning': 'herb_wheatgrass_warning',
        },
        {
          'name': 'herb_carob_name',
          'usage': 'herb_carob_usage',
          'benefits': 'herb_carob_benefits',
          'preparation': 'herb_carob_preparation',
          'warning': 'herb_carob_warning',
        },
      ]
    },
    'herbal_cat_hypochromia_support': {
      'icon': '🎯',
      'color': Colors.teal,
      'herbs': [
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
        {
          'name': 'herb_stinging_nettle_name',
          'usage': 'herb_stinging_nettle_usage',
          'benefits': 'herb_stinging_nettle_benefits',
          'preparation': 'herb_stinging_nettle_preparation',
          'warning': 'herb_stinging_nettle_warning',
        },
      ]
    },
    'herbal_cat_rdw_high_support': {
      'icon': '📈',
      'color': Colors.amber,
      'herbs': [
        {
          'name': 'herb_moringa_name',
          'usage': 'herb_moringa_usage',
          'benefits': 'herb_moringa_benefits',
          'preparation': 'herb_moringa_preparation',
          'warning': 'herb_moringa_warning',
        },
        {
          'name': 'herb_bee_pollen_name',
          'usage': 'herb_bee_pollen_usage',
          'benefits': 'herb_bee_pollen_benefits',
          'preparation': 'herb_bee_pollen_preparation',
          'warning': 'herb_bee_pollen_warning',
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
    'herbal_cat_neutrophil_support': {
      'icon': '🧿',
      'color': Colors.redAccent,
      'herbs': [
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
        {
          'name': 'herb_turmeric_name',
          'usage': 'herb_turmeric_usage',
          'benefits': 'herb_turmeric_benefits',
          'preparation': 'herb_turmeric_preparation',
          'warning': 'herb_turmeric_warning',
        },
      ]
    },
    'herbal_cat_lymphocyte_support': {
      'icon': '🛡️',
      'color': Colors.blueGrey,
      'herbs': [
        {
          'name': 'herb_green_tea_name',
          'usage': 'herb_green_tea_usage',
          'benefits': 'herb_green_tea_benefits',
          'preparation': 'herb_green_tea_preparation',
          'warning': 'herb_green_tea_warning',
        },
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
      ]
    },
    'herbal_cat_allergy_support': {
      'icon': '🤧',
      'color': Colors.lightGreen,
      'herbs': [
        {
          'name': 'herb_stinging_nettle_name',
          'usage': 'herb_stinging_nettle_usage',
          'benefits': 'herb_stinging_nettle_benefits',
          'preparation': 'herb_stinging_nettle_preparation',
          'warning': 'herb_stinging_nettle_warning',
        },
        {
          'name': 'herb_chamomile_name',
          'usage': 'herb_chamomile_usage',
          'benefits': 'herb_chamomile_benefits',
          'preparation': 'herb_chamomile_preparation',
          'warning': 'herb_chamomile_warning',
        },
        {
          'name': 'herb_green_tea_name',
          'usage': 'herb_green_tea_usage',
          'benefits': 'herb_green_tea_benefits',
          'preparation': 'herb_green_tea_preparation',
          'warning': 'herb_green_tea_warning',
        },
      ]
    },
    'herbal_cat_antiinflammatory_support': {
      'icon': '🔥',
      'color': Colors.deepPurple,
      'herbs': [
        {
          'name': 'herb_turmeric_name',
          'usage': 'herb_turmeric_usage',
          'benefits': 'herb_turmeric_benefits',
          'preparation': 'herb_turmeric_preparation',
          'warning': 'herb_turmeric_warning',
        },
        {
          'name': 'herb_ginger_name',
          'usage': 'herb_ginger_usage',
          'benefits': 'herb_ginger_benefits',
          'preparation': 'herb_ginger_preparation',
          'warning': 'herb_ginger_warning',
        },
        {
          'name': 'herb_green_tea_name',
          'usage': 'herb_green_tea_usage',
          'benefits': 'herb_green_tea_benefits',
          'preparation': 'herb_green_tea_preparation',
          'warning': 'herb_green_tea_warning',
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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadRecommendations();
    _loadFavorites();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Load last hemogram values and compute recommended herbal categories
  Future<void> _loadRecommendations() async {
    try {
      final prefs = await PreferencesService.getInstance();
      final last = prefs.getLastHemogramValues() ?? {};
      final rec = _computeRecommendations(last);
      final info = prefs.getUserInfo();
      if (!mounted) return;
      setState(() {
        userValues = Map<String, double>.from(last);
        recommendedCategories = rec;
        userAge = (info?['age'] as int?)?.toInt();
        userGender = (info?['gender'] as String?);
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        userValues = {};
        recommendedCategories = [];
        isLoading = false;
      });
    }
  }
  
  void _loadFavorites() async {
    try {
      final prefs = await PreferencesService.getInstance();
      final favorites = prefs.getFavoriteHerbs() ?? [];
      if (!mounted) return;
      setState(() {
        _favoriteHerbs = favorites.toSet();
      });
    } catch (e) {
      // Handle error silently
    }
  }
  
  void _toggleFavorite(String herbName) async {
    setState(() {
      if (_favoriteHerbs.contains(herbName)) {
        _favoriteHerbs.remove(herbName);
      } else {
        _favoriteHerbs.add(herbName);
      }
    });
    
    try {
      final prefs = await PreferencesService.getInstance();
      prefs.saveFavoriteHerbs(_favoriteHerbs.toList());
    } catch (e) {
      // Handle error - could show a snackbar
    }
  }
  
  List<MapEntry<String, Map<String, dynamic>>> _getFilteredHerbalSolutions() {
    var entries = herbalSolutions.entries.toList();
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      entries = entries.where((entry) {
        final loc = Provider.of<LocalizationService>(context, listen: false);
        final categoryName = loc.getString(entry.key).toLowerCase();
        final herbs = entry.value['herbs'] as List;
        
        // Check category name
        final categoryMatches = categoryName.contains(_searchQuery.toLowerCase());
        
        // Check herb names and descriptions
        final herbMatches = herbs.any((herb) {
          final herbName = loc.getString(herb['name']).toLowerCase();
          final herbBenefits = loc.getString(herb['benefits']).toLowerCase();
          return herbName.contains(_searchQuery.toLowerCase()) ||
                 herbBenefits.contains(_searchQuery.toLowerCase());
        });
        
        return categoryMatches || herbMatches;
      }).toList();
    }
    
    // Filter by category
    if (_selectedCategory != 'all') {
      entries = entries.where((entry) => entry.key == _selectedCategory).toList();
    }
    
    // Filter by favorites
    if (_showOnlyFavorites) {
      entries = entries.where((entry) {
        final herbs = entry.value['herbs'] as List;
        return herbs.any((herb) => _favoriteHerbs.contains(herb['name']));
      }).toList();
    }
    
    return entries;
  }

  // Decide which herbal categories to recommend based on values
  List<String> _computeRecommendations(Map<String, double> values) {
    final List<String> rec = [];
    bool below(String key, double min) => (values[key] != null) && values[key]! < min;
    bool above(String key, double max) => (values[key] != null) && values[key]! > max;

    final ref = _ref;

    if (below('hemoglobin', ref['hemoglobin']!['min'] as double)) {
      // Anemia-related
      rec.addAll(['herbal_cat_anemia', 'herbal_cat_iron_deficiency']);
    }
    if (below('iron', ref['iron']!['min'] as double) && !rec.contains('herbal_cat_iron_deficiency')) {
      rec.add('herbal_cat_iron_deficiency');
    }
    if (below('ferritin', ref['ferritin']!['min'] as double)) {
      rec.add('herbal_cat_ferritin_low');
    }
    // Immune support when WBC abnormal (above or below bounds)
    if (above('white_blood_cells', ref['white_blood_cells']!['max'] as double) ||
        below('white_blood_cells', ref['white_blood_cells']!['min'] as double)) {
      rec.add('herbal_cat_immunity');
    }
    if (below('platelets', ref['platelets']!['min'] as double)) {
      rec.add('herbal_cat_platelets');
    }
    if (below('red_blood_cells', ref['red_blood_cells']!['min'] as double)) {
      rec.add('herbal_cat_rbc_support');
    }
    if (below('hematocrit', ref['hematocrit']!['min'] as double)) {
      rec.add('herbal_cat_hematocrit_balance');
    }
    // Indices
    if (below('mcv', ref['mcv']!['min'] as double)) {
      rec.add('herbal_cat_microcytosis_support');
    } else if (above('mcv', ref['mcv']!['max'] as double)) {
      rec.add('herbal_cat_macrocytosis_support');
    }
    if (below('mch', ref['mch']!['min'] as double) || below('mchc', ref['mchc']!['min'] as double)) {
      rec.add('herbal_cat_hypochromia_support');
    }
    if (above('rdw', ref['rdw']!['max'] as double)) {
      rec.add('herbal_cat_rdw_high_support');
    }
    // Differential
    if (above('neutrophil', ref['neutrophil']!['max'] as double) || below('neutrophil', ref['neutrophil']!['min'] as double)) {
      rec.add('herbal_cat_neutrophil_support');
    }
    if (above('lymphocyte', ref['lymphocyte']!['max'] as double) || below('lymphocyte', ref['lymphocyte']!['min'] as double)) {
      rec.add('herbal_cat_lymphocyte_support');
    }
    if (above('eosinophil', ref['eosinophil']!['max'] as double) || above('basophil', ref['basophil']!['max'] as double)) {
      rec.add('herbal_cat_allergy_support');
    }
    if (above('monocyte', ref['monocyte']!['max'] as double)) {
      rec.add('herbal_cat_antiinflammatory_support');
    }

    // Keep only categories that exist in our map and dedupe while preserving order
    final seen = <String>{};
    final filtered = <String>[];
    for (final k in rec) {
      if (herbalSolutions.containsKey(k) && !seen.contains(k)) {
        seen.add(k);
        filtered.add(k);
      }
    }
    return filtered;
  }

  String _fb(LocalizationService loc, String key, String en) {
    final v = loc.getString(key);
    return v == key ? en : v;
  }
  
  Widget _buildSearchAndFilters(LocalizationService localizationService, ThemeData theme, ColorScheme scheme) {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _fb(localizationService, 'search_herbs_placeholder', 'Search herbs and solutions...'),
                prefixIcon: Icon(Icons.search, color: scheme.primary),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Favorites filter
                FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: _showOnlyFavorites ? Colors.white : scheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _fb(localizationService, 'favorites', 'Favorites'),
                        style: TextStyle(
                          color: _showOnlyFavorites ? Colors.white : scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  selected: _showOnlyFavorites,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyFavorites = selected;
                    });
                  },
                  backgroundColor: scheme.surface,
                  selectedColor: scheme.primary,
                ),
                const SizedBox(width: 8),
                
                // Category filters
                ...herbalSolutions.keys.take(3).map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      localizationService.getString(category),
                      style: TextStyle(
                        color: _selectedCategory == category ? Colors.white : scheme.primary,
                      ),
                    ),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'all';
                      });
                    },
                    backgroundColor: scheme.surface,
                    selectedColor: scheme.primary,
                  ),
                )),
                
                // "All" filter
                FilterChip(
                  label: Text(
                    _fb(localizationService, 'all_categories', 'All'),
                    style: TextStyle(
                      color: _selectedCategory == 'all' ? Colors.white : scheme.primary,
                    ),
                  ),
                  selected: _selectedCategory == 'all',
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = 'all';
                    });
                  },
                  backgroundColor: scheme.surface,
                  selectedColor: scheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHerbalCard(String category, Map<String, dynamic> categoryData) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final reason = _reasonForCategory(category, loc);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: categoryData['color'].withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.08),
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
            color: categoryData['color'].withValues(alpha: 0.1),
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
            color: scheme.primary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reason != null) Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '${loc.getString('reason_label')}: $reason',
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            Text(
              loc.getString('herbal_solutions_count').replaceFirst('{count}', categoryData['herbs'].length.toString()),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        children: ((categoryData['herbs'] as List).cast<Map<String, dynamic>>())
            .map<Widget>((herb) {
          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: categoryData['color'].withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Provider.of<LocalizationService>(context, listen: false).getString(herb['name']),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _favoriteHerbs.contains(herb['name']) ? Icons.favorite : Icons.favorite_border,
                        color: _favoriteHerbs.contains(herb['name']) ? scheme.primary : scheme.onSurface.withValues(alpha: 0.6),
                      ),
                      tooltip: Provider.of<LocalizationService>(context, listen: false).getString('toggle_favorite'),
                      onPressed: () => _toggleFavorite(herb['name']),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                _buildInfoRow(Provider.of<LocalizationService>(context, listen: false).getString('usage_label'), Provider.of<LocalizationService>(context, listen: false).getString(herb['usage']), Icons.schedule),
                _buildInfoRow(Provider.of<LocalizationService>(context, listen: false).getString('benefits_label'), Provider.of<LocalizationService>(context, listen: false).getString(herb['benefits']), Icons.favorite),
                _buildInfoRow(Provider.of<LocalizationService>(context, listen: false).getString('preparation_label'), Provider.of<LocalizationService>(context, listen: false).getString(herb['preparation']), Icons.build),

                // Light personalization notes
                if ((userAge ?? 0) >= 65)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.getString('age_personalization_note'),
                            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isFemale(userGender))
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.getString('female_general_caution'),
                            style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (herb['warning'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: scheme.onErrorContainer, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${Provider.of<LocalizationService>(context, listen: false).getString('warning_label')}: ${Provider.of<LocalizationService>(context, listen: false).getString(herb['warning'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onErrorContainer,
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

  // Basic diacritic stripper to compare gender strings without locale-specific characters
  String _stripDiacritics(String input) {
    return input
        .replaceAll('\u015f', 's') // ş
        .replaceAll('\u015e', 'S') // Ş
        .replaceAll('\u011f', 'g') // ğ
        .replaceAll('\u011e', 'G') // Ğ
        .replaceAll('\u00f6', 'o') // ö
        .replaceAll('\u00d6', 'O') // Ö
        .replaceAll('\u00fc', 'u') // ü
        .replaceAll('\u00dc', 'U') // Ü
        .replaceAll('\u0131', 'i') // ı
        .replaceAll('\u00e7', 'c') // ç
        .replaceAll('\u00c7', 'C'); // Ç
  }

  bool _isFemale(String? g) {
    if (g == null) return false;
    final s = _stripDiacritics(g.toLowerCase());
    return s.contains('female') || s.contains('kadin') || s.contains('woman');
  }

  String? _reasonForCategory(String category, LocalizationService loc) {
    String statusFor(double v, String key) {
      final min = _ref[key]!['min']!;
      final max = _ref[key]!['max']!;
      if (v < min) return loc.getString('status_low');
      if (v > max) return loc.getString('status_high');
      return loc.getString('status_normal');
    }

    String tpl(String key) {
      final v = userValues[key];
      if (v == null) return '';
      final s = statusFor(v, key);
      final range = loc.getStringWithParams('normal_range_template', {
        'min': _ref[key]!['min']!.toStringAsFixed(1),
        'max': _ref[key]!['max']!.toStringAsFixed(1),
      });
      final paramName = Provider.of<LocalizationService>(context, listen: false).getString(key);
      return '$paramName $s: ${v.toStringAsFixed(1)} ($range)';
    }

    switch (category) {
      case 'herbal_cat_anemia':
        return tpl('hemoglobin');
      case 'herbal_cat_iron_deficiency':
        return userValues['iron'] != null ? tpl('iron') : tpl('hemoglobin');
      case 'herbal_cat_ferritin_low':
        return tpl('ferritin');
      case 'herbal_cat_immunity':
        return tpl('white_blood_cells');
      case 'herbal_cat_platelets':
        return tpl('platelets');
      case 'herbal_cat_rbc_support':
        return tpl('red_blood_cells');
      case 'herbal_cat_hematocrit_balance':
        return tpl('hematocrit');
      case 'herbal_cat_microcytosis_support':
      case 'herbal_cat_macrocytosis_support':
        return tpl('mcv');
      case 'herbal_cat_hypochromia_support':
        return userValues['mch'] != null ? tpl('mch') : tpl('mchc');
      case 'herbal_cat_rdw_high_support':
        return tpl('rdw');
      case 'herbal_cat_neutrophil_support':
        return tpl('neutrophil');
      case 'herbal_cat_lymphocyte_support':
        return tpl('lymphocyte');
      case 'herbal_cat_allergy_support':
        return userValues['eosinophil'] != null ? tpl('eosinophil') : tpl('basophil');
      case 'herbal_cat_antiinflammatory_support':
        return tpl('monocyte');
      default:
        return null;
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTraditionalCard(Map<String, dynamic> method) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: method['color'].withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.08),
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
                  color: method['color'].withValues(alpha: 0.1),
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
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Provider.of<LocalizationService>(context, listen: false).getString(method['description']),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
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
              color: method['color'].withValues(alpha: 0.05),
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
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: scheme.onErrorContainer, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${Provider.of<LocalizationService>(context, listen: false).getString('warning_label')}: ${Provider.of<LocalizationService>(context, listen: false).getString(method['warning'])}',
                    style: TextStyle(
                      color: scheme.onErrorContainer,
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
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralAdvice() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // General warning (localized)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.health_and_safety, color: scheme.onErrorContainer, size: 32),
                const SizedBox(height: 12),
                Text(
                  Provider.of<LocalizationService>(context, listen: false).getString('important_reminder_title'),
                  style: TextStyle(
                    color: scheme.onErrorContainer,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Provider.of<LocalizationService>(context, listen: false).getString('important_reminder_body'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onErrorContainer, fontSize: 14),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Basic rules (localized)
          Text(
            Provider.of<LocalizationService>(context, listen: false).getString('basic_rules_title'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
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
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: scheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rule,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 24),
          
          // Expert support (localized)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services, color: scheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      Provider.of<LocalizationService>(context, listen: false).getString('expert_support_title'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  Provider.of<LocalizationService>(context, listen: false).getString('expert_support_body'),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.4),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(currentRoute: '/alternative_medicine'),
      appBar: AppBar(
        title: Text(localizationService.getString('alternative_medicine')),
        backgroundColor: theme.appBarTheme.backgroundColor ?? scheme.surface,
        foregroundColor: theme.appBarTheme.foregroundColor ?? scheme.onSurface,
        elevation: 0,
        actions: [
          // Quick toggle favorites filter
          IconButton(
            tooltip: localizationService.getString('favorites'),
            icon: Icon(_showOnlyFavorites ? Icons.favorite : Icons.favorite_border),
            onPressed: () => setState(() => _showOnlyFavorites = !_showOnlyFavorites),
          ),
          // Share favorites
          IconButton(
            tooltip: localizationService.getString('share_favorites'),
            icon: const Icon(Icons.ios_share),
            onPressed: () {
              final favs = _favoriteHerbs.toList();
              if (favs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizationService.getString('no_favorites_yet'))),
                );
                return;
              }
              final buffer = StringBuffer();
              buffer.writeln(localizationService.getString('share_favorites_title'));
              buffer.writeln();
              for (final key in favs) {
                try {
                  buffer.writeln('• ' + localizationService.getString(key));
                } catch (_) {
                  buffer.writeln('• ' + key);
                }
              }
              Share.share(buffer.toString());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.7),
          indicatorColor: scheme.primary,
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
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizationService.getString('support_blood_values_naturally'),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 16),
                
                // Search and filters
                _buildSearchAndFilters(localizationService, theme, scheme),
                const SizedBox(height: 16),
                if (isLoading) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(scheme.primary)),
                    ),
                  ),
                ] else ...[
                  // If any filter/search active, show filtered results only
                  if (_searchQuery.isNotEmpty || _selectedCategory != 'all' || _showOnlyFavorites) ...[
                    Builder(
                      builder: (context) {
                        final filteredEntries = _getFilteredHerbalSolutions();
                        if (filteredEntries.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                _fb(localizationService, 'no_results', 'No results'),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: filteredEntries
                              .map((entry) => _buildHerbalCard(entry.key, entry.value))
                              .toList(),
                        );
                      },
                    ),
                  ] else if (recommendedCategories.isNotEmpty) ...[
                    // Personalized header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: scheme.secondary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.recommend, color: scheme.secondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _fb(localizationService, 'personalized_recommendations', 'Personalized recommendations based on your last test'),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _fb(localizationService, 'recommended_for_you', 'Recommended for you'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
          ...recommendedCategories
            .where((k) => herbalSolutions.containsKey(k))
            .map((k) => _buildHerbalCard(k, herbalSolutions[k]!)),
                    const SizedBox(height: 12),
                    Divider(color: theme.dividerColor),
                    const SizedBox(height: 12),
                    Text(
                      _fb(localizationService, 'other_solutions', 'Other herbal supports'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
          ...herbalSolutions.entries
            .where((e) => !recommendedCategories.contains(e.key))
            .map((entry) => _buildHerbalCard(entry.key, entry.value)),
                  ] else ...[
                    // Fallback: show all
                    const SizedBox(height: 8),
                    ...herbalSolutions.entries.map((entry) => _buildHerbalCard(entry.key, entry.value)),
                  ],
                ],
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizationService.getString('traditional_treatments_subtitle'),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 24),
                
                ...traditionalMethods.map((method) => _buildTraditionalCard(method)),
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