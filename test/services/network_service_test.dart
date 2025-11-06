import 'package:flutter_test/flutter_test.dart';
import 'package:hemoai/services/network_service.dart';

void main() {
  group('NetworkService', () {
    test('should initialize successfully', () async {
      final service = NetworkService();
      await service.initialize();
      expect(service.isInitialized, true);
    });

    test('should check connectivity', () async {
      final service = NetworkService();
      await service.initialize();
      final result = await service.checkConnectivity();
      expect(result, isNotNull);
    });

    test('should provide network status text', () {
      final service = NetworkService();
      final status = service.getNetworkStatusText();
      expect(status, isNotEmpty);
    });
  });
}

