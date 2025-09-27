import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/localization_service.dart';
import '../services/web_database_helper.dart';
import '../services/preferences_service.dart';
import '../widgets/app_drawer.dart';
import '../utils/responsive_helper.dart';

class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdvancedAnalyticsScreen> createState() => _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late final WebDatabaseHelper _dbHelper;
  PreferencesService? _prefsService;
  
  List<Map<String, dynamic>> _hemogramTests = [];
  Map<String, dynamic>? _latestTest;
  bool _isLoading = true;
  
  // Health score calculation
  double _healthScore = 0.0;
  String _healthGrade = 'A';
  Color _healthColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _dbHelper = WebDatabaseHelper.instance;
    _initServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initServices() async {
    _prefsService = await PreferencesService.getInstance();
    await _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      int? userId = _prefsService?.getCurrentUserId();
      if (userId != null) {
        // Get all hemogram tests
        _hemogramTests = await _dbHelper.getHemogramTests(userId);
        
        // Get latest test
        if (_hemogramTests.isNotEmpty) {
          _latestTest = _hemogramTests.first;
          _calculateHealthScore();
        }
      }
    } catch (e) {
      print('Error loading analytics data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateHealthScore() {
    if (_latestTest == null) return;
    
    // Simple health score calculation based on normal ranges
    double score = 100.0;
    int abnormalCount = 0;
    
    // Check each parameter
    Map<String, List<double>> normalRanges = {
      'hemoglobin': [12.0, 17.0],
      'iron': [60.0, 170.0],
      'white_blood_cells': [4.0, 10.0],
      'platelets': [150.0, 400.0],
      'hematocrit': [38.0, 50.0],
    };
    
    normalRanges.forEach((key, range) {
      double? value = _latestTest![key]?.toDouble();
      if (value != null) {
        if (value < range[0] || value > range[1]) {
          abnormalCount++;
          score -= 15.0; // Decrease score for each abnormal value
        }
      }
    });
    
    // Ensure score doesn't go below 0
    _healthScore = score.clamp(0.0, 100.0);
    
    // Determine grade and color
    if (_healthScore >= 85) {
      _healthGrade = 'A';
      _healthColor = Colors.green;
    } else if (_healthScore >= 70) {
      _healthGrade = 'B';
      _healthColor = Colors.lightGreen;
    } else if (_healthScore >= 55) {
      _healthGrade = 'C';
      _healthColor = Colors.orange;
    } else if (_healthScore >= 40) {
      _healthGrade = 'D';
      _healthColor = Colors.deepOrange;
    } else {
      _healthGrade = 'F';
      _healthColor = Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localizationService, child) {
        return Directionality(
          textDirection: localizationService.textDirection,
          child: Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF0D1117) 
              : Colors.grey[50],
            drawer: const AppDrawer(currentRoute: '/advanced_analytics'),
            appBar: AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFFF0F6FC) 
                      : Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: localizationService.getString('menu'),
                ),
              ),
              title: Text(
                localizationService.getString('advanced_analytics'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF161B22) 
                : const Color(0xFFE53E3E),
              elevation: 0,
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.dashboard),
                    text: localizationService.getString('overview'),
                  ),
                  Tab(
                    icon: const Icon(Icons.trending_up),
                    text: localizationService.getString('trends'),
                  ),
                  Tab(
                    icon: const Icon(Icons.compare_arrows),
                    text: localizationService.getString('compare'),
                  ),
                  Tab(
                    icon: const Icon(Icons.psychology),
                    text: localizationService.getString('insights'),
                  ),
                ],
              ),
            ),
            body: _isLoading 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53E3E)),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizationService.getString('loading'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(localizationService),
                    _buildTrendsTab(localizationService),
                    _buildCompareTab(localizationService),
                    _buildInsightsTab(localizationService),
                  ],
                ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(LocalizationService localizationService) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Score Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_healthColor, _healthColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _healthColor.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  localizationService.getString('health_score'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _healthScore.toInt().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        '/100',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _healthGrade,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _getHealthScoreDescription(localizationService),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Stats Grid
          Text(
            localizationService.getString('quick_stats'),
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE53E3E),
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: ResponsiveHelper.responsiveValue(
              context,
              mobile: 2,
              tablet: 3,
              desktop: 4,
            ),
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                localizationService.getString('total_tests'),
                _hemogramTests.length.toString(),
                Icons.assignment,
                Colors.blue,
              ),
              _buildStatCard(
                localizationService.getString('last_test'),
                _getLastTestDate(),
                Icons.schedule,
                Colors.green,
              ),
              _buildStatCard(
                localizationService.getString('risk_level'),
                _latestTest?['risk_level'] ?? localizationService.getString('no_data'),
                Icons.warning,
                _getRiskColor(_latestTest?['risk_level']),
              ),
              _buildStatCard(
                localizationService.getString('trend'),
                _getTrendDirection(),
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Latest Test Results
          if (_latestTest != null) ...[
            Text(
              localizationService.getString('latest_test_results'),
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context, 20),
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE53E3E),
              ),
            ),
            const SizedBox(height: 16),
            _buildLatestResultsCard(localizationService),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF21262D)
          : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestResultsCard(LocalizationService localizationService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF21262D)
          : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_turned_in,
                color: const Color(0xFFE53E3E),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                localizationService.getString('test_date'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _formatTestDate(_latestTest!['test_date']),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Key parameters
          ..._getKeyParameters().map((param) {
            double? value = _latestTest![param['key']]?.toDouble();
            List<double> normalRange = param['range'];
            String status = _getParameterStatus(value, normalRange, localizationService);
            Color statusColor = _getParameterStatusColor(value, normalRange);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      localizationService.getString(param['key']),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value != null ? '${value.toStringAsFixed(1)} ${param['unit']}' : '-',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(LocalizationService localizationService) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizationService.getString('hemoglobin_trend'),
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE53E3E),
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendChart('hemoglobin', localizationService),
          
          const SizedBox(height: 32),
          
          Text(
            localizationService.getString('iron_trend'),
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE53E3E),
            ),
          ),
          const SizedBox(height: 16),
          _buildTrendChart('iron', localizationService),
        ],
      ),
    );
  }

  Widget _buildTrendChart(String parameter, LocalizationService localizationService) {
    List<FlSpot> spots = [];
    
    // Get data points for the parameter
    for (int i = 0; i < _hemogramTests.length && i < 10; i++) {
      var test = _hemogramTests[_hemogramTests.length - 1 - i];
      double? value = test[parameter]?.toDouble();
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }
    
    if (spots.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF21262D)
            : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            localizationService.getString('no_data_for_chart'),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF21262D)
          : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    'T${value.toInt() + 1}',
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFFE53E3E),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFE53E3E).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareTab(LocalizationService localizationService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              localizationService.getString('compare_feature_coming_soon'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab(LocalizationService localizationService) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizationService.getString('ai_insights'),
            style: TextStyle(
              fontSize: ResponsiveHelper.getFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE53E3E),
            ),
          ),
          const SizedBox(height: 16),
          
          ..._generateInsights(localizationService).map((insight) => 
            _buildInsightCard(insight, localizationService)
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight, LocalizationService localizationService) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF21262D)
          : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: insight['color'].withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: insight['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              insight['icon'],
              color: insight['color'],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getHealthScoreDescription(LocalizationService localizationService) {
    if (_healthScore >= 85) {
  return localizationService.getString('excellent_health');
    } else if (_healthScore >= 70) {
  return localizationService.getString('good_health');
    } else if (_healthScore >= 55) {
  return localizationService.getString('fair_health');
    } else if (_healthScore >= 40) {
  return localizationService.getString('poor_health');
    } else {
  return localizationService.getString('critical_health');
    }
  }

  String _getLastTestDate() {
    if (_latestTest == null) return '-';
    try {
      DateTime date = DateTime.parse(_latestTest!['test_date']);
      Duration diff = DateTime.now().difference(date);
      final loc = Provider.of<LocalizationService>(context, listen: false);
      if (diff.inDays == 0) return loc.getString('date_today');
      if (diff.inDays == 1) return loc.getString('date_yesterday');
      return loc.getStringWithParams('days_ago', {'count': diff.inDays.toString()});
    } catch (e) {
      return '-';
    }
  }

  Color _getRiskColor(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'düşük':
      case 'low':
        return Colors.green;
      case 'orta':
      case 'medium':
        return Colors.orange;
      case 'yüksek':
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTrendDirection() {
    if (_hemogramTests.length < 2) return '-';
    
    var latest = _hemogramTests[0];
    var previous = _hemogramTests[1];
    
    double? latestHb = latest['hemoglobin']?.toDouble();
    double? previousHb = previous['hemoglobin']?.toDouble();
    
    if (latestHb != null && previousHb != null) {
      if (latestHb > previousHb) return '↗️';
      if (latestHb < previousHb) return '↘️';
      return '→';
    }
    
    return '-';
  }

  String _formatTestDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  List<Map<String, dynamic>> _getKeyParameters() {
    return [
      {'key': 'hemoglobin', 'range': [12.0, 17.0], 'unit': 'g/dL'},
      {'key': 'iron', 'range': [60.0, 170.0], 'unit': 'mcg/dL'},
      {'key': 'white_blood_cells', 'range': [4.0, 10.0], 'unit': 'K/uL'},
      {'key': 'platelets', 'range': [150.0, 400.0], 'unit': 'K/uL'},
    ];
  }

  String _getParameterStatus(double? value, List<double> range, LocalizationService localizationService) {
    if (value == null) return '-';
    if (value < range[0]) return localizationService.getString('low');
    if (value > range[1]) return localizationService.getString('high');
    return localizationService.getString('normal');
  }

  Color _getParameterStatusColor(double? value, List<double> range) {
    if (value == null) return Colors.grey;
    if (value < range[0] || value > range[1]) return Colors.red;
    return Colors.green;
  }

  List<Map<String, dynamic>> _generateInsights(LocalizationService localizationService) {
    List<Map<String, dynamic>> insights = [];
    
    if (_latestTest != null) {
      double? hb = _latestTest!['hemoglobin']?.toDouble();
      double? iron = _latestTest!['iron']?.toDouble();
      
      if (hb != null && hb < 12) {
        insights.add({
          'title': localizationService.getString('low_hemoglobin_insight'),
          'description': localizationService.getString('low_hemoglobin_desc'),
          'icon': Icons.warning,
          'color': Colors.red,
        });
      }
      
      if (iron != null && iron < 60) {
        insights.add({
          'title': localizationService.getString('low_iron_insight'),
          'description': localizationService.getString('low_iron_desc'),
          'icon': Icons.local_hospital,
          'color': Colors.orange,
        });
      }
      
      if (_healthScore > 85) {
        insights.add({
          'title': localizationService.getString('great_progress_insight'),
          'description': localizationService.getString('great_progress_desc'),
          'icon': Icons.thumb_up,
          'color': Colors.green,
        });
      }
    }
    
    if (insights.isEmpty) {
      insights.add({
        'title': localizationService.getString('no_insights_insight'),
        'description': localizationService.getString('no_insights_desc'),
        'icon': Icons.psychology,
        'color': Colors.blue,
      });
    }
    
    return insights;
  }
}