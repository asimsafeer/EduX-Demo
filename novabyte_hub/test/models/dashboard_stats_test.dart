/// Unit tests for DashboardStats model
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:novabyte_hub/models/dashboard_stats.dart';

void main() {
  group('DashboardStats', () {
    test('construction with all fields', () {
      const stats = DashboardStats(
        totalSchools: 25,
        pendingRequests: 5,
        activeLicenses: 18,
        expiringSoon: 3,
      );

      expect(stats.totalSchools, equals(25));
      expect(stats.pendingRequests, equals(5));
      expect(stats.activeLicenses, equals(18));
      expect(stats.expiringSoon, equals(3));
    });

    test('empty factory returns all zeros', () {
      expect(DashboardStats.empty.totalSchools, equals(0));
      expect(DashboardStats.empty.pendingRequests, equals(0));
      expect(DashboardStats.empty.activeLicenses, equals(0));
      expect(DashboardStats.empty.expiringSoon, equals(0));
    });

    test('large values are handled correctly', () {
      const stats = DashboardStats(
        totalSchools: 999999,
        pendingRequests: 50000,
        activeLicenses: 800000,
        expiringSoon: 10000,
      );

      expect(stats.totalSchools, equals(999999));
    });

    test('zero values are valid', () {
      const stats = DashboardStats(
        totalSchools: 0,
        pendingRequests: 0,
        activeLicenses: 0,
        expiringSoon: 0,
      );

      expect(stats.totalSchools, equals(0));
      expect(stats.pendingRequests, equals(0));
    });
  });
}
