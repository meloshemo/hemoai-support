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

    // Canonical ranges (simple thresholds; should match referenceRanges logic)
    const ref = {
      'hemoglobin': {'min': 12.0, 'max': 17.0},
      'iron': {'min': 60.0, 'max': 170.0},
      'white_blood_cells': {'min': 4.0, 'max': 11.0},
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
