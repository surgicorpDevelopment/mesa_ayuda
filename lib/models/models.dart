class Proyecto {
  final int id;
  final String titulo;
  final String descripcion;
  final int? areaId;
  final String estado;
  final String prioridad;
  final int? responsableId;
  final String? responsableNombre;
  final int? creadoPorId;
  final DateTime? fechaObjetivo;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final int ticketsCount;
  final List<TicketAdjunto> adjuntos;

  const Proyecto({
    required this.id,
    required this.titulo,
    this.descripcion = '',
    this.areaId,
    this.estado = 'idea',
    this.prioridad = 'media',
    this.responsableId,
    this.responsableNombre,
    this.creadoPorId,
    this.fechaObjetivo,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.ticketsCount = 0,
    this.adjuntos = const [],
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    final resp = json['responsable_detail'];
    final adjRaw = json['adjuntos'];
    final adjuntos = <TicketAdjunto>[];
    if (adjRaw is List) {
      for (final a in adjRaw) {
        if (a is Map<String, dynamic>) adjuntos.add(TicketAdjunto.fromJson(a));
      }
    }
    return Proyecto(
      id: json['id'] as int,
      titulo: (json['titulo'] ?? '') as String,
      descripcion: (json['descripcion'] ?? '') as String,
      areaId: json['area_id'] as int?,
      estado: (json['estado'] ?? 'idea') as String,
      prioridad: (json['prioridad'] ?? 'media') as String,
      responsableId: json['responsable'] as int?,
      responsableNombre: resp is Map
          ? ((resp['full_name'] ?? resp['username']) as String?)
          : null,
      creadoPorId: json['creado_por'] as int?,
      fechaObjetivo: json['fecha_objetivo'] != null
          ? DateTime.tryParse(json['fecha_objetivo'] as String)
          : null,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'] as String)
          : null,
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.tryParse(json['fecha_actualizacion'] as String)
          : null,
      ticketsCount: (json['tickets_count'] as int?) ?? 0,
      adjuntos: adjuntos,
    );
  }

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descripcion': descripcion,
        'area_id': areaId,
        'estado': estado,
        'prioridad': prioridad,
        'responsable': responsableId,
        'fecha_objetivo': fechaObjetivo?.toIso8601String().split('T').first,
      };
}

class Ticket {
  final int id;
  final String titulo;
  final String descripcion;
  final int? areaId;
  final String sistemaAfectado;
  final String estado;
  final String prioridad;
  final String impacto;
  final int? reportadoPorId;
  final String? reportadoPorNombre;
  final int? asignadoAId;
  final String? asignadoANombre;
  final int? proyectoId;
  final String? proyectoTitulo;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final List<TicketAdjunto> adjuntos;

  const Ticket({
    required this.id,
    required this.titulo,
    this.descripcion = '',
    this.areaId,
    this.sistemaAfectado = '',
    this.estado = 'nuevo',
    this.prioridad = 'media',
    this.impacto = 'media',
    this.reportadoPorId,
    this.reportadoPorNombre,
    this.asignadoAId,
    this.asignadoANombre,
    this.proyectoId,
    this.proyectoTitulo,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.adjuntos = const [],
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final rep = json['reportado_por_detail'];
    final asg = json['asignado_a_detail'];
    final adjRaw = json['adjuntos'];
    final adjuntos = <TicketAdjunto>[];
    if (adjRaw is List) {
      for (final a in adjRaw) {
        if (a is Map<String, dynamic>) {
          adjuntos.add(TicketAdjunto.fromJson(a));
        }
      }
    }
    return Ticket(
      id: json['id'] as int,
      titulo: (json['titulo'] ?? '') as String,
      descripcion: (json['descripcion'] ?? '') as String,
      areaId: json['area_id'] as int?,
      sistemaAfectado: (json['sistema_afectado'] ?? '') as String,
      estado: (json['estado'] ?? 'nuevo') as String,
      prioridad: (json['prioridad'] ?? 'media') as String,
      impacto: (json['impacto'] ?? 'media') as String,
      reportadoPorId: json['reportado_por'] as int?,
      reportadoPorNombre: rep is Map
          ? ((rep['full_name'] ?? rep['username']) as String?)
          : null,
      asignadoAId: json['asignado_a'] as int?,
      asignadoANombre: asg is Map
          ? ((asg['full_name'] ?? asg['username']) as String?)
          : null,
      proyectoId: json['proyecto'] as int?,
      proyectoTitulo: json['proyecto_titulo'] as String?,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'] as String)
          : null,
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.tryParse(json['fecha_actualizacion'] as String)
          : null,
      adjuntos: adjuntos,
    );
  }

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descripcion': descripcion,
        'area_id': areaId,
        'sistema_afectado': sistemaAfectado,
        'estado': estado,
        'prioridad': prioridad,
        'impacto': impacto,
        'asignado_a': asignadoAId,
        'proyecto': proyectoId,
        'adjuntos': adjuntos.map((a) => a.toJson()).toList(),
      };
}

