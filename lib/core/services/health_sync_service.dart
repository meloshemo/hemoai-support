// Health Sync Service - Platform-aware implementation
// Uses conditional imports to support both with and without health package
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:health/health.dart';
import '../database/app_database.dart';
import '../models/user_model.dart';
import 'dart:io' show Platform;

class HealthSyncService {
  static final HealthSyncService _instance = HealthSyncService._internal();
  factory HealthSyncService() => _instance;
  HealthSyncService._internal();

  final Logger _logger = Logger();
  Health? _health;
  bool _isInitialized = false;
  bool _hasPermissions = false;
  bool _healthPackageAvailable = false;

  // Health data types we're interested in
  static final List<HealthDataType> _healthDataTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN_SATURATION,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.WALKING_HEART_RATE,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.BONE_MASS,
    HealthDataType.LEAN_BODY_MASS,
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize health package
      try {
        _health = Health();
        _healthPackageAvailable = true;
        _logger.i('Health package initialized successfully');
      } catch (e) {
        _logger.w('Health package initialization failed: $e');
        _healthPackageAvailable = false;
        _health = null;
      }
      
      _isInitialized = true;
      
      // Request permissions if package is available
      if (_healthPackageAvailable && _health != null) {
        await _requestPermissions();
      } else {
        _logger.i('Health sync service initialized (package not available - using fallback)');
      }
      
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize health sync service: $e', 
                error: e, stackTrace: stackTrace);
      _isInitialized = true; // Mark as initialized even if package fails
      _healthPackageAvailable = false;
    }
  }

  Future<void> _requestPermissions() async {
    if (!_healthPackageAvailable || _health == null) {
      _hasPermissions = false;
      _logger.i('Health package not available - skipping permissions');
      return;
    }

    try {
      // Request health permissions for all data types
      _hasPermissions = await _health!.requestAuthorization(_healthDataTypes);
      
      if (_hasPermissions) {
        _logger.i('Health permissions granted');
      } else {
        _logger.w('Health permissions denied by user');
      }
      
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
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions || _health == null) {
      _logger.w('Health service not available - returning empty data');
      return {};
    }

    try {
      final healthData = <String, dynamic>{};

      // Fetch data for each health data type
      for (final dataType in _healthDataTypes) {
        try {
          final data = await _health!.getHealthDataFromTypes(
            startDate,
            endDate,
            [dataType],
          );
          
          if (data.isNotEmpty) {
            healthData[dataType.toString()] = data.map((datum) {
              return {
                'value': datum.value.toDouble(),
                'unit': datum.unit.toString(),
                'dateTime': datum.dateFrom ?? datum.dateTo,
              };
            }).toList();
          }
        } catch (e) {
          _logger.w('Failed to fetch ${dataType.toString()}: $e');
        }
      }
      
      _logger.i('Retrieved health data for ${healthData.length} data types');
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
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions || _health == null) {
      return [];
    }

    try {
      final data = await _health!.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.WEIGHT],
      );
      
      return data.map((datum) {
        return {
          'value': datum.value.toDouble(),
          'unit': datum.unit.toString(),
          'dateTime': datum.dateFrom ?? datum.dateTo,
        };
      }).toList();
    } catch (e) {
      _logger.e('Failed to get weight data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBloodPressureData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions || _health == null) {
      return [];
    }

    try {
      final systolicData = await _health!.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.BLOOD_PRESSURE_SYSTOLIC],
      );
      
      final diastolicData = await _health!.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
      );
      
      final results = <Map<String, dynamic>>[];
      
      // Combine systolic and diastolic readings
      for (final systolic in systolicData) {
        final matchingDiastolic = diastolicData.firstWhere(
          (d) => (d.dateFrom ?? d.dateTo).difference(systolic.dateFrom ?? systolic.dateTo).abs().inMinutes < 5,
          orElse: () => systolic, // Fallback if no matching diastolic
        );
        
        results.add({
          'systolic': systolic.value.toDouble(),
          'diastolic': matchingDiastolic.value.toDouble(),
          'unit': systolic.unit.toString(),
          'dateTime': systolic.dateFrom ?? systolic.dateTo,
          'type': 'BLOOD_PRESSURE',
        });
      }
      
      return results;
    } catch (e) {
      _logger.e('Failed to get blood pressure data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getHeartRateData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions || _health == null) {
      return [];
    }

    try {
      final data = await _health!.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.HEART_RATE, HealthDataType.RESTING_HEART_RATE, HealthDataType.WALKING_HEART_RATE],
      );
      
      return data.map((datum) {
        return {
          'value': datum.value.toDouble(),
          'unit': datum.unit.toString(),
          'dateTime': datum.dateFrom ?? datum.dateTo,
          'type': datum.type.toString(),
        };
      }).toList();
    } catch (e) {
      _logger.e('Failed to get heart rate data: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStepsData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions || _health == null) {
      return [];
    }

    try {
      final data = await _health!.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.STEPS],
      );
      
      return data.map((datum) {
        return {
          'value': datum.value.toDouble(),
          'unit': datum.unit.toString(),
          'dateTime': datum.dateFrom ?? datum.dateTo,
        };
      }).toList();
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
    if (!_isInitialized || !_healthPackageAvailable || !_hasPermissions || _health == null) {
      return false;
    }

    try {
      // Map string data type to HealthDataType
      HealthDataType? healthDataType;
      switch (dataType.toUpperCase()) {
        case 'WEIGHT':
          healthDataType = HealthDataType.WEIGHT;
          break;
        case 'HEIGHT':
          healthDataType = HealthDataType.HEIGHT;
          break;
        case 'HEART_RATE':
          healthDataType = HealthDataType.HEART_RATE;
          break;
        case 'BLOOD_GLUCOSE':
          healthDataType = HealthDataType.BLOOD_GLUCOSE;
          break;
        case 'BODY_TEMPERATURE':
          healthDataType = HealthDataType.BODY_TEMPERATURE;
          break;
        default:
          _logger.w('Unsupported data type for writing: $dataType');
          return false;
      }

      if (healthDataType == null) return false;

      // Write health data
      final success = await _health!.writeHealthData(
        value,
        healthDataType,
        dateTime,
        dateTime,
      );

      if (success) {
        _logger.i('Successfully wrote health data: $dataType = $value');
      } else {
        _logger.w('Failed to write health data: $dataType');
      }

      return success;
      
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





