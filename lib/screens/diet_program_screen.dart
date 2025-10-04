import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/localization_service.dart';
import '../widgets/app_drawer.dart';
import '../services/diet_program_service.dart';
import '../services/diet_menu_service.dart';
import '../utils/responsive_helper.dart';

class DietProgramScreen extends StatelessWidget {
  const DietProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    final dietService = DietProgramService();
    final menuService = DietMenuService();

    // For demo: minimal example values; in future wire to actual latest hemogram
    final exampleValues = {
      'hemoglobin': 11.2, // low -> triggers hemoglobin program
      'iron': 55.0, // low -> triggers iron program
      'white_blood_cells': 6.5,
    };

    final programs = dietService.generate(values: exampleValues);

    final canPop = Navigator.of(context).canPop();
    final screenPadding = ResponsiveHelper.getScreenPadding(context);
    return Scaffold(
      drawer: canPop ? null : const AppDrawer(currentRoute: '/diet_program'),
      appBar: AppBar(
        leading: canPop
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop())
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        title: Text(loc.getString('personal_diet_program')),
      ),
      body: SingleChildScrollView(
        padding: screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst bilgilendirme ve hızlı aksiyonlar
            _headerActions(context, loc, programs.isNotEmpty ? programs.first.riskTag : 'general', menuService),
            SizedBox(height: ResponsiveHelper.responsiveValue(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),

            // Program kartları
            ...List.generate(programs.length, (index) {
              final p = programs[index];
              final includeLines = loc.getString(p.includeKey).split('\n');
              final limitLines = loc.getString(p.limitKey).split('\n');
              final menu = menuService.buildMenu(riskTag: p.riskTag, dayIndex: DateTime.now().weekday % 7);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.getString(p.titleKey), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(loc.getString(p.descriptionKey)),
                        const SizedBox(height: 12),
                        Text(loc.getString('include_colon'), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 6),
                        ...includeLines.map((line) => _bullet(line)),
                        const SizedBox(height: 12),
                        Text(loc.getString('limit_colon'), style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(height: 6),
                        ...limitLines.map((line) => _bullet(line)),
                        const Divider(height: 24),
                        Text(loc.getString('daily_menu_heading'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _menuSection(context, loc.getString('breakfast_label'), menu['breakfast']!, loc),
                        _menuSection(context, loc.getString('lunch_label'), menu['lunch']!, loc),
                        _menuSection(context, loc.getString('snack_label'), menu['snack']!, loc),
                        _menuSection(context, loc.getString('dinner_label'), menu['dinner']!, loc),
                        const SizedBox(height: 8),
                        Text(loc.getString('hydration_tip'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.tertiary)),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Haftalık Özet (başlıca risk etiketiyle)
            if (programs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(loc.getString('weekly_overview'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              ...List.generate(7, (i) {
                final menu = menuService.buildMenu(riskTag: programs.first.riskTag, dayIndex: i);
                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                  title: Text('Gün ${i + 1}', style: Theme.of(context).textTheme.titleSmall),
                  children: [
                    _menuSection(context, loc.getString('breakfast_label'), menu['breakfast']!, loc, compact: true),
                    _menuSection(context, loc.getString('lunch_label'), menu['lunch']!, loc, compact: true),
                    _menuSection(context, loc.getString('snack_label'), menu['snack']!, loc, compact: true),
                    _menuSection(context, loc.getString('dinner_label'), menu['dinner']!, loc, compact: true),
                  ],
                );
              })
            ],
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _menuSection(BuildContext context, String title, List<String> itemKeys, LocalizationService loc, {bool compact = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ...itemKeys.map((k) => GestureDetector(
                onTap: () => _showAlternatives(context, k, loc),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: compact ? 2 : 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: Text(loc.getString(k))),
                            const SizedBox(width: 6),
                            Icon(Icons.swap_horiz, size: 14, color: Theme.of(context).colorScheme.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // Eylemler: Bugünkü menüyü kopyala ve ipucu
  Widget _headerActions(BuildContext context, LocalizationService loc, String riskTag, DietMenuService menuService) {
    final menu = menuService.buildMenu(riskTag: riskTag, dayIndex: DateTime.now().weekday % 7);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: Text(loc.getString('copy_todays_menu')),
                    onPressed: () async {
                      final text = _formatMenuForCopy(loc, menu);
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.getString('menu_copied'))),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: loc.getString('smart_substitutions'),
                  child: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatMenuForCopy(LocalizationService loc, Map<String, List<String>> menu) {
    final b = StringBuffer();
    void add(String labelKey, String slot) {
      b.writeln('${loc.getString(labelKey)}:');
      for (final k in menu[slot] ?? const <String>[]) {
        b.writeln('- ${loc.getString(k)}');
      }
      b.writeln();
    }
    add('breakfast_label', 'breakfast');
    add('lunch_label', 'lunch');
    add('snack_label', 'snack');
    add('dinner_label', 'dinner');
    return b.toString().trim();
  }

  void _showAlternatives(BuildContext context, String itemKey, LocalizationService loc) {
    // Bilinen bazı öğe -> alternatif listesi anahtarları
    const Map<String, String> subsMap = {
      'diet_item_oatmeal_molasses': 'diet_subs_oatmeal_molasses',
      'diet_item_boiled_egg': 'diet_subs_boiled_egg',
      'diet_item_chicken_or_legumes': 'diet_subs_chicken_or_legumes',
    };
    final subsKey = subsMap[itemKey];
    if (subsKey == null) return;

    final title = loc.getStringWithParams('alternatives_for', {'item': loc.getString(itemKey)});
    final lines = loc.getString(subsKey).split('\n');
    if (lines.isEmpty || (lines.length == 1 && lines.first.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.getString('no_alternatives_available'))),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('• $e'),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.getString('ok')),
          ),
        ],
      ),
    );
  }
}
