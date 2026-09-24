/// Versión de la app Mesa de Ayuda.
///
/// Mantener alineado con `version:` en [pubspec.yaml]
/// (`1.0.1+2` → name `1.0.1`, build `2`).
class AppVersion {
  static const String name = '1.0.1';
  static const int build = 2;

  /// Etiqueta corta para UI: `v1.0.0`.
  static const String label = 'v$name';

  /// Con build: `v1.0.0 (1)`.
  static const String labelWithBuild = 'v$name ($build)';
}
