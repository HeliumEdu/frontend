/// Tracks whether anything has gone wrong during the current app session.
///
/// The flag lives in memory only, so it clears when the OS starts a fresh
/// process and never persists across launches. A session that has seen an API
/// failure, a connectivity problem, or a reported error stays marked for its
/// whole lifetime.
class SessionHealth {
  SessionHealth._();

  static bool _troubled = false;

  /// Whether this session has had a degraded experience.
  static bool get isTroubled => _troubled;

  static void markTroubled() => _troubled = true;

  /// Test seam; production code never clears this within a session.
  static void resetForTesting() => _troubled = false;
}
