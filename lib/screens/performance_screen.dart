import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../services/analytics_service.dart';
import '../utils/performance_optimizer.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  Map<String, dynamic> _cacheInfo = {};
  List<String> _recommendations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _loading = true);
    
    try {
      final cacheInfo = await _optimizer.getCacheInfo();
      final recommendations = await _optimizer.getPerformanceRecommendations();
      
      if (mounted) {
        setState(() {
          _cacheInfo = cacheInfo;
          _recommendations = recommendations;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        final loc = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getStringWithParams('error_loading_performance', {'error': e.toString()})),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _clearAllCaches() async {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.trackEvent('performance_cache_cleared');

    try {
      await _optimizer.clearAllCaches();
      await _loadPerformanceData(); // Refresh data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<LocalizationService>(context, listen: false)
                .getString('cache_cleared')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final loc = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getStringWithParams('error_clearing_caches', {'error': e.toString()})),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _applyRecommendedSettings() async {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.trackEvent('performance_recommended_settings_applied');

    try {
      await _optimizer.applyRecommendedSettings();
      await _loadPerformanceData(); // Refresh data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<LocalizationService>(context, listen: false)
                .getString('performance_optimized')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final loc = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.getStringWithParams('error_applying_settings', {'error': e.toString()})),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    return Consumer<LocalizationService>(
      builder: (context, loc, _) => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(loc.getString('performance_settings')),
          backgroundColor: theme.appBarTheme.backgroundColor ?? scheme.surface,
          foregroundColor: theme.appBarTheme.foregroundColor ?? scheme.onSurface,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadPerformanceData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Performance Controls Section
                    _buildPerformanceControlsCard(scheme, loc),
                    const SizedBox(height: 16),
                    
                    // Cache Information Section
                    _buildCacheInfoCard(scheme, loc),
                    const SizedBox(height: 16),
                    
                    // Recommendations Section
                    _buildRecommendationsCard(scheme, loc),
                    const SizedBox(height: 16),
                    
                    // Debug Information (only in debug mode)
                    if (kDebugMode) _buildDebugInfoCard(scheme, loc),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPerformanceControlsCard(ColorScheme scheme, LocalizationService loc) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.getString('performance_settings'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Animation Settings
            FutureBuilder<bool>(
              future: _optimizer.areAnimationsEnabled(),
              builder: (context, snapshot) {
                final enabled = snapshot.data ?? true;
                return SwitchListTile(
                  secondary: Icon(Icons.animation, color: scheme.primary),
                  title: Text(loc.getString('enable_animations')),
                  subtitle: Text(enabled ? loc.getString('animations_enabled') : loc.getString('animations_disabled')),
                  value: enabled,
                  onChanged: (value) async {
                    await _optimizer.setAnimationsEnabled(value);
                    setState(() {});
                  },
                );
              },
            ),
            
            // Motion Reduction Settings
            FutureBuilder<bool>(
              future: _optimizer.shouldReduceMotion(),
              builder: (context, snapshot) {
                final reduce = snapshot.data ?? false;
                return SwitchListTile(
                  secondary: Icon(Icons.accessibility, color: scheme.primary),
                  title: Text(loc.getString('reduce_motion')),
                  subtitle: Text(reduce ? loc.getString('motion_reduced_accessibility') : loc.getString('motion_normal')),
                  value: reduce,
                  onChanged: (value) async {
                    await _optimizer.setReduceMotion(value);
                    setState(() {});
                  },
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearAllCaches,
                    icon: const Icon(Icons.cleaning_services),
                    label: Text(loc.getString('clear_cache')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _applyRecommendedSettings,
                    icon: const Icon(Icons.speed),
                    label: Text(loc.getString('apply_recommended_settings')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheInfoCard(ColorScheme scheme, LocalizationService loc) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.getString('cache_info'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_cacheInfo.isNotEmpty) ...[
              _buildInfoRow(loc.getString('image_cache'), '${_cacheInfo['imageCacheCount'] ?? 0} ${loc.getString('items')}'),
              _buildInfoRow(loc.getString('max_image_cache'), '${_cacheInfo['imageCacheMaxSize'] ?? 0} ${loc.getString('items')}'),
              _buildInfoRow(loc.getString('hemoai_cache'), '${_cacheInfo['hemoaiCacheSize'] ?? 0} ${loc.getString('entries')}'),
              if (_cacheInfo['timestamp'] != null)
                _buildInfoRow(loc.getString('last_updated'), 
                  DateTime.parse(_cacheInfo['timestamp']).toLocal().toString().split('.')[0]),
            ] else
              Text(
                loc.getString('no_cache_information_available'),
                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(ColorScheme scheme, LocalizationService loc) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.getString('performance_recommendations'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_recommendations.isNotEmpty)
              ..._recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, color: scheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: TextStyle(color: scheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ))
            else
              Text(
                loc.getString('no_recommendations_available'),
                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugInfoCard(ColorScheme scheme, LocalizationService loc) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bug_report, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  loc.getString('debug_information'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(loc.getString('platform'), kIsWeb ? loc.getString('is_web') : loc.getString('native')),
            _buildInfoRow(loc.getString('debug_mode'), kDebugMode.toString()),
            _buildInfoRow(loc.getString('profile_mode'), kProfileMode.toString()),
            _buildInfoRow(loc.getString('release_mode'), kReleaseMode.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}