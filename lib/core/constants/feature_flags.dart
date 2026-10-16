/// App feature flags toggled via `--dart-define=...`.
///
/// Keep these read-only so production builds are deterministic.
class FeatureFlags {
  FeatureFlags._();

  /// Boot into a minimal screen to diagnose renderer / widget tree issues.
  static const bool minimalBoot = bool.fromEnvironment('TM_MINIMAL_BOOT');

  /// Disable BackdropFilter-based blur effects (can help on some emulators/GPUs).
  static const bool disableBlur = bool.fromEnvironment('TM_DISABLE_BLUR');

  /// Keep loyalty/reward features enabled for the normal HOMIES app.
  ///
  /// A restricted submission build can opt out explicitly with
  /// `TM_ENABLE_FINANCIAL_REWARDS=false`.
  static const bool enableFinancialRewards = bool.fromEnvironment(
    'TM_ENABLE_FINANCIAL_REWARDS',
    defaultValue: true,
  );
  static const bool disableFinancialRewards = !enableFinancialRewards;

  /// Keep in-app payment services enabled for the normal HOMIES app.
  static const bool enableInAppPayments = bool.fromEnvironment(
    'TM_ENABLE_IN_APP_PAYMENTS',
    defaultValue: true,
  );
  static const bool disableInAppPayments = !enableInAppPayments;
}
