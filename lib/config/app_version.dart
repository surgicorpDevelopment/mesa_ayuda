/// Versión de la app Mesa de Ayuda.
///
/// Mantener alineado con `version:` en [pubspec.yaml]
/// (`1.1.1+4` → name `1.1.1`, build `4`).
class AppVersion {
  static const String name = '1.1.1';
  static const int build = 4;

  /// Etiqueta corta para UI: `v1.1.1`.
  static const String label = 'v$name';

  /// Con build: `v1.1.1 (4)`.
  static const String labelWithBuild = 'v$name ($build)';
}
