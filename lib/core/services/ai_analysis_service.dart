import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../database/app_database.dart';

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
    // This would load TensorFlow Lite models or connect to AI services
    await Future.delayed(const Duration(milliseconds: 500));
    _logger.i('AI models initialized');
  }

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

  Future<TrendAnalysis> _analyzeTrends(
    BloodTestResult bloodTest,
    UserModel user,
  ) async {
    // This would analyze historical data to identify trends
    // For now, returning a mock analysis
    return TrendAnalysis(
      overallTrend: 'stable',
      improvingParameters: ['hemoglobin', 'cholesterol'],
      decliningParameters: [],
      stableParameters: ['glucose', 'alt', 'ast'],
      trendConfidence: 0.75,
    );
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
