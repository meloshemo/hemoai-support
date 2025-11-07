// Health Sync Service - Platform-aware implementation
// Uses conditional imports to support both with and without health package
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../database/app_database.dart';
import '../models/user_model.dart';
import 'dart:io' show Platform;

class HealthSyncService {
  static final HealthSyncService _instance = HealthSyncService._internal();
  factory HealthSyncService() => _instance;
  HealthSyncService._internal();

  final Logger _logger = Logger();
  dynamic _health; // Dynamic to handle optional package
  bool _isInitialized = false;
  bool _hasPermissions = false;
  bool _healthPackageAvailable = false;

  // Health data types we're interested in (will be converted to strings if package unavailable)
  static const List<String> _healthDataTypes = [
    'WEIGHT',
    'HEIGHT',
    'BLOOD_PRESSURE_SYSTOLIC',
    'BLOOD_PRESSURE_DIASTOLIC',
    'HEART_RATE',
    'BLOOD_OXYGEN',
    'BODY_TEMPERATURE',
    'STEPS',
    'ACTIVE_ENERGY_BURNED',
    'RESTING_HEART_RATE',
    'WALKING_HEART_RATE_AVERAGE',
    'BLOOD_GLUCOSE',
    'BODY_FAT_PERCENTAGE',
    'BONE_MASS',
    'LEAN_BODY_MASS',
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Try to initialize health package if available
      try {
        // Conditional import would go here, but for now we check if package is available
        _healthPackageAvailable = false; // Set to true when health package is added
        if (_healthPackageAvailable) {
          // _health = Health(); // Uncomment when health package is available
        }
      } catch (e) {
        _logger.w('Health package not available: $e');
        _healthPackageAvailable = false;
      }
      
      _isInitialized = true;
      
      // Request permissions only if package is available
      if (_healthPackageAvailable) {
        await _requestPermissions();
      } else {
        _logger.i('Health sync service initialized (package not available - using fallback)');
      }
      
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize health sync service: $e', 
                error: e, stackTrace: stackTrace);
      _isInitialized = true; // Mark as initialized even if package fails
    }
  }

  Future<void> _requestPermissions() async {
    if (!_healthPackageAvailable || _health == null) {
      _hasPermissions = false;
      _logger.i('Health package not available - skipping permissions');
      return;
    }

    try {
      // Request health permissions (when package is available)
      // _hasPermissions = await _health.requestAuthorization(...);
      _hasPermissions = false; // Set to false until package is integrated
      _logger.w('Health permissions not implemented (package not available)');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to request health permissions: $e', 
                error: e, stackTrace: stackTrace);
      _hasPermissions = false;
    }
  }

  Future<bool> hasPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _hasPermissions;
  }

  Future<void> requestPermissions() async {
    await _requestPermissions();
  }

  Future<Map<String, dynamic>> getHealthData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions) {
      _logger.w('Health service not available - returning empty data');
      return {};
    }

    try {
      final healthData = <String, dynamic>{};

      // When health package is integrated, implement data fetching here
      _logger.i('Health data retrieval would happen here (package not available)');
      
      return healthData;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to get health data: $e', 
                error: e, stackTrace: stackTrace);
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getWeightData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions) {
      return [];
    }

    try {
      // When health package is integrated, implement weight data fetching here
      _logger.i('Weight data retrieval would happen here (package not available)');
      return [];
    } catch (e) {
      _logger.e('Failed to get weight data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBloodPressureData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions) {
      return [];
    }

    try {
      // When health package is integrated, implement blood pressure data fetching here
      _logger.i('Blood pressure data retrieval would happen here (package not available)');
      return [];
    } catch (e) {
      _logger.e('Failed to get blood pressure data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getHeartRateData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions) {
      return [];
    }

    try {
      // When health package is integrated, implement heart rate data fetching here
      _logger.i('Heart rate data retrieval would happen here (package not available)');
      return [];
    } catch (e) {
      _logger.e('Failed to get heart rate data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStepsData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions) {
      return [];
    }

    try {
      // When health package is integrated, implement steps data fetching here
      _logger.i('Steps data retrieval would happen here (package not available)');
      return [];
    } catch (e) {
      _logger.e('Failed to get steps data: $e');
      return [];
    }
  }

  Future<bool> writeHealthData({
    required String dataType,
    required double value,
    required DateTime dateTime,
    String? unit,
  }) async {
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions) {
      return false;
    }

    try {
      // When health package is integrated, implement data writing here
      _logger.i('Health data writing would happen here (package not available): $dataType = $value');
      return false; // Return false until package is integrated
      
    } catch (e, stackTrace) {
      _logger.e('Failed to write health data: $e', 
                error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> syncUserHealthData(UserModel user, AppDatabase database) async {
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions) {
      _logger.i('Health sync skipped - package not available or no permissions');
      return;
    }

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      // Get weight data
      final weightData = await getWeightData(
        startDate: startDate,
        endDate: endDate,
      );

      // Get blood pressure data
      final bloodPressureData = await getBloodPressureData(
        startDate: startDate,
        endDate: endDate,
      );

      // Get heart rate data
      final heartRateData = await getHeartRateData(
        startDate: startDate,
        endDate: endDate,
      );

      // Store in database
      await _storeHealthDataInDatabase(
        database,
        user.id,
        weightData,
        bloodPressureData,
        heartRateData,
      );

      _logger.i('Successfully synced health data for user: ${user.name}');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to sync health data: $e', 
                error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _storeHealthDataInDatabase(
    AppDatabase database,
    int userId,
    List<Map<String, dynamic>> weightData,
    List<Map<String, dynamic>> bloodPressureData,
    List<Map<String, dynamic>> heartRateData,
  ) async {
    try {
      // Store weight data
      for (final dataPoint in weightData) {
        await database.into(database.healthMetrics).insert(
          HealthMetricsCompanion.insert(
            userId: userId,
            metricType: 'weight',
            value: (dataPoint['value'] as num).toDouble(),
            unit: dataPoint['unit'] as String? ?? 'kg',
            recordedAt: dataPoint['dateTime'] as DateTime? ?? DateTime.now(),
          ),
        );
      }

      // Store blood pressure data
      for (final dataPoint in bloodPressureData) {
        final metricType = dataPoint['type']?.toString().contains('SYSTOLIC') ?? false
            ? 'blood_pressure_systolic'
            : 'blood_pressure_diastolic';
        
        await database.into(database.healthMetrics).insert(
          HealthMetricsCompanion.insert(
            userId: userId,
            metricType: metricType,
            value: (dataPoint['value'] as num).toDouble(),
            unit: dataPoint['unit'] as String? ?? 'mmHg',
            recordedAt: dataPoint['dateTime'] as DateTime? ?? DateTime.now(),
          ),
        );
      }

      // Store heart rate data
      for (final dataPoint in heartRateData) {
        await database.into(database.healthMetrics).insert(
          HealthMetricsCompanion.insert(
            userId: userId,
            metricType: 'heart_rate',
            value: (dataPoint['value'] as num).toDouble(),
            unit: dataPoint['unit'] as String? ?? 'bpm',
            recordedAt: dataPoint['dateTime'] as DateTime? ?? DateTime.now(),
          ),
        );
      }

      _logger.i('Health data stored in database successfully');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to store health data in database: $e', 
                error: e, stackTrace: stackTrace);
    }
  }

  Future<Map<String, double>> getLatestHealthMetrics() async {
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions) {
      return {};
    }

    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 1));

      final healthData = await getHealthData(
        startDate: startDate,
        endDate: endDate,
      );

      final latestMetrics = <String, double>{};

      for (final entry in healthData.entries) {
        final dataPoints = entry.value as List<Map<String, dynamic>>;
        if (dataPoints.isNotEmpty) {
          // Get the latest data point
          final latest = dataPoints.reduce((a, b) {
            final dateA = a['dateTime'] as DateTime? ?? DateTime(1970);
            final dateB = b['dateTime'] as DateTime? ?? DateTime(1970);
            return dateA.isAfter(dateB) ? a : b;
          });
          latestMetrics[entry.key] = (latest['value'] as num).toDouble();
        }
      }

      return latestMetrics;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to get latest health metrics: $e', 
                error: e, stackTrace: stackTrace);
      return {};
    }
  }
}





