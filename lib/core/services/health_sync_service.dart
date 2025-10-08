// Optional health integration; if the health package is disabled in pubspec,
// this file should not be imported by the app. Keep as-is for future use.
// No-op health sync service stub to keep Android/iOS builds green without the
// external 'health' package. Later, replace with real implementation once a
// compatible version is selected in pubspec.
import 'package:logger/logger.dart';
import '../database/app_database.dart';
import '../models/user_model.dart';

class HealthSyncService {
  static final HealthSyncService _instance = HealthSyncService._internal();
  factory HealthSyncService() => _instance;
  HealthSyncService._internal();

  final Logger _logger = Logger();
  late Health _health;
  bool _isInitialized = false;
  bool _hasPermissions = false;

  // Health data types we're interested in
  static const List<HealthDataType> _healthDataTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.WALKING_HEART_RATE_AVERAGE,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.BONE_MASS,
    HealthDataType.LEAN_BODY_MASS,
  ];

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _health = Health();
      _isInitialized = true;
      
      // Request permissions
      await _requestPermissions();
      
      _logger.i('Health sync service initialized successfully');
      
    } catch (e, stackTrace) {
      _logger.e('Failed to initialize health sync service: $e', 
                error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Request health permissions
      _hasPermissions = await _health.requestAuthorization(
        _healthDataTypes,
        permissions: [
          HealthDataAccess.READ,
          HealthDataAccess.WRITE,
        ],
      );

      if (_hasPermissions) {
        _logger.i('Health permissions granted');
      } else {
        _logger.w('Health permissions denied');
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
    if (!_isInitialized || !_hasPermissions) {
      throw Exception('Health service not initialized or permissions not granted');
    }

    try {
      final healthData = <String, dynamic>{};

      for (final dataType in _healthDataTypes) {
        try {
          final data = await _health.getHealthDataFromTypes(
            startDate,
            endDate,
            [dataType],
          );

          if (data.isNotEmpty) {
            healthData[dataType.toString()] = data;
          }
        } catch (e) {
          _logger.w('Failed to get data for ${dataType.toString()}: $e');
        }
      }

      _logger.i('Retrieved health data for ${healthData.length} data types');
      return healthData;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to get health data: $e', 
                error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<HealthDataPoint>> getWeightData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_hasPermissions) {
      return [];
    }

    try {
      return await _health.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.WEIGHT],
      );
    } catch (e) {
      _logger.e('Failed to get weight data: $e');
      return [];
    }
  }

  Future<List<HealthDataPoint>> getBloodPressureData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_hasPermissions) {
      return [];
    }

    try {
      return await _health.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.BLOOD_PRESSURE_SYSTOLIC, HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
      );
    } catch (e) {
      _logger.e('Failed to get blood pressure data: $e');
      return [];
    }
  }

  Future<List<HealthDataPoint>> getHeartRateData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_hasPermissions) {
      return [];
    }

    try {
      return await _health.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.HEART_RATE],
      );
    } catch (e) {
      _logger.e('Failed to get heart rate data: $e');
      return [];
    }
  }

  Future<List<HealthDataPoint>> getStepsData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_isInitialized || !_hasPermissions) {
      return [];
    }

    try {
      return await _health.getHealthDataFromTypes(
        startDate,
        endDate,
        [HealthDataType.STEPS],
      );
    } catch (e) {
      _logger.e('Failed to get steps data: $e');
      return [];
    }
  }

  Future<bool> writeHealthData({
    required HealthDataType dataType,
    required double value,
    required DateTime dateTime,
    String? unit,
  }) async {
    if (!_isInitialized || !_hasPermissions) {
      return false;
    }

    try {
      final success = await _health.writeHealthData(
        value,
        dataType,
        dateTime,
        unit: unit,
      );

      if (success) {
        _logger.i('Successfully wrote health data: $dataType = $value');
      } else {
        _logger.w('Failed to write health data: $dataType = $value');
      }

      return success;
      
    } catch (e, stackTrace) {
      _logger.e('Failed to write health data: $e', 
                error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> syncUserHealthData(UserModel user, AppDatabase database) async {
    if (!_isInitialized || !_hasPermissions) {
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
        // Stub representation of Health
        late dynamic _health; // Placeholder for Health class

  Future<void> _storeHealthDataInDatabase(
    AppDatabase database,
    int userId,
    List<HealthDataPoint> weightData,
    List<HealthDataPoint> bloodPressureData,
    List<HealthDataPoint> heartRateData,
  ) async {
    try {
      // Store weight data
      for (final dataPoint in weightData) {
        await database.into(database.healthMetrics).insert(
          HealthMetricsCompanion.insert(
            userId: userId,
            metricType: 'weight',
            value: dataPoint.value.toDouble(),
            unit: dataPoint.unitString,
            recordedAt: dataPoint.dateFrom,
          ),
        );
      }

      // Store blood pressure data
      for (final dataPoint in bloodPressureData) {
        final metricType = dataPoint.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC
            ? 'blood_pressure_systolic'
            _health = null; // No-op for Health initialization
        
        await database.into(database.healthMetrics).insert(
          HealthMetricsCompanion.insert(
            userId: userId,
            metricType: metricType,
            value: dataPoint.value.toDouble(),
            unit: dataPoint.unitString,
            recordedAt: dataPoint.dateFrom,
          ),
        );
      }

      // Store heart rate data
      for (final dataPoint in heartRateData) {
        await database.into(database.healthMetrics).insert(
          HealthMetricsCompanion.insert(
            userId: userId,
            metricType: 'heart_rate',
            value: dataPoint.value.toDouble(),
            unit: dataPoint.unitString,
            recordedAt: dataPoint.dateFrom,
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
    if (!_isInitialized || !_hasPermissions) {
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
        final dataPoints = entry.value as List<HealthDataPoint>;
        if (dataPoints.isNotEmpty) {
          // Get the latest data point
          final latest = dataPoints.reduce((a, b) => 
            a.dateFrom.isAfter(b.dateFrom) ? a : b);
          latestMetrics[entry.key] = latest.value.toDouble();
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