class TicketAdjunto {
  final String id;
  final String nombre;
  final String? mimeType;
  final int sizeBytes;
  /// Data URL (mock) o URL del servidor cuando exista backend.
  final String url;

  const TicketAdjunto({
    required this.id,
    required this.nombre,
    required this.url,
    this.mimeType,
    this.sizeBytes = 0,
  });

  factory TicketAdjunto.fromJson(Map<String, dynamic> json) => TicketAdjunto(
        id: (json['id'] ?? '').toString(),
        nombre: (json['nombre'] ?? 'captura.png') as String,
        url: (json['url'] ?? '') as String,
        mimeType: json['mime_type'] as String?,
        sizeBytes: (json['size_bytes'] as int?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'url': url,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
      };
}

class Comentario {
  final int id;
  final String tipo;
  final int refId;
  final int? autorId;
  final String? autorNombre;
  final String cuerpo;
  final DateTime? fechaCreacion;

  const Comentario({
    required this.id,
    required this.tipo,
    required this.refId,
    this.autorId,
    this.autorNombre,
    required this.cuerpo,
    this.fechaCreacion,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    final autor = json['autor_detail'];
    return Comentario(
      id: json['id'] as int,
      tipo: (json['tipo'] ?? '') as String,
      refId: json['ref_id'] as int,
      autorId: json['autor'] as int?,
      autorNombre: autor is Map
          ? ((autor['full_name'] ?? autor['username']) as String?)
          : null,
      cuerpo: (json['cuerpo'] ?? '') as String,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.tryParse(json['fecha_creacion'] as String)
          : null,
    );
  }
}

class InboxStats {
  final int misTicketsAbiertos;
  final int asignadosAMi;
  final int colaSinAsignar;
  final int proyectosActivos;

  const InboxStats({
    this.misTicketsAbiertos = 0,
    this.asignadosAMi = 0,
    this.colaSinAsignar = 0,
    this.proyectosActivos = 0,
  });

  factory InboxStats.fromJson(Map<String, dynamic> json) => InboxStats(
        misTicketsAbiertos: (json['mis_tickets_abiertos'] as int?) ?? 0,
        asignadosAMi: (json['asignados_a_mi'] as int?) ?? 0,
        colaSinAsignar: (json['cola_sin_asignar'] as int?) ?? 0,
        proyectosActivos: (json['proyectos_activos'] as int?) ?? 0,
      );
}

/// Tarea de avance dentro de un proyecto (tablero Kanban).
///
/// Estados: pendiente | en_progreso | hecho
class Tarea {
  final int id;
  final String titulo;
  final String descripcion;
  final String estado;
  final int? asignadoAId;
  final String? asignadoANombre;
  final int proyectoId;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  const Tarea({
    required this.id,
    required this.titulo,
    this.descripcion = '',
    this.estado = 'pendiente',
    this.asignadoAId,
    this.asignadoANombre,
    required this.proyectoId,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) => Tarea(
        id: json['id'] as int,
        titulo: (json['titulo'] ?? '') as String,
        descripcion: (json['descripcion'] ?? '') as String,
        estado: (json['estado'] ?? 'pendiente') as String,
        asignadoAId: json['asignado_a'] as int?,
        asignadoANombre: json['asignado_a_nombre'] as String?,
        proyectoId: json['proyecto'] as int,
        fechaCreacion: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        fechaActualizacion: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'descripcion': descripcion,
        'estado': estado,
        'asignado_a': asignadoAId,
        'proyecto': proyectoId,
      };
}

/// Área de la organización (catálogo para el selector en proyectos).
class AreaOption {
  final int id;
  final String nombre;

