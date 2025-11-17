import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/preferences_service.dart';
import '../services/database_helper.dart';
import '../utils/validators.dart';
import 'package:intl/intl.dart';

class HemogramEntryScreen extends StatefulWidget {
  const HemogramEntryScreen({super.key});

  @override
  State<HemogramEntryScreen> createState() => _HemogramEntryScreenState();
}

class _HemogramEntryScreenState extends State<HemogramEntryScreen> {
  int? _familyMemberId;
  String? _familyMemberName;
  
  // Popular markers (20) controllers
  final Map<String, TextEditingController> controllers = {
    'hemoglobin': TextEditingController(),
    'glucose': TextEditingController(),
    'calcium': TextEditingController(),
    'sodium': TextEditingController(),
    'potassium': TextEditingController(),
    'chloride': TextEditingController(),
    'alt': TextEditingController(),
    'ast': TextEditingController(),
    'ggt': TextEditingController(),
    'total_bilirubin': TextEditingController(),
    'direct_bilirubin': TextEditingController(),
    'crp': TextEditingController(),
    'iron': TextEditingController(),
    'uibc': TextEditingController(),
    'tibc': TextEditingController(),
    'tsh': TextEditingController(),
    'free_t3': TextEditingController(),
    'free_t4': TextEditingController(),
    'vitamin_d3': TextEditingController(),
    'vitamin_b12': TextEditingController(),
  };

  final Map<String, List<double>> referenceRanges = {
    'hemoglobin': [12, 17], // g/dL
    'glucose': [70, 100], // mg/dL (açlık)
    'calcium': [8.6, 10.2], // mg/dL
    'sodium': [135, 145], // mmol/L
    'potassium': [3.5, 5.1], // mmol/L
    'chloride': [98, 107], // mmol/L
    'alt': [7, 56], // U/L
    'ast': [10, 40], // U/L
    'ggt': [9, 48], // U/L
    'total_bilirubin': [0.1, 1.2], // mg/dL
    'direct_bilirubin': [0.0, 0.3], // mg/dL
    'crp': [0, 5], // mg/L
    'iron': [60, 170], // µg/dL
    'uibc': [110, 370], // µg/dL
    'tibc': [240, 450], // µg/dL
    'tsh': [0.4, 4.0], // µIU/mL
    'free_t3': [2.0, 4.4], // pg/mL
    'free_t4': [0.8, 1.8], // ng/dL
    'vitamin_d3': [20, 50], // ng/mL
    'vitamin_b12': [200, 900], // pg/mL
  };

  DateTime? _selectedDate;
  bool _isLoading = true;

