class AppUser {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final List<String> groups;
  final String? area;
  final int? areaId;
  final String? puesto;
  final bool isStaff;

  /// Rol efectivo calculado por el backend en `GET /GP_Usuario/me/`.
  /// Cuando viene, manda sobre la deducción local por grupos: así el frontend
  /// nunca muestra acciones que la API va a rechazar con 403.
  final bool? esGestor;
  final bool? esLider;
  final bool? esDesarrollador;

  const AppUser({
    required this.id,
    required this.username,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.groups = const [],
    this.area,
    this.areaId,
    this.puesto,
    this.isStaff = false,
    this.esGestor,
    this.esLider,
    this.esDesarrollador,
  });

  String get fullName {
    final n = '$firstName $lastName'.trim();
    return n.isEmpty ? username : n;
  }

  bool get isGestor =>
      esGestor ?? (isStaff || groups.contains('gp_gestor_proyectos'));

  bool get isLider => esLider ?? (isGestor || groups.contains('gp_lider_area'));

  bool get isDesarrollador =>
      esDesarrollador ?? (isLider || groups.contains('gp_desarrollador'));

  bool get canManageProyectos => isLider;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final groupsRaw = json['groups'];
    final groups = <String>[];
    if (groupsRaw is List) {
      for (final g in groupsRaw) {
        if (g is String) {
          // Puede ser URL .../groups/1/ o nombre
          if (g.contains('/groups/')) {
            continue;
          }
          groups.add(g);
        } else if (g is Map && g['name'] != null) {
          groups.add(g['name'] as String);
        }
      }
    }

    int? areaId;
    final areaIdRaw = json['area_id'];
    if (areaIdRaw is Map) {
      areaId = areaIdRaw['id'] as int?;
    } else if (areaIdRaw is int) {
      areaId = areaIdRaw;
    }

    String? nonEmpty(dynamic value) {
      if (value is! String) return null;
      final t = value.trim();
      return t.isEmpty ? null : t;
    }

    final puestoIdRaw = json['puesto_id'];
    final puestoFromId =
        puestoIdRaw is Map ? nonEmpty(puestoIdRaw['nombre']) : null;

    return AppUser(
      id: json['id'] as int,
      username: (json['username'] ?? '') as String,
      firstName: (json['first_name'] ?? '') as String,
      lastName: (json['last_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      groups: groups,
      // Preferir area_id.nombre: el campo plano `area` puede ser un valor legado distinto.
      area: (areaIdRaw is Map ? nonEmpty(areaIdRaw['nombre']) : null) ??
          nonEmpty(json['area']),
      areaId: areaId,
      // En prod el cargo está en puesto_id.nombre (/users/), no en un CharField puesto.
      puesto: nonEmpty(json['puesto']) ?? puestoFromId,
      isStaff: json['is_staff'] == true,
      esGestor: json['es_gestor'] as bool?,
      esLider: json['es_lider'] as bool?,
      esDesarrollador: json['es_desarrollador'] as bool?,
    );
  }
}
