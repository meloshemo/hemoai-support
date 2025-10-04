import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../services/preferences_service.dart';
import '../services/localization_service.dart';
import '../services/diet_program_service.dart';
import '../models/diet_program.dart';

class DietProgramScreen extends StatelessWidget {
  const DietProgramScreen({Key? key}) : super(key: key);

  Future<_DietData> _loadData() async {
    final prefs = await PreferencesService.getInstance();
    final user = prefs.getUserInfo();
    final int age = (user != null && user['age'] is int) ? (user['age'] as int) : 30;
    final Map<String, double>? lastValues = prefs.getLastHemogramValues();

    final service = DietProgramService();
    final programs = service.generate(values: lastValues ?? {});
    final ageGroupKey = service.ageGroupFor(age);

    return _DietData(
      age: age,
      ageGroupKey: ageGroupKey,
      programs: programs,
      hasMeasuredValues: lastValues != null && lastValues.isNotEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppDrawer(currentRoute: '/diet_program'),
      appBar: AppBar(
        title: Consumer<LocalizationService>(
          builder: (context, localization, child) => Text(localization.getString('personal_diet_program')),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE53E3E),
        elevation: 0,
      ),
      body: Consumer<LocalizationService>(
        builder: (context, localization, child) => FutureBuilder<_DietData>(
          future: _loadData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFE53E3E)));
            }
            if (!snapshot.hasData) {
              return Center(child: Text(localization.getString('no_data_available')));
            }
            final data = snapshot.data!;

            final ageGroupLabel = localization.getString(data.ageGroupKey);
            final suitabilityText = localization.getStringWithParams('suitable_for_age', {
              'age_group': ageGroupLabel,
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.restaurant_menu, size: 28, color: Color(0xFFE53E3E)),
                          const SizedBox(width: 8),
                          Text(
                            localization.getString('diet_recommendations_title'),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localization.getString('diet_program_description'),
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          avatar: const Icon(Icons.cake, size: 18, color: Colors.white),
                          label: Text(suitabilityText, style: const TextStyle(color: Colors.white)),
                          backgroundColor: const Color(0xFFE53E3E),
                        ),
                      ),
                      if (!data.hasMeasuredValues) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53E3E).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE53E3E).withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFFE53E3E)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  localization.getString('enter_hemogram_values'),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/hemogram_entry'),
                                child: Text(localization.getString('go_to_hemogram_entry')),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: data.programs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final DietProgram program = data.programs[index];
                      return _DietCard(program: program);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DietCard extends StatelessWidget {
  final DietProgram program;
  const _DietCard({required this.program});

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.getString(program.titleKey),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFE53E3E)),
            ),
            const SizedBox(height: 6),
            Text(
              localization.getString(program.descriptionKey),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            if (program.macrosKey != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.pie_chart_outline, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localization.getString(program.macrosKey!),
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localization.getString(program.includeKey),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.block, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localization.getString(program.limitKey),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            if (program.sampleMenuKey != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.menu_book, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localization.getString(program.sampleMenuKey!),
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DietData {
  final int age;
  final String ageGroupKey;
  final List<DietProgram> programs;
  final bool hasMeasuredValues;

  _DietData({
    required this.age,
    required this.ageGroupKey,
    required this.programs,
    required this.hasMeasuredValues,
  });
}
