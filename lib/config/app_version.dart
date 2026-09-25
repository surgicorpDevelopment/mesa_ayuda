/// Versión de la app Mesa de Ayuda.
///
/// Mantener alineado con `version:` en [pubspec.yaml]
/// (`1.1.2+5` → name `1.1.2`, build `5`).
class AppVersion {
  static const String name = '1.1.2';
  static const int build = 5;

  /// Etiqueta corta para UI: `v1.1.2`.
  static const String label = 'v$name';

  /// Con build: `v1.1.2 (5)`.
  static const String labelWithBuild = 'v$name ($build)';
}
