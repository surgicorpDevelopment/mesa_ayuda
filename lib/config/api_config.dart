import 'package:flutter/foundation.dart';

class ApiConfig {
  /// API raíz en producción (mismo dominio, sin subpath del frontend).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://appsurgicorperu.com',
  );

  /// Mock de tickets/proyectos para UI local sin GP_* en el servidor.
  /// - `flutter run` (debug): mock ON por defecto
  /// - `flutter build --release`: mock OFF
  /// Forzar: `--dart-define=USE_MOCK=true|false`
  static bool get useMock {
    const flag = String.fromEnvironment('USE_MOCK');
    if (flag == 'true') return true;
    if (flag == 'false') return false;
    return kDebugMode;
  }

  static const String tokenPath = '/api/token/';
  static const String refreshPath = '/api/token/refresh/';
  static const String usersPath = '/users/';
  static const String usuariosPath = '/GP_Usuario/';
  static const String perfilPath = '/GP_Usuario/me/';
  static const String proyectosPath = '/GP_Proyecto/';
  static const String ticketsPath = '/GP_Ticket/';
  static const String comentariosPath = '/GP_Comentario/';
  static const String historialPath = '/GP_HistorialEstado/';
  static const String inboxPath = '/GP_Ticket/inbox/';
  static const String sistemasPath = '/GP_Sistema/';
  static const String areasPath = '/EU_Area/';
  static const String tareasPath = '/GP_Tarea/';
  static const String productividadPath = '/GP_Productividad/';
}