  // Parameter categories for organized display
  Map<String, List<String>> get _parameterCategories => {
    'hemogram_basic': ['hemoglobin'],
    'glucose_metabolism': ['glucose'],
    'electrolytes': ['sodium', 'potassium', 'chloride', 'calcium'],
    'liver_function': ['alt', 'ast', 'ggt', 'total_bilirubin', 'direct_bilirubin'],
    'inflammation': ['crp'],
    'iron_studies': ['iron', 'uibc', 'tibc'],
    'thyroid_function': ['tsh', 'free_t3', 'free_t4'],
    'vitamins': ['vitamin_d3', 'vitamin_b12'],
  };

  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _hydrateExistingValues();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if this is for a family member - must be done here, not in initState
    if (!_hasInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _familyMemberId = args['family_member_id'] as int?;
        _familyMemberName = args['family_member_name'] as String?;
      }
      _hasInitialized = true;
    }
  }

  Future<void> _showHemogramHistory(BuildContext context, LocalizationService loc) async {
    final prefs = await PreferencesService.getInstance();
    final userId = await prefs.getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.getString('login_required'))),
      );
      return;
    }

    final db = DatabaseHelper.instance;
    final tests = await db.getHemogramTests(_familyMemberId ?? userId);
    
    if (!context.mounted) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      loc.getString('hemogram_history', defaultValue: 'Hemogram History'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              loc.getString('no_hemogram_history', defaultValue: 'No hemogram history found'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: tests.length,
                        itemBuilder: (context, index) {
                          final test = tests[index];
                          final testDate = DateTime.tryParse(test['test_date'] as String? ?? '');
                          final dateStr = testDate != null
                              ? DateFormat.yMMMd(loc.currentLanguageCode).format(testDate)
                              : loc.getString('unknown_date', defaultValue: 'Unknown date');
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Icon(
                                  Icons.bloodtype,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(
                                dateStr,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                _getTestSummary(test, loc),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _loadTestIntoForm(test);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTestSummary(Map<String, dynamic> test, LocalizationService loc) {
    final values = <String>[];
    if (test['hemoglobin'] != null) {
      values.add('${loc.getString('hemoglobin')}: ${test['hemoglobin']}');
    }
    if (test['glucose'] != null) {
      values.add('${loc.getString('glucose')}: ${test['glucose']}');
    }
    if (test['iron'] != null) {
      values.add('${loc.getString('iron')}: ${test['iron']}');
    }
    if (values.isEmpty) {
      return loc.getString('no_values_available', defaultValue: 'No values available');
    }
    return values.take(3).join(', ');
  }

  void _loadTestIntoForm(Map<String, dynamic> test) {
    // Load test date
    final testDate = DateTime.tryParse(test['test_date'] as String? ?? '');
    if (testDate != null) {
      setState(() {
        _selectedDate = testDate;
      });
    }

    // Load values into controllers
    final valueKeys = [
      'hemoglobin', 'glucose', 'calcium', 'sodium', 'potassium', 'chloride',
      'alt', 'ast', 'ggt', 'total_bilirubin', 'direct_bilirubin',
      'crp', 'iron', 'uibc', 'tibc', 'tsh', 'free_t3', 'free_t4',
      'vitamin_d3', 'vitamin_b12',
    ];

    for (final key in valueKeys) {
      final controller = controllers[key];
      if (controller != null) {
        final value = test[key];
        if (value != null) {
          final numValue = value is num ? value : double.tryParse(value.toString());
          if (numValue != null) {
            controller.text = numValue.toStringAsFixed(
              numValue.truncateToDouble() == numValue ? 0 : 2,
            );
          }
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Provider.of<LocalizationService>(context, listen: false)
              .getString('test_loaded', defaultValue: 'Test loaded into form')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _hydrateExistingValues() async {
    final prefs = await PreferencesService.getInstance();
    Map<String, double>? values = prefs.getLastHemogramValues();
    if (values == null || values.isEmpty) {
      values = await prefs.loadActiveHemogramValues();
    }
    DateTime? lastDate;
    final dateStr = prefs.getLastHemogramDate();
    if (dateStr != null && dateStr.isNotEmpty) {
      lastDate = DateTime.tryParse(dateStr);
    }
    if (!mounted) return;
    if (values != null && values.isNotEmpty) {
      final existing = values;
      controllers.forEach((key, controller) {
        final v = existing[key];
        if (v != null) {
          controller.text = v.toStringAsFixed(
            v.truncateToDouble() == v ? 0 : 2,
          );
        }
      });
    }
    setState(() {
      _selectedDate = lastDate;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    for (final controller in controllers.values) {
      controller.dispose();
    }
    controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_familyMemberName != null 
              ? '${loc.getString('hemogram_entry')} - $_familyMemberName'
              : loc.getString('hemogram_entry')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_familyMemberName != null 
            ? '${loc.getString('hemogram_entry')} - $_familyMemberName'
            : loc.getString('hemogram_entry')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: loc.getString('view_hemogram_history', defaultValue: 'View Hemogram History'),
            onPressed: () => _showHemogramHistory(context, loc),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: loc.getString('new_hemogram', defaultValue: 'New Hemogram'),
            onPressed: () {
              setState(() {
                controllers.forEach((key, controller) {
                  controller.clear();
                });
                _selectedDate = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.getString('ready_for_new_hemogram', defaultValue: 'Ready for new hemogram entry')),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StatefulBuilder(
          builder: (context, setState) {
            final materialLoc = MaterialLocalizations.of(context);
            return ListView(
              children: [
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(loc.getString('test_date')),
                    subtitle: Text(
                      _selectedDate != null
                          ? materialLoc.formatFullDate(_selectedDate!)
                          : loc.getString('select_date_hint',
                              defaultValue: loc.getString('select')),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final initial = _selectedDate ?? now;
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initial,
                          firstDate: DateTime(now.year - 10),
                          lastDate: now.add(const Duration(days: 1)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Text(loc.getString('edit')),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(loc.getString('ocr_desktop_placeholder'))),
                    );
                  },
                  icon: Icon(Icons.camera_alt),
                  label: Text(loc.getString('scan_document')),
                ),
                SizedBox(height: 16),
                // Categorized parameters for better organization
                ..._buildCategorizedParameters(loc, setState),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final Map<String, double> values = {};
                    controllers.forEach((key, ctrl) {
                      final t = ctrl.text.trim();
                      if (t.isNotEmpty) {
                        final v = double.tryParse(t.replaceAll(',', '.'));
                        if (v != null) values[key] = v;
                      }
                    });
                    if (values.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            loc.getString(
                              'enter_hemogram_values',
                            ),
                          ),
                        ),
                      );
                      return;
                    }
                    
                    // Save hemogram values
                    final navigator = Navigator.of(context);
                    final prefs = await PreferencesService.getInstance();
                    final testDate = _selectedDate ?? DateTime.now();
                    
                    // If this is for a family member, save to database
                    if (_familyMemberId != null) {
                      final db = DatabaseHelper.instance;
                      final testData = <String, dynamic>{
                        'user_id': _familyMemberId,
                        'test_date': testDate.toIso8601String().split('T')[0],
                        'values_json': jsonEncode(values),
                        'status': 'active',
                        'created_at': DateTime.now().toIso8601String(),
                      };
                      
                      // Map values to database columns
                      values.forEach((key, value) {
                        // Map common keys to database column names
                        final dbKey = _mapToDbColumn(key);
                        if (dbKey != null) {
                          testData[dbKey] = value;
                        }
                      });
                      
                      await db.insertHemogramTest(testData);
                      
                      if (!mounted) return;
                      navigator.pop(true); // Return success
                    } else {
                      // Regular user flow
                      await prefs.saveHemogramValues(
                        values,
                        testDate: testDate,
                      );
                      
                      if (!mounted) return;
                      navigator.pushNamed(
                        '/analysis',
                        arguments: {
                          'values': values,
                          'testDate': _selectedDate,
                        },
                      );
                    }
                  },
                  child: Text(loc.getString('analysis')),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildCategorizedParameters(LocalizationService loc, StateSetter setState) {
    final widgets = <Widget>[];
    
    _parameterCategories.forEach((categoryKey, params) {
      // Filter to only include parameters that exist in controllers
      final validParams = params.where((p) => controllers.containsKey(p)).toList();
      if (validParams.isEmpty) return;
      
      widgets.add(
        Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(categoryKey),
                      color: const Color(0xFFE53E3E),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loc.getString(categoryKey),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE53E3E),
                      ),
                    ),
                  ],
                ),
              ),
              // Parameters in this category
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: validParams.map((param) {
                    final textValue = controllers[param]!.text.trim();
                    final low = referenceRanges[param]![0];
                    final high = referenceRanges[param]![1];
                    final helper =
                        '${loc.getString('reference_range')}: ${low.toStringAsFixed(low == low.truncateToDouble() ? 0 : 1)} - ${high.toStringAsFixed(high == high.truncateToDouble() ? 0 : 1)}';
                    
                    // Check if value is in range for visual feedback
                    Color? borderColor;
                    if (textValue.isNotEmpty) {
                      final value = double.tryParse(textValue.replaceAll(',', '.'));
                      if (value != null) {
                        if (value < low || value > high) {
                          borderColor = Colors.orange;
                        } else {
                          borderColor = Colors.green;
                        }
                      }
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controllers[param],
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: loc.getString(param),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                              borderSide: borderColor != null
                                ? BorderSide(color: borderColor, width: 2)
                                : const BorderSide(),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: borderColor != null
                                ? BorderSide(color: borderColor, width: 2)
                                : const BorderSide(),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: borderColor ?? const Color(0xFFE53E3E),
                              width: 2,
                            ),
                          ),
                          helperText: helper,
                          errorText: textValue.isNotEmpty
                              ? Validators.validateNumericRange(
                                  textValue,
                                  min: referenceRanges[param]![0] * 0.5,
                                  max: referenceRanges[param]![1] * 2.0,
                                  fieldName: loc.getString(param),
                                )
                              : null,
                          suffixIcon: textValue.isNotEmpty && borderColor != null
                              ? Icon(
                                  borderColor == Colors.green
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color: borderColor,
                                  size: 20,
                                )
                              : null,
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    });
    
    return widgets;
  }

  String? _mapToDbColumn(String key) {
    // Map hemogram entry keys to database column names
    final mapping = {
      'hemoglobin': 'hemoglobin',
      'glucose': 'glucose',
      'calcium': 'calcium',
      'sodium': 'sodium',
      'potassium': 'potassium',
      'chloride': 'chloride',
      'alt': 'alt',
      'ast': 'ast',
      'ggt': 'ggt',
      'total_bilirubin': 'bilirubin',
      'direct_bilirubin': 'bilirubin', // Note: database may only have one bilirubin column
      'crp': 'crp',
      'iron': 'iron',
      'uibc': null, // Not in standard columns
      'tibc': null, // Not in standard columns
      'tsh': 'tsh',
      'free_t3': null, // May need to add
      'free_t4': null, // May need to add
      'vitamin_d3': 'vitamin_d3',
      'vitamin_b12': 'vitamin_b12',
    };
    return mapping[key];
  }

  IconData _getCategoryIcon(String categoryKey) {
    switch (categoryKey) {
      case 'hemogram_basic':
        return Icons.bloodtype;
      case 'glucose_metabolism':
        return Icons.monitor_heart;
      case 'electrolytes':
        return Icons.water_drop;
      case 'liver_function':
        return Icons.medical_services;
      case 'inflammation':
        return Icons.local_fire_department;
      case 'iron_studies':
        return Icons.iron;
      case 'thyroid_function':
        return Icons.health_and_safety;
      case 'vitamins':
        return Icons.medication;
      default:
        return Icons.science;
    }
  }
}
