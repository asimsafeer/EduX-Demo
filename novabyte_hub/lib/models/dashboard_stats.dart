/// NovaByte Hub — Dashboard Statistics Model
library;

/// Aggregated statistics for the admin dashboard
class DashboardStats {
  final int totalSchools;
  final int pendingRequests;
  final int activeLicenses;
  final int expiringSoon;

  const DashboardStats({
    required this.totalSchools,
    required this.pendingRequests,
    required this.activeLicenses,
    required this.expiringSoon,
  });

  /// Empty/loading state
  static const empty = DashboardStats(
    totalSchools: 0,
    pendingRequests: 0,
    activeLicenses: 0,
    expiringSoon: 0,
  );
}
