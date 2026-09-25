/// Versión de la app Mesa de Ayuda.
///
/// Mantener alineado con `version:` en [pubspec.yaml]
/// (`1.1.0+3` → name `1.1.0`, build `3`).
class AppVersion {
  static const String name = '1.1.0';
  static const int build = 3;

  /// Etiqueta corta para UI: `v1.1.0`.
  static const String label = 'v$name';

  /// Con build: `v1.1.0 (3)`.
  static const String labelWithBuild = 'v$name ($build)';
}
