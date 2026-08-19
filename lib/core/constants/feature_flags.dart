/// App feature flags toggled via `--dart-define=...`.
///
/// Keep these read-only so production builds are deterministic.
class FeatureFlags {
  FeatureFlags._();

  /// Boot into a minimal screen to diagnose renderer / widget tree issues.
  static const bool minimalBoot = bool.fromEnvironment('TM_MINIMAL_BOOT');

  /// Disable BackdropFilter-based blur effects (can help on some emulators/GPUs).
  static const bool disableBlur = bool.fromEnvironment('TM_DISABLE_BLUR');
}
