import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

class RecentTestsCard extends ConsumerWidget {
  const RecentTestsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Mock recent tests data - in real app, this would come from providers
    final recentTests = [
      RecentTest(
        testType: 'Complete Blood Count',
        date: DateTime.now().subtract(const Duration(days: 3)),
        status: 'completed',
        results: 'Normal',
        criticalValues: 0,
      ),
      RecentTest(
        testType: 'Lipid Profile',
        date: DateTime.now().subtract(const Duration(days: 7)),
        status: 'completed',
        results: 'Good',
        criticalValues: 0,
      ),
      RecentTest(
        testType: 'Liver Function Test',
        date: DateTime.now().subtract(const Duration(days: 14)),
        status: 'completed',
        results: 'Normal',
        criticalValues: 0,
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
                  'Recent Tests',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to all tests
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
              itemCount: recentTests.length,
              separatorBuilder: (context, index) => Divider(
                color: colorScheme.outlineVariant,
                height: 16,
              ),
              itemBuilder: (context, index) {
                final test = recentTests[index];
                return _RecentTestTile(test: test);
              },
            ),
            
            const SizedBox(height: 8),
            
            // Add Test Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to add test
                },
                icon: const Icon(Icons.add),
                label: const Text('Add New Test'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTestTile extends StatelessWidget {
  final RecentTest test;

  const _RecentTestTile({required this.test});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        // Navigate to test details
      },
      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getStatusColor(test.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            
            // Test info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.testType,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _formatDate(test.date),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getResultsColor(test.results).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          test.results,
                          style: TextStyle(
                            color: _getResultsColor(test.results),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Critical values indicator
            if (test.criticalValues > 0)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.healthCritical.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber,
                  color: AppTheme.healthCritical,
                  size: 16,
                ),
              ),
            
            // Arrow icon
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.healthGood;
      case 'pending':
        return AppTheme.healthWarning;
      case 'cancelled':
        return AppTheme.healthCritical;
      default:
        return Colors.grey;
    }
  }

  Color _getResultsColor(String results) {
    switch (results.toLowerCase()) {
      case 'normal':
      case 'good':
        return AppTheme.healthGood;
      case 'abnormal':
      case 'warning':
        return AppTheme.healthWarning;
      case 'critical':
        return AppTheme.healthCritical;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class RecentTest {
  final String testType;
  final DateTime date;
  final String status;
  final String results;
  final int criticalValues;

  const RecentTest({
    required this.testType,
    required this.date,
    required this.status,
    required this.results,
    required this.criticalValues,
  });
}