  const AreaOption({required this.id, required this.nombre});

  factory AreaOption.fromJson(Map<String, dynamic> json) {
    return AreaOption(
      id: json['id'] as int,
      nombre: (json['nombre'] ?? json['name'] ?? '') as String,
    );
  }
}

/// Usuario asignable a un ticket (catálogo ligero para el selector).
class AssignableUser {
  final int id;
  final String fullName;
  final String username;
  final String? rol;

  const AssignableUser({
    required this.id,
    required this.fullName,
    this.username = '',
    this.rol,
  });

  factory AssignableUser.fromJson(Map<String, dynamic> json) {
    final first = (json['first_name'] ?? '') as String;
    final last = (json['last_name'] ?? '') as String;
    final combined = '$first $last'.trim();
    final username = (json['username'] ?? '') as String;
    return AssignableUser(
      id: json['id'] as int,
      fullName: (json['full_name'] as String?)?.isNotEmpty == true
          ? json['full_name'] as String
          : (combined.isNotEmpty ? combined : username),
      username: username,
      rol: json['rol'] as String? ?? json['group'] as String?,
    );
  }
}

/// Fila del ranking de productividad.
class ProductividadRanking {
  final int userId;
  final String nombre;
  final int tareasHechas;
  final int ticketsResueltos;

  const ProductividadRanking({
    required this.userId,
    required this.nombre,
    this.tareasHechas = 0,
    this.ticketsResueltos = 0,
  });

  int get total => tareasHechas + ticketsResueltos;

  factory ProductividadRanking.fromJson(Map<String, dynamic> json) => ProductividadRanking(
        userId: json['user_id'] as int,
        nombre: (json['nombre'] ?? '') as String,
        tareasHechas: (json['tareas_hechas'] as int?) ?? 0,
        ticketsResueltos: (json['tickets_resueltos'] as int?) ?? 0,
      );
}

/// Evento del timeline de productividad.
class ProductividadEvento {
  final DateTime fecha;
  final int? usuarioId;
  final String? usuarioNombre;
  final String tipo; // ticket | tarea
  final int refId;
  final String titulo;
  final String estadoAnterior;
  final String estadoNuevo;

  const ProductividadEvento({
    required this.fecha,
    this.usuarioId,
    this.usuarioNombre,
    required this.tipo,
    required this.refId,
    required this.titulo,
    this.estadoAnterior = '',
    required this.estadoNuevo,
  });

  factory ProductividadEvento.fromJson(Map<String, dynamic> json) => ProductividadEvento(
        fecha: DateTime.tryParse((json['fecha'] ?? '') as String) ?? DateTime.now(),
        usuarioId: json['usuario_id'] as int?,
        usuarioNombre: json['usuario_nombre'] as String?,
        tipo: (json['tipo'] ?? '') as String,
        refId: json['ref_id'] as int,
        titulo: (json['titulo'] ?? '') as String,
        estadoAnterior: (json['estado_anterior'] ?? '') as String,
        estadoNuevo: (json['estado_nuevo'] ?? '') as String,
      );
}

/// Respuesta del endpoint de productividad.
class ProductividadReport {
  final List<ProductividadRanking> ranking;
  final List<ProductividadEvento> actividad;

  const ProductividadReport({
    this.ranking = const [],
    this.actividad = const [],
  });

  factory ProductividadReport.fromJson(Map<String, dynamic> json) {
    final rankingRaw = json['ranking'];
    final actividadRaw = json['actividad'];
    return ProductividadReport(
      ranking: rankingRaw is List
          ? rankingRaw
              .whereType<Map<String, dynamic>>()
              .map(ProductividadRanking.fromJson)
              .toList()
          : const [],
      actividad: actividadRaw is List
          ? actividadRaw
              .whereType<Map<String, dynamic>>()
              .map(ProductividadEvento.fromJson)
              .toList()
          : const [],
    );
  }
}
