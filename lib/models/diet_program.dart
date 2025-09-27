class DietProgram {
  final String titleKey;
  final String descriptionKey;
  final String includeKey; // bullet list content
  final String limitKey;   // bullet list content
  final String riskTag;    // e.g., hemoglobin, iron, immune, platelets, general
  final String? macrosKey;     // optional: macros breakdown key
  final String? sampleMenuKey; // optional: sample daily menu key

  DietProgram({
    required this.titleKey,
    required this.descriptionKey,
    required this.includeKey,
    required this.limitKey,
    required this.riskTag,
    this.macrosKey,
    this.sampleMenuKey,
  });
}
