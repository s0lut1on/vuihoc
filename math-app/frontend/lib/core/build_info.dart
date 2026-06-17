// Build metadata — displayed on the Home screen footer so users (and us) can
// verify which build is actually deployed. Compiled into the bundle via
// `flutter build web --dart-define=APP_VERSION=<sha>` so the value is
// inlined by the Dart compiler and survives web minification.

/// Build identifier, e.g. "v1.0.0+12abcde". Injected at build time.
/// Falls back to "dev" when not provided (local debug builds).
const String kBuildVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: 'dev',
);

/// Whether the current build was started in debug mode.
const bool kIsDebugBuild = bool.fromEnvironment(
  'DEBUG',
  defaultValue: false,
);
