import '../models/diet_program.dart';

class DietProgramService {
  // Determine age group from age in years
  String ageGroupFor(int age) {
    if (age < 13) return 'age_group_child';
    if (age < 18) return 'age_group_teen';
    if (age < 60) return 'age_group_adult';
    return 'age_group_senior';
  }

  // Generate diet programs suggestions from hemogram and basic flags
  List<DietProgram> generate({
    required Map<String, double> values,
  }) {
    final List<DietProgram> programs = [];

    // Helper: in-range check with basic ranges (align with AnalysisScreen defaults)
    bool below(String key, double min) => (values[key] != null) && values[key]! < min;
    bool above(String key, double max) => (values[key] != null) && values[key]! > max;
    bool outside(String key, double min, double max) => (values[key] != null) && (values[key]! < min || values[key]! > max);

    // Canonical ranges (simple thresholds; should match referenceRanges logic)
    const ref = {
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

    // Low hemoglobin
    if (below('hemoglobin', ref['hemoglobin']!['min'] as double)) {
      programs.add(DietProgram(
        titleKey: 'diet_low_hemoglobin_title',
        descriptionKey: 'diet_low_hemoglobin_desc',
        includeKey: 'diet_low_hemoglobin_include',
        limitKey: 'diet_low_hemoglobin_limit',
        riskTag: 'hemoglobin',
        macrosKey: 'diet_low_hemoglobin_macros',
        sampleMenuKey: 'diet_low_hemoglobin_menu',
      ));
    }

    // Low iron
    if (below('iron', ref['iron']!['min'] as double)) {
      programs.add(DietProgram(
        titleKey: 'diet_low_iron_title',
        descriptionKey: 'diet_low_iron_desc',
        includeKey: 'diet_low_iron_include',
        limitKey: 'diet_low_iron_limit',
        riskTag: 'iron',
        macrosKey: 'diet_low_iron_macros',
        sampleMenuKey: 'diet_low_iron_menu',
      ));
    }

    // High WBC
    if (above('white_blood_cells', ref['white_blood_cells']!['max'] as double)) {
      programs.add(DietProgram(
        titleKey: 'diet_high_wbc_title',
        descriptionKey: 'diet_high_wbc_desc',
        includeKey: 'diet_high_wbc_include',
        limitKey: 'diet_high_wbc_limit',
        riskTag: 'white_blood_cells',
        macrosKey: 'diet_high_wbc_macros',
        sampleMenuKey: 'diet_high_wbc_menu',
      ));
    }

    // High glucose
    if (above('glucose', ref['glucose']!['max'] as double)) {
      programs.add(DietProgram(
        titleKey: 'diet_glucose_control_title',
        descriptionKey: 'diet_glucose_control_desc',
        includeKey: 'diet_glucose_control_include',
        limitKey: 'diet_glucose_control_limit',
        riskTag: 'glucose',
        macrosKey: 'diet_glucose_control_macros',
        sampleMenuKey: 'diet_glucose_control_menu',
      ));
    }

    // Liver enzymes elevated (ALT/AST/GGT)
    if (above('alt', ref['alt']!['max'] as double) ||
        above('ast', ref['ast']!['max'] as double) ||
        above('ggt', ref['ggt']!['max'] as double)) {
      programs.add(DietProgram(
        titleKey: 'diet_liver_support_title',
        descriptionKey: 'diet_liver_support_desc',
        includeKey: 'diet_liver_support_include',
        limitKey: 'diet_liver_support_limit',
        riskTag: 'liver',
        macrosKey: 'diet_liver_support_macros',
        sampleMenuKey: 'diet_liver_support_menu',
      ));
    }

    // Bilirubin elevated
    if (above('total_bilirubin', ref['total_bilirubin']!['max'] as double) ||
        above('direct_bilirubin', ref['direct_bilirubin']!['max'] as double)) {
      programs.add(DietProgram(
        titleKey: 'diet_bilirubin_support_title',
        descriptionKey: 'diet_bilirubin_support_desc',
        includeKey: 'diet_bilirubin_support_include',
        limitKey: 'diet_bilirubin_support_limit',
        riskTag: 'bilirubin',
        macrosKey: 'diet_bilirubin_support_macros',
        sampleMenuKey: 'diet_bilirubin_support_menu',
      ));
    }

    // CRP elevated -> anti-inflammatory
    if (above('crp', ref['crp']!['max'] as double)) {
      programs.add(DietProgram(
        titleKey: 'diet_crp_antiinflam_title',
        descriptionKey: 'diet_crp_antiinflam_desc',
        includeKey: 'diet_crp_antiinflam_include',
        limitKey: 'diet_crp_antiinflam_limit',
        riskTag: 'crp',
        macrosKey: 'diet_crp_antiinflam_macros',
        sampleMenuKey: 'diet_crp_antiinflam_menu',
      ));
    }

    // Thyroid imbalance (TSH or Free T3/T4 outside)
    if (outside('tsh', ref['tsh']!['min'] as double, ref['tsh']!['max'] as double) ||
        outside('free_t3', ref['free_t3']!['min'] as double, ref['free_t3']!['max'] as double) ||
        outside('free_t4', ref['free_t4']!['min'] as double, ref['free_t4']!['max'] as double)) {
      programs.add(DietProgram(
        titleKey: 'diet_thyroid_support_title',
        descriptionKey: 'diet_thyroid_support_desc',
        includeKey: 'diet_thyroid_support_include',
        limitKey: 'diet_thyroid_support_limit',
        riskTag: 'thyroid',
        macrosKey: 'diet_thyroid_support_macros',
        sampleMenuKey: 'diet_thyroid_support_menu',
      ));
    }

    // Vitamin D low
    if (below('vitamin_d3', ref['vitamin_d3']!['min'] as double)) {
      programs.add(DietProgram(
        titleKey: 'diet_vitd_support_title',
        descriptionKey: 'diet_vitd_support_desc',
        includeKey: 'diet_vitd_support_include',
        limitKey: 'diet_vitd_support_limit',
        riskTag: 'vitamin_d3',
        macrosKey: 'diet_vitd_support_macros',
        sampleMenuKey: 'diet_vitd_support_menu',
      ));
    }

    // Vitamin B12 low
    if (below('vitamin_b12', ref['vitamin_b12']!['min'] as double)) {
      programs.add(DietProgram(
        titleKey: 'diet_b12_support_title',
        descriptionKey: 'diet_b12_support_desc',
        includeKey: 'diet_b12_support_include',
        limitKey: 'diet_b12_support_limit',
        riskTag: 'vitamin_b12',
        macrosKey: 'diet_b12_support_macros',
        sampleMenuKey: 'diet_b12_support_menu',
      ));
    }

    // Electrolyte imbalance
    if (outside('sodium', ref['sodium']!['min'] as double, ref['sodium']!['max'] as double) ||
        outside('potassium', ref['potassium']!['min'] as double, ref['potassium']!['max'] as double) ||
        outside('chloride', ref['chloride']!['min'] as double, ref['chloride']!['max'] as double)) {
      programs.add(DietProgram(
        titleKey: 'diet_electrolyte_balance_title',
        descriptionKey: 'diet_electrolyte_balance_desc',
        includeKey: 'diet_electrolyte_balance_include',
        limitKey: 'diet_electrolyte_balance_limit',
        riskTag: 'electrolytes',
        macrosKey: 'diet_electrolyte_balance_macros',
        sampleMenuKey: 'diet_electrolyte_balance_menu',
      ));
    }

    // Calcium low
    if (below('calcium', ref['calcium']!['min'] as double)) {
      programs.add(DietProgram(
        titleKey: 'diet_calcium_support_title',
        descriptionKey: 'diet_calcium_support_desc',
        includeKey: 'diet_calcium_support_include',
        limitKey: 'diet_calcium_support_limit',
        riskTag: 'calcium',
        macrosKey: 'diet_calcium_support_macros',
        sampleMenuKey: 'diet_calcium_support_menu',
      ));
    }

    // If nothing triggered, provide a general balanced program based on normal status
    if (programs.isEmpty) {
      programs.add(DietProgram(
        titleKey: 'diet_balanced_title',
        descriptionKey: 'diet_balanced_desc',
        includeKey: 'diet_balanced_include',
        limitKey: 'diet_balanced_limit',
        riskTag: 'general',
        macrosKey: 'diet_balanced_macros',
        sampleMenuKey: 'diet_balanced_menu',
      ));
    }

    return programs;
  }
}
