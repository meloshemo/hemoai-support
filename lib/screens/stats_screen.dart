import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/database_helper.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // For demo: assume userId=1 when not available
    const userId = 1;
    try {
      final db = DatabaseHelper.instance;
      final s = await db.getUserStats(userId);
      if (mounted) setState(() { _stats = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _stats = {}; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text(loc.getString('stats_overview_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.getString('stats_overview_desc')),
                  const SizedBox(height: 12),
                  _MetricRow(label: loc.getString('stats_total_tests'), value: '${_stats?['total_tests'] ?? 0}'),
                  _MetricRow(label: loc.getString('stats_family_members'), value: '${_stats?['family_members'] ?? 0}'),
                  _MetricRow(label: loc.getString('stats_active_medications'), value: '${_stats?['active_medications'] ?? 0}'),
                  _MetricRow(label: loc.getString('stats_unread_notifications'), value: '${_stats?['unread_notifications'] ?? 0}'),
                  const Spacer(),
                  Text(loc.getString('privacy_local_analytics_note'), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
