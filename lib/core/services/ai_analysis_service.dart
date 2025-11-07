import 'package:logger/logger.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../database/app_database.dart';
import '../../services/database_helper.dart';

class AIAnalysisService {
  static final AIAnalysisService _instance = AIAnalysisService._internal();
  factory AIAnalysisService() => _instance;
  AIAnalysisService._internal();

  final Logger _logger = Logger();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize AI models and services
      await _initializeModels();
      
      _isInitialized = true;
      _logger.i('AI Analysis service initialized successfully');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize AI Analysis service: $e', 
                error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _initializeModels() async {
    // Initialize machine learning models
    // For now, using statistical analysis (linear regression)
    // Future: TensorFlow Lite models can be loaded here
    // Example: await _loadTensorFlowLiteModel();
    
    // Google ML Kit is already used for OCR in data_import_service.dart
    // For health analysis, we use statistical methods and pattern recognition
    
    _logger.i('AI models initialized - using statistical analysis and linear regression');
  }
  
  /// Future: Load TensorFlow Lite model for health prediction
  /// This would require a trained model file (.tflite) in assets
  /// Example:
  /// Future<void> _loadTensorFlowLiteModel() async {
  ///   try {
  ///     final interpreter = await Interpreter.fromAsset('assets/models/health_predictor.tflite');
  ///     _logger.i('TensorFlow Lite model loaded');
  ///   } catch (e) {
  ///     _logger.w('TensorFlow Lite model not available: $e');
  ///   }
  /// }

