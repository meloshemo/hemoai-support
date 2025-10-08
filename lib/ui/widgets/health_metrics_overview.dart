import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

class HealthMetricsOverview extends ConsumerWidget {
  const HealthMetricsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Mock health metrics - in real app, this would come from providers
    final metrics = [
      HealthMetric(
        name: 'Hemoglobin',
        value: '14.2',
        unit: 'g/dL',
        status: 'normal',
        trend: 'stable',
      ),
      HealthMetric(
        name: 'Cholesterol',
        value: '185',
        unit: 'mg/dL',
        status: 'normal',
        trend: 'improving',
      ),
      HealthMetric(
        name: 'Blood Pressure',
        value: '120/80',
        unit: 'mmHg',
        status: 'normal',
        trend: 'stable',
      ),
      HealthMetric(
        name: 'Heart Rate',
        value: '72',
        unit: 'bpm',
        status: 'normal',
        trend: 'stable',
      ),
    ];

    return Card(
      elevation: AppTheme.lowElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Health Metrics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to detailed metrics
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: metrics.length,
              separatorBuilder: (context, index) => Divider(
                color: colorScheme.outlineVariant,
                height: 24,
              ),
              itemBuilder: (context, index) {
                final metric = metrics[index];
                return _HealthMetricTile(metric: metric);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthMetricTile extends StatelessWidget {
  final HealthMetric metric;

  const _HealthMetricTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Status indicator
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getStatusColor(metric.status),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        
        // Metric info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '${metric.value} ${metric.unit}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildTrendIndicator(metric.trend),
                ],
              ),
            ],
          ),
        ),
        
        // Trend icon
        Icon(
          _getTrendIcon(metric.trend),
          color: _getTrendColor(metric.trend),
          size: 20,
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(String trend) {
    Color color = _getTrendColor(trend);
    String text = _getTrendText(trend);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'normal':
        return AppTheme.healthGood;
      case 'warning':
        return AppTheme.healthWarning;
      case 'critical':
        return AppTheme.healthCritical;
      default:
        return Colors.grey;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return AppTheme.healthGood;
      case 'declining':
        return AppTheme.healthCritical;
      case 'stable':
        return AppTheme.healthInfo;
      default:
        return Colors.grey;
    }
  }

  String _getTrendText(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return '↗';
      case 'declining':
        return '↘';
      case 'stable':
        return '→';
      default:
        return '?';
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      case 'stable':
        return Icons.trending_flat;
      default:
        return Icons.help_outline;
    }
  }
}

class HealthMetric {
  final String name;
  final String value;
  final String unit;
  final String status;
  final String trend;

  const HealthMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.status,
    required this.trend,
  });
}