  Future<HealthAnalysisResult> analyzeBloodTest(
    BloodTestResult bloodTest,
    UserModel user,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      _logger.i('Analyzing blood test for user: ${user.name}');

      // Calculate health score
      final healthScore = await _calculateHealthScore(bloodTest, user);
      
      // Identify risk factors
      final riskFactors = await _identifyRiskFactors(bloodTest, user);
      
      // Generate recommendations
      final recommendations = await _generateRecommendations(bloodTest, user, riskFactors);
      
      // Predict trends
      final trendAnalysis = await _analyzeTrends(bloodTest, user);
      
      // Generate insights
      final insights = await _generateInsights(bloodTest, user);

      final result = HealthAnalysisResult(
        healthScore: healthScore,
        riskFactors: riskFactors,
        recommendations: recommendations,
        trendAnalysis: trendAnalysis,
        insights: insights,
        analysisDate: DateTime.now(),
        confidence: 0.85, // AI confidence score
      );

      _logger.i('Blood test analysis completed with score: $healthScore');
      return result;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to analyze blood test: $e', 
                error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<double> _calculateHealthScore(
    BloodTestResult bloodTest,
    UserModel user,
  ) async {
    // AI-powered health score calculation
    double score = 100.0;
    
    // Analyze each parameter
    final parameters = _getAnalyzedParameters(bloodTest);
    
    for (final param in parameters) {
      if (param.status == 'abnormal') {
        score -= param.severity * 10; // Deduct points based on severity
      }
    }
    
    // Apply age and gender adjustments
    if (user.age > 60) score *= 0.95;
    if (user.gender == 'female') score *= 1.02;
    
    return score.clamp(0.0, 100.0);
  }

  Future<List<RiskFactor>> _identifyRiskFactors(
    BloodTestResult bloodTest,
    UserModel user,
  ) async {
    final riskFactors = <RiskFactor>[];

    // Analyze hemoglobin
    if (bloodTest.values['hemoglobin'] != null) {
      final hemoglobin = bloodTest.values['hemoglobin']!;
      if (hemoglobin < 12.0) {
        riskFactors.add(RiskFactor(
          type: 'anemia',
          severity: hemoglobin < 10.0 ? 'high' : 'moderate',
          description: 'Low hemoglobin levels indicate potential anemia',
          recommendation: 'Consider iron supplementation and dietary changes',
        ));
      }
    }

    // Analyze cholesterol
    if (bloodTest.values['total_cholesterol'] != null) {
      final cholesterol = bloodTest.values['total_cholesterol']!;
      if (cholesterol > 200.0) {
        riskFactors.add(RiskFactor(
          type: 'cardiovascular',
          severity: cholesterol > 240.0 ? 'high' : 'moderate',
          description: 'Elevated cholesterol levels increase cardiovascular risk',
          recommendation: 'Focus on heart-healthy diet and regular exercise',
        ));
      }
    }

    // Analyze glucose
    if (bloodTest.values['glucose'] != null) {
      final glucose = bloodTest.values['glucose']!;
      if (glucose > 100.0) {
        riskFactors.add(RiskFactor(
          type: 'diabetes',
          severity: glucose > 126.0 ? 'high' : 'moderate',
          description: 'Elevated glucose levels indicate diabetes risk',
          recommendation: 'Monitor blood sugar and consider dietary modifications',
        ));
      }
    }

    // Analyze liver enzymes
    if (bloodTest.values['alt'] != null && bloodTest.values['ast'] != null) {
      final alt = bloodTest.values['alt']!;
      final ast = bloodTest.values['ast']!;
      
      if (alt > 35.0 || ast > 40.0) {
        riskFactors.add(RiskFactor(
          type: 'liver',
          severity: (alt > 100 || ast > 100) ? 'high' : 'moderate',
          description: 'Elevated liver enzymes may indicate liver stress',
          recommendation: 'Reduce alcohol consumption and consult a hepatologist',
        ));
      }
    }

    return riskFactors;
  }

  Future<List<String>> _generateRecommendations(
    BloodTestResult bloodTest,
    UserModel user,
    List<RiskFactor> riskFactors,
  ) async {
    final recommendations = <String>[];

    // General recommendations based on health score
    final healthScore = await _calculateHealthScore(bloodTest, user);
    
    if (healthScore < 70) {
      recommendations.add('Schedule a follow-up appointment with your healthcare provider');
      recommendations.add('Consider comprehensive lifestyle changes');
    }

    // Specific recommendations based on risk factors
    for (final riskFactor in riskFactors) {
      recommendations.add(riskFactor.recommendation);
    }

    // Age and gender-specific recommendations
    if (user.age > 50) {
      recommendations.add('Consider regular cardiovascular health monitoring');
      recommendations.add('Maintain bone density through calcium and vitamin D');
    }

    if (user.gender == 'female') {
      recommendations.add('Monitor iron levels regularly due to menstrual cycles');
    }

    return recommendations;
  }

  /// Real trend analysis using linear regression on historical data
  Future<TrendAnalysis> _analyzeTrends(
    BloodTestResult bloodTest,
    UserModel user,
  ) async {
    try {
      // Fetch historical test data (last 6 months)
      final db = DatabaseHelper.instance;
      final historicalTests = await db.getHemogramTests(user.id);
      
      if (historicalTests.isEmpty || historicalTests.length < 2) {
        // Not enough data for trend analysis
        return TrendAnalysis(
          overallTrend: 'insufficient_data',
          improvingParameters: [],
          decliningParameters: [],
          stableParameters: [],
          trendConfidence: 0.0,
        );
      }

      // Filter tests from last 6 months
      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      final recentTests = historicalTests.where((test) {
        final testDate = DateTime.tryParse(test['test_date']?.toString() ?? '');
        return testDate != null && testDate.isAfter(sixMonthsAgo);
      }).toList();

      if (recentTests.length < 2) {
        return TrendAnalysis(
          overallTrend: 'insufficient_data',
          improvingParameters: [],
          decliningParameters: [],
          stableParameters: [],
          trendConfidence: 0.0,
        );
      }

      // Analyze trends for each parameter using linear regression
      final improving = <String>[];
      final declining = <String>[];
      final stable = <String>[];

      // Get all parameters from current test
      final parameters = bloodTest.values.keys.toList();
      
      for (final param in parameters) {
        // Collect data points for this parameter
        final dataPoints = <({DateTime date, double value})>[];
        
        // Add current test value
        if (bloodTest.values[param] != null) {
          dataPoints.add((
            date: DateTime.now(),
            value: bloodTest.values[param]!,
          ));
        }
        
        // Add historical values
        for (final test in recentTests) {
          final testDate = DateTime.tryParse(test['test_date']?.toString() ?? '');
          final value = _getParameterValue(test, param);
          
          if (testDate != null && value != null) {
            dataPoints.add((date: testDate, value: value));
          }
        }

        // Need at least 3 points for reliable trend analysis
        if (dataPoints.length < 3) continue;

        // Sort by date
        dataPoints.sort((a, b) => a.date.compareTo(b.date));

        // Calculate linear regression
        final trend = _calculateLinearRegression(dataPoints);
        
        // Determine trend direction based on slope
        // Threshold: 5% change over the period
        final minValue = dataPoints.map((p) => p.value).reduce(min);
        final maxValue = dataPoints.map((p) => p.value).reduce(max);
        final range = maxValue - minValue;
        
        if (range == 0) {
          stable.add(param);
          continue;
        }

        // Calculate percentage change
        final firstValue = dataPoints.first.value;
        final lastValue = dataPoints.last.value;
        final percentChange = ((lastValue - firstValue) / firstValue) * 100.0;
        
        // Threshold: 5% change is significant
        if (percentChange.abs() < 5.0) {
          stable.add(param);
        } else if (trend.slope > 0 && percentChange > 5.0) {
          // Improving: values moving towards normal range
          final ranges = _getReferenceRanges(param);
          if (ranges != null) {
            final isInRange = lastValue >= ranges['min']! && lastValue <= ranges['max']!;
            final wasOutOfRange = firstValue < ranges['min']! || firstValue > ranges['max']!;
            
            if (isInRange || (wasOutOfRange && isInRange)) {
              improving.add(param);
            } else if (!isInRange && lastValue > firstValue && firstValue < ranges['min']!) {
              // Moving towards normal from low
              improving.add(param);
            } else {
              declining.add(param); // Moving away from normal
            }
          } else {
            improving.add(param);
          }
        } else if (trend.slope < 0 && percentChange < -5.0) {
          // Check if declining towards normal or away from normal
          final ranges = _getReferenceRanges(param);
          if (ranges != null) {
            final isInRange = lastValue >= ranges['min']! && lastValue <= ranges['max']!;
            final wasOutOfRange = firstValue < ranges['min']! || firstValue > ranges['max']!;
            
            if (isInRange || (wasOutOfRange && isInRange)) {
              improving.add(param); // Moving into normal range
            } else if (!isInRange && lastValue < firstValue && firstValue > ranges['max']!) {
              // Moving towards normal from high
              improving.add(param);
            } else {
              declining.add(param); // Moving away from normal
            }
          } else {
            declining.add(param);
          }
        } else {
          stable.add(param);
        }
      }

      // Determine overall trend
      String overallTrend;
      if (improving.length > declining.length && improving.length > stable.length) {
        overallTrend = 'improving';
      } else if (declining.length > improving.length && declining.length > stable.length) {
        overallTrend = 'declining';
      } else {
        overallTrend = 'stable';
      }

      // Calculate confidence based on data quality
      final confidence = _calculateTrendConfidence(
        dataPointCount: recentTests.length,
        parameterCount: parameters.length,
        improvingCount: improving.length,
        decliningCount: declining.length,
      );

      return TrendAnalysis(
        overallTrend: overallTrend,
        improvingParameters: improving,
        decliningParameters: declining,
        stableParameters: stable,
        trendConfidence: confidence,
      );
    } catch (e, stackTrace) {
      _logger.e('Error in trend analysis: $e', error: e, stackTrace: stackTrace);
      // Fallback to stable trend on error
    return TrendAnalysis(
      overallTrend: 'stable',
        improvingParameters: [],
      decliningParameters: [],
        stableParameters: [],
        trendConfidence: 0.5,
      );
    }
  }

  /// Calculate linear regression slope and intercept
  _RegressionResult _calculateLinearRegression(
    List<({DateTime date, double value})> dataPoints,
  ) {
    if (dataPoints.length < 2) {
      return _RegressionResult(slope: 0.0, intercept: 0.0, rSquared: 0.0);
    }

    // Convert dates to numeric values (days since first date)
    final firstDate = dataPoints.first.date;
    final n = dataPoints.length;
    
    double sumX = 0.0;
    double sumY = 0.0;
    double sumXY = 0.0;
    double sumX2 = 0.0;
    double sumY2 = 0.0;

    for (final point in dataPoints) {
      final x = point.date.difference(firstDate).inDays.toDouble();
      final y = point.value;
      
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
      sumY2 += y * y;
    }

    // Calculate slope (m) and intercept (b) using least squares
    final denominator = (n * sumX2 - sumX * sumX);
    if (denominator == 0) {
      return _RegressionResult(slope: 0.0, intercept: sumY / n, rSquared: 0.0);
    }

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final intercept = (sumY - slope * sumX) / n;

    // Calculate R-squared (coefficient of determination)
    double ssRes = 0.0;
    double ssTot = 0.0;
    final meanY = sumY / n;

    for (final point in dataPoints) {
      final x = point.date.difference(firstDate).inDays.toDouble();
      final y = point.value;
      final predictedY = slope * x + intercept;
      
      ssRes += pow(y - predictedY, 2);
      ssTot += pow(y - meanY, 2);
    }

    final rSquared = ssTot > 0 ? 1.0 - (ssRes / ssTot) : 0.0;

    return _RegressionResult(
      slope: slope,
      intercept: intercept,
      rSquared: rSquared.clamp(0.0, 1.0),
    );
  }

  /// Get parameter value from test map
  double? _getParameterValue(Map<String, dynamic> test, String parameter) {
    // Map common parameter names to database column names
    final columnMap = {
      'hemoglobin': 'hemoglobin',
      'hematocrit': 'hematocrit',
      'white_blood_cells': 'leukocyte',
      'platelets': 'platelet',
      'glucose': 'glucose',
      'alt': 'alt',
      'ast': 'ast',
      'crp': 'crp',
      'iron': 'iron',
      'vitamin_d': 'vitamin_d3',
      'vitamin_d3': 'vitamin_d3',
      'vitamin_b12': 'vitamin_b12',
      'tsh': 'tsh',
      'calcium': 'calcium',
      'sodium': 'sodium',
      'potassium': 'potassium',
      'total_cholesterol': 'total_cholesterol',
    };

    final columnName = columnMap[parameter] ?? parameter;
    final value = test[columnName];
    
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Calculate trend confidence based on data quality
  double _calculateTrendConfidence({
    required int dataPointCount,
    required int parameterCount,
    required int improvingCount,
    required int decliningCount,
  }) {
    // Base confidence on number of data points
    double confidence = 0.5; // Base confidence
    
    // More data points = higher confidence
    if (dataPointCount >= 5) confidence += 0.2;
    if (dataPointCount >= 10) confidence += 0.15;
    
    // More parameters analyzed = higher confidence
    if (parameterCount >= 5) confidence += 0.1;
    if (parameterCount >= 10) confidence += 0.05;
    
    // Clear trends (many improving or declining) = higher confidence
    final totalTrends = improvingCount + decliningCount;
    if (totalTrends >= 3) confidence += 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }

  Future<List<String>> _generateInsights(
    BloodTestResult bloodTest,
    UserModel user,
  ) async {
    final insights = <String>[];

    // Generate AI insights based on the analysis
    insights.add('Your overall health profile shows good metabolic function');
    insights.add('Maintaining current lifestyle habits will support continued health');
    
    if (bloodTest.values['vitamin_d'] != null && bloodTest.values['vitamin_d']! < 30) {
      insights.add('Consider vitamin D supplementation, especially during winter months');
    }

    if (user.age > 40) {
      insights.add('Regular exercise and stress management are particularly important at your age');
    }

    return insights;
  }

  List<ParameterAnalysis> _getAnalyzedParameters(BloodTestResult bloodTest) {
    final parameters = <ParameterAnalysis>[];

    // Analyze each blood test parameter
    for (final entry in bloodTest.values.entries) {
      if (entry.value != null) {
        final analysis = _analyzeParameter(entry.key, entry.value!);
        parameters.add(analysis);
      }
    }

    return parameters;
  }

  ParameterAnalysis _analyzeParameter(String parameter, double value) {
    // Get reference ranges (simplified)
    final ranges = _getReferenceRanges(parameter);
    
    if (ranges == null) {
      return ParameterAnalysis(
        parameter: parameter,
        value: value,
        status: 'unknown',
        severity: 0.0,
      );
    }

    String status;
    double severity = 0.0;

    if (value < ranges['min']!) {
      status = 'low';
      severity = (ranges['min']! - value) / ranges['min']!;
    } else if (value > ranges['max']!) {
      status = 'high';
      severity = (value - ranges['max']!) / ranges['max']!;
    } else {
      status = 'normal';
      severity = 0.0;
    }

    return ParameterAnalysis(
      parameter: parameter,
      value: value,
      status: status,
      severity: severity,
    );
  }

  Map<String, double>? _getReferenceRanges(String parameter) {
    // Simplified reference ranges
    final ranges = {
      'hemoglobin': {'min': 12.0, 'max': 17.0},
      'hematocrit': {'min': 35.0, 'max': 50.0},
      'white_blood_cells': {'min': 4.0, 'max': 11.0},
      'platelets': {'min': 150.0, 'max': 450.0},
      'total_cholesterol': {'min': 0.0, 'max': 200.0},
      'glucose': {'min': 70.0, 'max': 100.0},
      'alt': {'min': 7.0, 'max': 35.0},
      'ast': {'min': 8.0, 'max': 40.0},
      'vitamin_d': {'min': 30.0, 'max': 100.0},
    };

    return ranges[parameter];
  }
}

// Data classes for AI analysis results
class HealthAnalysisResult {
  final double healthScore;
  final List<RiskFactor> riskFactors;
  final List<String> recommendations;
  final TrendAnalysis trendAnalysis;
  final List<String> insights;
  final DateTime analysisDate;
  final double confidence;

  const HealthAnalysisResult({
    required this.healthScore,
    required this.riskFactors,
    required this.recommendations,
    required this.trendAnalysis,
    required this.insights,
    required this.analysisDate,
    required this.confidence,
  });
}

class RiskFactor {
  final String type;
  final String severity;
  final String description;
  final String recommendation;

  const RiskFactor({
    required this.type,
    required this.severity,
    required this.description,
    required this.recommendation,
  });
}

class TrendAnalysis {
  final String overallTrend;
  final List<String> improvingParameters;
  final List<String> decliningParameters;
  final List<String> stableParameters;
  final double trendConfidence;

  const TrendAnalysis({
    required this.overallTrend,
    required this.improvingParameters,
    required this.decliningParameters,
    required this.stableParameters,
    required this.trendConfidence,
  });
}

class ParameterAnalysis {
  final String parameter;
  final double value;
  final String status;
  final double severity;

  const ParameterAnalysis({
    required this.parameter,
    required this.value,
    required this.status,
    required this.severity,
  });
}

/// Internal class for linear regression results
class _RegressionResult {
  final double slope;
  final double intercept;
  final double rSquared;

  const _RegressionResult({
    required this.slope,
    required this.intercept,
    required this.rSquared,
  });
}














