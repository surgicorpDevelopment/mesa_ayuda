import '../models/models.dart';
import 'mock_attachment_assets.dart';

/// Datos en memoria para probar UI sin endpoints GP_* en el servidor.
class MockDataStore {
  MockDataStore() {
    _seed();
  }

  int _ticketSeq = 6;
  int _proyectoSeq = 3;
  int _comentarioSeq = 4;
  int _tareaSeq = 0;

  final List<Ticket> tickets = [];
  final List<Proyecto> proyectos = [];
  final List<Comentario> comentarios = [];
  final List<Tarea> tareas = [];
  final List<ProductividadEvento> historial = [];
  final List<AssignableUser> assignableUsers = [];
  final List<AreaOption> areas = const [
    AreaOption(id: 8,  nombre: 'Atenciones'),
    AreaOption(id: 12, nombre: 'Comercial'),
    AreaOption(id: 15, nombre: 'Desarrollo Software'),
    AreaOption(id: 22, nombre: 'Contabilidad'),
    AreaOption(id: 30, nombre: 'Logística'),
    AreaOption(id: 35, nombre: 'Recursos Humanos'),
    AreaOption(id: 40, nombre: 'Distribución'),
  ];

  void _seed() {
    final now = DateTime.now();
    assignableUsers.addAll(const [
      AssignableUser(
        id: 3,
        fullName: 'Jeshua Cabanillas',
        username: 'jcabanillas',
        rol: 'Desarrollador',
      ),
      AssignableUser(
        id: 12,
        fullName: 'Jairo Mendoza',
        username: 'jmendoza',
        rol: 'Desarrollador',
      ),
      AssignableUser(
        id: 15,
        fullName: 'María Torres',
        username: 'mtorres',
        rol: 'Líder de área',
      ),
      AssignableUser(
        id: 16,
        fullName: 'Luis Vargas',
        username: 'lvargas',
        rol: 'Desarrollador',
      ),
      AssignableUser(
        id: 17,
        fullName: 'Ana Quispe',
        username: 'aquispe',
        rol: 'Gestor de proyectos',
      ),
    ]);

    proyectos.addAll([
      Proyecto(
        id: 1,
        titulo: 'App de Cajas de traslado',
        descripcion: 'Escaneo y seguimiento de cajas entre almacenes.',
        areaId: 15,
        estado: 'en_proceso',
        prioridad: 'alta',
        responsableId: 3,
        responsableNombre: 'Jeshua Cabanillas',
        creadoPorId: 3,
        fechaInicio: now.subtract(const Duration(days: 18)),
        fechaObjetivo: now.subtract(const Duration(days: 2)),
        fechaCreacion: now.subtract(const Duration(days: 20)),
        fechaActualizacion: now.subtract(const Duration(hours: 5)),
        ticketsCount: 3,
      ),
      Proyecto(
        id: 2,
        titulo: 'Mejoras módulo Cotizaciones',
        descripcion: 'Arreglar pa_si_producto y flujo de adicionales.',
        areaId: 15,
        estado: 'idea',
        prioridad: 'media',
        responsableId: 3,
        responsableNombre: 'Jeshua Cabanillas',
        creadoPorId: 3,
        fechaInicio: now.add(const Duration(days: 10)),
        fechaObjetivo: now.add(const Duration(days: 50)),
        fechaCreacion: now.subtract(const Duration(days: 7)),
        fechaActualizacion: now.subtract(const Duration(days: 1)),
        ticketsCount: 2,
      ),
      Proyecto(
        id: 3,
        titulo: 'Portal vacaciones v2',
        descripcion: 'Rediseño UX y reportes para RRHH.',
        areaId: 15,
        estado: 'completado',
        prioridad: 'baja',
        responsableId: 12,
        responsableNombre: 'Jairo Mendoza',
        creadoPorId: 3,
        fechaInicio: now.subtract(const Duration(days: 55)),
        fechaObjetivo: now.subtract(const Duration(days: 14)),
        fechaCreacion: now.subtract(const Duration(days: 60)),
        fechaActualizacion: now.subtract(const Duration(days: 14)),
        ticketsCount: 1,
      ),
    ]);

    tickets.addAll([
      Ticket(
        id: 1,
        titulo: 'Error al escanear cajas de traslado',
        descripcion: 'En PDA a veces no lee el QR y queda en blanco.',
        areaId: 15,
        sistemaAfectado: 'hoja_picking',
        estado: 'en_proceso',
        prioridad: 'alta',
        impacto: 'alta',
        reportadoPorId: 10,
        reportadoPorNombre: 'Carlos López',
        asignadoAId: 3,
        asignadoANombre: 'Jeshua Cabanillas',
        proyectoId: 1,
        proyectoTitulo: 'App de Cajas de traslado',
        fechaCreacion: now.subtract(const Duration(days: 3)),
        fechaActualizacion: now.subtract(const Duration(hours: 2)),
        adjuntos: const [
          TicketAdjunto(
            id: 'mock_att_1',
            nombre: 'pda_scan_fail.png',
            url: mockImgPdaScan,
            mimeType: 'image/png',
            sizeBytes: mockImgPdaScanBytes,
          ),
          TicketAdjunto(
            id: 'mock_att_2',
            nombre: 'pantalla_en_blanco.png',
            url: mockImgQrBlank,
            mimeType: 'image/png',
            sizeBytes: mockImgQrBlankBytes,
          ),
        ],
      ),
      Ticket(
        id: 2,
        titulo: 'Averiguar conexión API empresa de transporte',
        descripcion: 'Necesitamos validar endpoints de tracking.',
        areaId: 15,
        sistemaAfectado: 'erp',
        estado: 'nuevo',
        prioridad: 'media',
        impacto: 'media',
        reportadoPorId: 11,
        reportadoPorNombre: 'Fernando Ruiz',
        asignadoAId: null,
        asignadoANombre: null,
        proyectoId: 1,
        proyectoTitulo: 'App de Cajas de traslado',
        fechaCreacion: now.subtract(const Duration(days: 1)),
        fechaActualizacion: now.subtract(const Duration(days: 1)),
      ),
      Ticket(
        id: 3,
        titulo: 'Arreglar pa_si_producto en cotizaciones',
        descripcion: 'Al confirmar adicionales el status no cambia a Guía generada.',
        areaId: 15,
        sistemaAfectado: 'cotizaciones',
        estado: 'esperando',
        prioridad: 'alta',
        impacto: 'media',
        reportadoPorId: 3,
        reportadoPorNombre: 'Jeshua Cabanillas',
        asignadoAId: 3,
        asignadoANombre: 'Jeshua Cabanillas',
        proyectoId: 2,
        proyectoTitulo: 'Mejoras módulo Cotizaciones',
        fechaCreacion: now.subtract(const Duration(hours: 10)),
        fechaActualizacion: now.subtract(const Duration(hours: 1)),
        adjuntos: const [
          TicketAdjunto(
            id: 'mock_att_3',
            nombre: 'cotizacion_status.png',
            url: mockImgAlmacen,
            mimeType: 'image/png',
            sizeBytes: mockImgAlmacenBytes,
          ),
        ],
      ),
      Ticket(
        id: 4,
        titulo: 'Impresión etiqueta A4 falla en 2do piso',
        descripcion: 'Cola de impresión se queda en cola sin enviar a la impresora.',
        areaId: 15,
        sistemaAfectado: 'hoja_picking',
        estado: 'resuelto',
        prioridad: 'media',
        impacto: 'alta',
        reportadoPorId: 10,
        reportadoPorNombre: 'Carlos López',
        asignadoAId: 3,
        asignadoANombre: 'Jeshua Cabanillas',
        proyectoId: 1,
        proyectoTitulo: 'App de Cajas de traslado',
        fechaCreacion: now.subtract(const Duration(days: 12)),
        fechaActualizacion: now.subtract(const Duration(days: 5)),
      ),
      Ticket(
        id: 5,
        titulo: 'Exportar Excel de cotizaciones pendientes',
        descripcion: 'Solicitud de export diario para el área comercial.',
        areaId: 15,
        sistemaAfectado: 'cotizaciones',
        estado: 'cerrado',
        prioridad: 'baja',
        impacto: 'baja',
        reportadoPorId: 11,
        reportadoPorNombre: 'Fernando Ruiz',
        asignadoAId: 12,
        asignadoANombre: 'Jairo Mendoza',
        proyectoId: 2,
        proyectoTitulo: 'Mejoras módulo Cotizaciones',
        fechaCreacion: now.subtract(const Duration(days: 30)),
        fechaActualizacion: now.subtract(const Duration(days: 20)),
      ),
      Ticket(
        id: 6,
        titulo: 'Corregir cálculo de días hábiles en vacaciones',
        descripcion: 'Feriados locales no se restaban correctamente.',
        areaId: 15,
        sistemaAfectado: 'vacaciones',
        estado: 'cerrado',
        prioridad: 'alta',
        impacto: 'media',
        reportadoPorId: 13,
        reportadoPorNombre: 'Ana Torres',
        asignadoAId: 12,
        asignadoANombre: 'Jairo Mendoza',
        proyectoId: 3,
        proyectoTitulo: 'Portal vacaciones v2',
        fechaCreacion: now.subtract(const Duration(days: 45)),
        fechaActualizacion: now.subtract(const Duration(days: 15)),
      ),
      // Cola helpdesk: otras áreas, sin asignar
      Ticket(
        id: 7,
        titulo: 'No imprime boleta en caja 3',
        descripcion: 'Al confirmar venta la impresora no responde. Área Contabilidad.',
        areaId: 22,
        sistemaAfectado: 'facturacion',
        estado: 'nuevo',
        prioridad: 'alta',
        impacto: 'alta',
        reportadoPorId: 20,
        reportadoPorNombre: 'Rosa Paredes',
        asignadoAId: null,
        asignadoANombre: null,
        fechaCreacion: now.subtract(const Duration(hours: 4)),
        fechaActualizacion: now.subtract(const Duration(hours: 4)),
      ),
      Ticket(
        id: 8,
        titulo: 'App de atenciones no carga pacientes',
        descripcion: 'Timeout al buscar por DNI. Área Atenciones.',
        areaId: 8,
        sistemaAfectado: 'power_apps',
        estado: 'nuevo',
        prioridad: 'media',
        impacto: 'alta',
        reportadoPorId: 21,
        reportadoPorNombre: 'Pedro Salas',
        asignadoAId: null,
        asignadoANombre: null,
        fechaCreacion: now.subtract(const Duration(hours: 1)),
        fechaActualizacion: now.subtract(const Duration(hours: 1)),
      ),
    ]);
    _ticketSeq = 8;

    comentarios.addAll([
      Comentario(
        id: 1,
        tipo: 'ticket',
        refId: 1,
        autorId: 10,
        autorNombre: 'Carlos López',
        cuerpo: 'Pasa sobre todo en el almacén principal, turno mañana.',
        fechaCreacion: now.subtract(const Duration(days: 2)),
      ),
      Comentario(
        id: 2,
        tipo: 'ticket',
        refId: 1,
        autorId: 3,
        autorNombre: 'Jeshua Cabanillas',
        cuerpo: 'Reproduje el bug; estoy revisando el scanner.',
        fechaCreacion: now.subtract(const Duration(hours: 6)),
      ),
      Comentario(
        id: 3,
        tipo: 'proyecto',
        refId: 1,
        autorId: 3,
        autorNombre: 'Jeshua Cabanillas',
        cuerpo: 'Prioridad alta para esta semana.',
        fechaCreacion: now.subtract(const Duration(days: 4)),
      ),
      Comentario(
        id: 4,
        tipo: 'ticket',
        refId: 4,
        autorId: 3,
        autorNombre: 'Jeshua Cabanillas',
        cuerpo: 'Reinicio de cola y driver; cerrado.',
        fechaCreacion: now.subtract(const Duration(days: 5)),
      ),
    ]);

    // ── Tareas por proyecto ──────────────────────────────────────────────
    // Proyecto 1: App de Cajas de traslado
    tareas.addAll([
      Tarea(
        id: ++_tareaSeq,
        titulo: 'Diseñar pantalla de escaneo QR',
        descripcion: 'Wireframes y UI del flujo principal de escaneo.',
        estado: 'hecho',
        asignadoAId: 3,
        asignadoANombre: 'Jeshua Cabanillas',
        proyectoId: 1,
        fechaCreacion: now.subtract(const Duration(days: 18)),
        fechaActualizacion: now.subtract(const Duration(days: 12)),
      ),
      Tarea(
        id: ++_tareaSeq,
        titulo: 'Integrar lector de códigos QR/barras',
        descripcion: 'Usar plugin mobile_scanner y adaptar a PDA Zebra.',
        estado: 'en_progreso',
        asignadoAId: 12,
        asignadoANombre: 'Jairo Mendoza',
        proyectoId: 1,
        fechaCreacion: now.subtract(const Duration(days: 10)),
        fechaActualizacion: now.subtract(const Duration(days: 2)),
      ),
      Tarea(
        id: ++_tareaSeq,
        titulo: 'Pruebas en PDA Zebra TC21',
        descripcion: 'Validar velocidad de escaneo y flujo offline.',
        estado: 'pendiente',
        proyectoId: 1,
        fechaCreacion: now.subtract(const Duration(days: 5)),
        fechaActualizacion: now.subtract(const Duration(days: 5)),
      ),
      Tarea(
        id: ++_tareaSeq,
        titulo: 'Documentar API de movimiento de cajas',
        estado: 'pendiente',
        proyectoId: 1,
        fechaCreacion: now.subtract(const Duration(days: 3)),
        fechaActualizacion: now.subtract(const Duration(days: 3)),
      ),
    ]);

    // Proyecto 2: Mejoras módulo Cotizaciones
    tareas.addAll([
      Tarea(
        id: ++_tareaSeq,
        titulo: 'Revisar lógica pa_si_producto',
        descripcion: 'Trazar el flujo de adicionales y localizar el bug de status.',
        estado: 'en_progreso',
        asignadoAId: 3,
        asignadoANombre: 'Jeshua Cabanillas',
        proyectoId: 2,
        fechaCreacion: now.subtract(const Duration(days: 6)),
        fechaActualizacion: now.subtract(const Duration(hours: 3)),
      ),
      Tarea(
        id: ++_tareaSeq,
        titulo: 'Corregir status "Guía generada"',
        estado: 'pendiente',
        proyectoId: 2,
        fechaCreacion: now.subtract(const Duration(days: 4)),
        fechaActualizacion: now.subtract(const Duration(days: 4)),
      ),
      Tarea(
        id: ++_tareaSeq,
        titulo: 'Tests unitarios del módulo',
        estado: 'pendiente',
        proyectoId: 2,
        fechaCreacion: now.subtract(const Duration(days: 2)),
        fechaActualizacion: now.subtract(const Duration(days: 2)),
      ),
    ]);

    // Proyecto 3: Portal vacaciones v2
    tareas.addAll([
      Tarea(
        id: ++_tareaSeq,
        titulo: 'Rediseño UX del portal',
        descripcion: 'Nuevas pantallas Figma aprobadas por RRHH.',
        estado: 'hecho',
        asignadoAId: 12,
        asignadoANombre: 'Jairo Mendoza',
        proyectoId: 3,
        fechaCreacion: now.subtract(const Duration(days: 55)),
        fechaActualizacion: now.subtract(const Duration(days: 30)),
      ),
      Tarea(
        id: ++_tareaSeq,
        titulo: 'Reportes de vacaciones para RRHH',
        estado: 'hecho',
        asignadoAId: 12,
        asignadoANombre: 'Jairo Mendoza',
        proyectoId: 3,
        fechaCreacion: now.subtract(const Duration(days: 40)),
        fechaActualizacion: now.subtract(const Duration(days: 15)),
      ),
    ]);

    // Historial de productividad (quién cambió a qué estado y cuándo)
    historial.addAll([
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 12)),
        usuarioId: 3,
        usuarioNombre: 'Jeshua Cabanillas',
        tipo: 'tarea',
        refId: 1,
        titulo: 'Diseñar pantalla de escaneo QR',
        estadoAnterior: 'en_progreso',
        estadoNuevo: 'hecho',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 5)),
        usuarioId: 3,
        usuarioNombre: 'Jeshua Cabanillas',
        tipo: 'ticket',
        refId: 4,
        titulo: 'Impresión etiqueta A4 falla en 2do piso',
        estadoAnterior: 'en_proceso',
        estadoNuevo: 'resuelto',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 2)),
        usuarioId: 12,
        usuarioNombre: 'Jairo Mendoza',
        tipo: 'tarea',
        refId: 2,
        titulo: 'Integrar lector de códigos QR/barras',
        estadoAnterior: 'pendiente',
        estadoNuevo: 'en_progreso',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 15)),
        usuarioId: 12,
        usuarioNombre: 'Jairo Mendoza',
        tipo: 'tarea',
        refId: 9,
        titulo: 'Reportes de vacaciones para RRHH',
        estadoAnterior: 'en_progreso',
        estadoNuevo: 'hecho',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 30)),
        usuarioId: 12,
        usuarioNombre: 'Jairo Mendoza',
        tipo: 'tarea',
        refId: 8,
        titulo: 'Rediseño UX del portal',
        estadoAnterior: 'en_progreso',
        estadoNuevo: 'hecho',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 20)),
        usuarioId: 12,
        usuarioNombre: 'Jairo Mendoza',
        tipo: 'ticket',
        refId: 5,
        titulo: 'Exportar Excel de cotizaciones pendientes',
        estadoAnterior: 'resuelto',
        estadoNuevo: 'cerrado',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 15)),
        usuarioId: 12,
        usuarioNombre: 'Jairo Mendoza',
        tipo: 'ticket',
        refId: 6,
        titulo: 'Corregir cálculo de días hábiles en vacaciones',
        estadoAnterior: 'resuelto',
        estadoNuevo: 'cerrado',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(hours: 3)),
        usuarioId: 3,
        usuarioNombre: 'Jeshua Cabanillas',
        tipo: 'tarea',
        refId: 5,
        titulo: 'Revisar lógica pa_si_producto',
        estadoAnterior: 'pendiente',
        estadoNuevo: 'en_progreso',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(hours: 2)),
        usuarioId: 3,
        usuarioNombre: 'Jeshua Cabanillas',
        tipo: 'ticket',
        refId: 1,
        titulo: 'Error al escanear cajas de traslado',
        estadoAnterior: 'nuevo',
        estadoNuevo: 'en_proceso',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 1)),
        usuarioId: 16,
        usuarioNombre: 'Luis Vargas',
        tipo: 'ticket',
        refId: 3,
        titulo: 'Arreglar pa_si_producto en cotizaciones',
        estadoAnterior: 'nuevo',
        estadoNuevo: 'esperando',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 3)),
        usuarioId: 10,
        usuarioNombre: 'Carlos López',
        tipo: 'ticket',
        refId: 1,
        titulo: 'Error al escanear cajas de traslado',
        estadoAnterior: '',
        estadoNuevo: 'nuevo',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 20)),
        usuarioId: 3,
        usuarioNombre: 'Jeshua Cabanillas',
        tipo: 'proyecto',
        refId: 1,
        titulo: 'App de Cajas de traslado',
        estadoAnterior: '',
        estadoNuevo: 'idea',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 18)),
        usuarioId: 3,
        usuarioNombre: 'Jeshua Cabanillas',
        tipo: 'proyecto',
        refId: 1,
        titulo: 'App de Cajas de traslado',
        estadoAnterior: 'idea',
        estadoNuevo: 'planificado',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 16)),
        usuarioId: 3,
        usuarioNombre: 'Jeshua Cabanillas',
        tipo: 'proyecto',
        refId: 1,
        titulo: 'App de Cajas de traslado',
        estadoAnterior: 'planificado',
        estadoNuevo: 'en_proceso',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 7)),
        usuarioId: 3,
        usuarioNombre: 'Jeshua Cabanillas',
        tipo: 'proyecto',
        refId: 2,
        titulo: 'Mejoras módulo Cotizaciones',
        estadoAnterior: '',
        estadoNuevo: 'idea',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 60)),
        usuarioId: 3,
        usuarioNombre: 'Jeshua Cabanillas',
        tipo: 'proyecto',
        refId: 3,
        titulo: 'Portal vacaciones v2',
        estadoAnterior: '',
        estadoNuevo: 'idea',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 50)),
        usuarioId: 3,
        usuarioNombre: 'Jeshua Cabanillas',
        tipo: 'proyecto',
        refId: 3,
        titulo: 'Portal vacaciones v2',
        estadoAnterior: 'idea',
        estadoNuevo: 'en_proceso',
      ),
      ProductividadEvento(
        fecha: now.subtract(const Duration(days: 14)),
        usuarioId: 12,
        usuarioNombre: 'Jairo Mendoza',
        tipo: 'proyecto',
        refId: 3,
        titulo: 'Portal vacaciones v2',
        estadoAnterior: 'en_proceso',
        estadoNuevo: 'completado',
      ),
    ]);
  }

  /// Igual que la acción `inbox` del backend: la cola solo cuenta para
  /// desarrolladores y los proyectos activos se cuentan sobre los visibles.
  InboxStats inbox({
    required int userId,
    int? userAreaId,
    bool isGestor = false,
    bool isLider = false,
    bool isDesarrollador = false,
  }) {
    final misAbiertos = tickets
        .where((t) =>
            t.reportadoPorId == userId &&
            t.estado != 'resuelto' &&
            t.estado != 'cerrado')
        .length;
    final asignados = tickets
        .where((t) =>
            t.asignadoAId == userId &&
            t.estado != 'resuelto' &&
            t.estado != 'cerrado')
        .length;
    final colaSinAsignar = isDesarrollador
        ? tickets.where(_esColaSinAsignar).length
        : 0;
    final proyectosActivos = _visibleProyectos(
      userId: userId,
      userAreaId: userAreaId,
      isGestor: isGestor,
      isLider: isLider,
      isDesarrollador: isDesarrollador,
    ).where((p) => p.estado != 'completado' && p.estado != 'cancelado').length;
    return InboxStats(
      misTicketsAbiertos: misAbiertos,
      asignadosAMi: asignados,
      colaSinAsignar: colaSinAsignar,
      proyectosActivos: proyectosActivos,
    );
  }

  /// Equivalente a `Q_COLA_SIN_ASIGNAR` del backend.
  bool _esColaSinAsignar(Ticket t) =>
      t.asignadoAId == null && t.estado != 'resuelto' && t.estado != 'cerrado';

  /// Replica la lógica de visibilidad del backend Django.
  ///
  /// - [isGestor]      → ve todos los tickets (gestor/staff)
  /// - [isDesarrollador] → ve los suyos (reportados o asignados) + sin asignar
  /// - usuario genérico → solo los que él mismo reportó
  List<Ticket> listTickets(
    Map<String, String>? filters, {
    required int userId,
    required int? userAreaId,
    bool isGestor = false,
    bool isDesarrollador = false,
  }) {
    var list = List<Ticket>.from(tickets);

    // ── Visibilidad por rol (igual que el queryset del backend) ──────────
    if (!isGestor) {
      if (isDesarrollador) {
        // Asignados a mí | reportados por mí | sin asignar (cola abierta)
        // + los del área propia si la tiene
        list = list.where((t) {
          if (t.asignadoAId == userId) return true;
          if (t.reportadoPorId == userId) return true;
          if (_esColaSinAsignar(t)) return true;
          if (userAreaId != null && t.areaId == userAreaId) return true;
          return false;
        }).toList();
      } else {
        // Usuario final: solo lo que él reportó
        list = list.where((t) => t.reportadoPorId == userId).toList();
      }
    }

    // ── Filtros adicionales (estado, asignado, proyecto, etc.) ───────────
    if (filters != null) {
      if (filters['estado'] != null) {
        list = list.where((t) => t.estado == filters['estado']).toList();
      }
      if (filters['asignado_a'] != null) {
        final id = int.tryParse(filters['asignado_a']!);
        list = list.where((t) => t.asignadoAId == id).toList();
      }
      if (filters['unassigned'] == '1') {
        list = list.where(_esColaSinAsignar).toList();
      }
      if (filters['proyecto'] != null) {
        final id = int.tryParse(filters['proyecto']!);
        list = list.where((t) => t.proyectoId == id).toList();
      }
    }

    return list;
  }

  Ticket getTicket(int id) {
    return tickets.firstWhere(
      (t) => t.id == id,
      orElse: () => throw StateError('Ticket $id no encontrado'),
    );
  }

  void deleteTicket(int id) {
    final existed = tickets.any((t) => t.id == id);
    if (!existed) throw StateError('Ticket $id no encontrado');
    tickets.removeWhere((t) => t.id == id);
    comentarios.removeWhere((c) => c.tipo == 'ticket' && c.refId == id);
    historial.removeWhere((e) => e.tipo == 'ticket' && e.refId == id);
  }

  Ticket createTicket(Map<String, dynamic> body, {required int userId, required String userName}) {
    _ticketSeq += 1;
    final adjuntos = <TicketAdjunto>[];
    final raw = body['adjuntos'];
    if (raw is List) {
      for (final a in raw) {
        if (a is Map<String, dynamic>) {
          adjuntos.add(TicketAdjunto.fromJson(a));
        } else if (a is TicketAdjunto) {
          adjuntos.add(a);
        }
      }
    }
    final t = Ticket(
      id: _ticketSeq,
      titulo: (body['titulo'] ?? '') as String,
      descripcion: (body['descripcion'] ?? '') as String,
      areaId: body['area_id'] as int?,
      sistemaAfectado: (body['sistema_afectado'] ?? '') as String,
      estado: (body['estado'] ?? 'nuevo') as String,
      prioridad: (body['prioridad'] ?? 'media') as String,
      impacto: (body['impacto'] ?? 'media') as String,
      reportadoPorId: userId,
      reportadoPorNombre: userName,
      asignadoAId: body['asignado_a'] as int?,
      proyectoId: body['proyecto'] as int?,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
      adjuntos: adjuntos,
    );
    tickets.insert(0, t);
    _recordHistorial(
      tipo: 'ticket',
      refId: t.id,
      titulo: t.titulo,
      estadoAnterior: '',
      estadoNuevo: t.estado,
      usuarioId: userId,
      usuarioNombre: userName,
    );
    return t;
  }

  List<AreaOption> listAreas() => List<AreaOption>.from(areas);

  List<AssignableUser> listAssignableUsers({String? query}) {
    var list = List<AssignableUser>.from(assignableUsers);
    final q = query?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      list = list
          .where(
            (u) =>
                u.fullName.toLowerCase().contains(q) ||
                u.username.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  String? nameForUser(int? userId) {
    if (userId == null) return null;
    for (final u in assignableUsers) {
      if (u.id == userId) return u.fullName;
    }
    return null;
  }

  Ticket updateTicket(
    int id,
    Map<String, dynamic> body, {
    String? assignName,
    int? actorId,
    String? actorName,
  }) {
    final i = tickets.indexWhere((t) => t.id == id);
    if (i < 0) throw StateError('Ticket $id no encontrado');
    final cur = tickets[i];
    final newAsignadoId =
        body.containsKey('asignado_a') ? body['asignado_a'] as int? : cur.asignadoAId;
    String? newAsignadoNombre = cur.asignadoANombre;
    if (body.containsKey('asignado_a')) {
      if (newAsignadoId == null) {
        newAsignadoNombre = null;
      } else {
        newAsignadoNombre =
            assignName ?? nameForUser(newAsignadoId) ?? 'Usuario #$newAsignadoId';
      }
    }
    final updated = Ticket(
      id: cur.id,
      titulo: (body['titulo'] as String?) ?? cur.titulo,
      descripcion: (body['descripcion'] as String?) ?? cur.descripcion,
      areaId: body.containsKey('area_id') ? body['area_id'] as int? : cur.areaId,
      sistemaAfectado: (body['sistema_afectado'] as String?) ?? cur.sistemaAfectado,
      estado: (body['estado'] as String?) ?? cur.estado,
      prioridad: (body['prioridad'] as String?) ?? cur.prioridad,
      impacto: (body['impacto'] as String?) ?? cur.impacto,
      reportadoPorId: cur.reportadoPorId,
      reportadoPorNombre: cur.reportadoPorNombre,
      asignadoAId: newAsignadoId,
      asignadoANombre: newAsignadoNombre,
      proyectoId: body.containsKey('proyecto') ? body['proyecto'] as int? : cur.proyectoId,
      proyectoTitulo: cur.proyectoTitulo,
      fechaCreacion: cur.fechaCreacion,
      fechaActualizacion: DateTime.now(),
      adjuntos: body.containsKey('adjuntos')
          ? _parseAdjuntos(body['adjuntos'])
          : cur.adjuntos,
    );
    tickets[i] = updated;
    if (cur.estado != updated.estado) {
      _recordHistorial(
        tipo: 'ticket',
        refId: updated.id,
        titulo: updated.titulo,
        estadoAnterior: cur.estado,
        estadoNuevo: updated.estado,
        usuarioId: actorId ?? updated.asignadoAId,
        usuarioNombre: actorName ?? assignName ?? updated.asignadoANombre,
      );
    }
    return updated;
  }

  /// Asigna el ticket al usuario y pasa a en_proceso si estaba nuevo.
  Ticket takeTicket(int id, {required int userId, required String userName}) {
    final cur = getTicket(id);
    if (cur.asignadoAId != null) {
      throw StateError('El ticket ya está asignado');
    }
    return updateTicket(
      id,
      {
        'asignado_a': userId,
        if (cur.estado == 'nuevo') 'estado': 'en_proceso',
      },
      assignName: userName,
      actorId: userId,
      actorName: userName,
    );
  }

  List<TicketAdjunto> _parseAdjuntos(dynamic raw) {
    final adjuntos = <TicketAdjunto>[];
    if (raw is List) {
      for (final a in raw) {
        if (a is Map<String, dynamic>) {
          adjuntos.add(TicketAdjunto.fromJson(a));
        } else if (a is Map) {
          adjuntos.add(TicketAdjunto.fromJson(Map<String, dynamic>.from(a)));
        } else if (a is TicketAdjunto) {
          adjuntos.add(a);
        }
      }
    }
    return adjuntos;
  }

  /// Replica `visible_proyectos` del backend.
  List<Proyecto> _visibleProyectos({
    required int userId,
    required int? userAreaId,
    bool isGestor = false,
    bool isLider = false,
    bool isDesarrollador = false,
  }) {
    if (isGestor) return List<Proyecto>.from(proyectos);
    if (isLider && userAreaId != null) {
      return proyectos
          .where((p) =>
              p.areaId == userAreaId ||
              p.responsableId == userId ||
              p.creadoPorId == userId)
          .toList();
    }
    if (isDesarrollador) {
      return proyectos
          .where((p) =>
              p.responsableId == userId ||
              (userAreaId != null && p.areaId == userAreaId))
          .toList();
    }
    return const [];
  }

  List<Proyecto> listProyectos(
    Map<String, String>? filters, {
    required int userId,
    required int? userAreaId,
    bool isGestor = false,
    bool isLider = false,
    bool isDesarrollador = false,
  }) {
    var list = _visibleProyectos(
      userId: userId,
      userAreaId: userAreaId,
      isGestor: isGestor,
      isLider: isLider,
      isDesarrollador: isDesarrollador,
    );
    if (filters?['estado'] != null) {
      list = list.where((p) => p.estado == filters!['estado']).toList();
    }
    return list;
  }

  Proyecto getProyecto(int id) {
    return proyectos.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('Proyecto $id no encontrado'),
    );
  }

  Proyecto createProyecto(Map<String, dynamic> body, {required int userId, required String userName}) {
    _proyectoSeq += 1;
    final responsableId = (body['responsable'] as int?) ?? userId;
    final responsableNombre = responsableId == userId
        ? userName
        : (nameForUser(responsableId) ?? 'Usuario #$responsableId');
    final p = Proyecto(
      id: _proyectoSeq,
      titulo: (body['titulo'] ?? '') as String,
      descripcion: (body['descripcion'] ?? '') as String,
      areaId: body['area_id'] as int?,
      estado: (body['estado'] ?? 'idea') as String,
      prioridad: (body['prioridad'] ?? 'media') as String,
      responsableId: responsableId,
      responsableNombre: responsableNombre,
      creadoPorId: userId,
      fechaInicio: _parseDate(body['fecha_inicio']),
      fechaObjetivo: _parseDate(body['fecha_objetivo']),
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    proyectos.insert(0, p);
    _recordHistorial(
      tipo: 'proyecto',
      refId: p.id,
      titulo: p.titulo,
      estadoAnterior: '',
      estadoNuevo: p.estado,
      usuarioId: userId,
      usuarioNombre: userName,
    );
    return p;
  }

  Proyecto updateProyecto(
    int id,
    Map<String, dynamic> body, {
    int? actorId,
    String? actorName,
  }) {
    final i = proyectos.indexWhere((p) => p.id == id);
    if (i < 0) throw StateError('Proyecto $id no encontrado');
    final cur = proyectos[i];
    final newResponsableId =
        body.containsKey('responsable') ? body['responsable'] as int? : cur.responsableId;
    final newResponsableNombre = body.containsKey('responsable')
        ? (newResponsableId == null
            ? null
            : (nameForUser(newResponsableId) ?? 'Usuario #$newResponsableId'))
        : cur.responsableNombre;
    final updated = Proyecto(
      id: cur.id,
      titulo: (body['titulo'] as String?) ?? cur.titulo,
      descripcion: (body['descripcion'] as String?) ?? cur.descripcion,
      areaId: body.containsKey('area_id') ? body['area_id'] as int? : cur.areaId,
      estado: (body['estado'] as String?) ?? cur.estado,
      prioridad: (body['prioridad'] as String?) ?? cur.prioridad,
      responsableId: newResponsableId,
      responsableNombre: newResponsableNombre,
      creadoPorId: cur.creadoPorId,
      fechaInicio: body.containsKey('fecha_inicio') ? _parseDate(body['fecha_inicio']) : cur.fechaInicio,
      fechaObjetivo: body.containsKey('fecha_objetivo')
          ? _parseDate(body['fecha_objetivo'])
          : cur.fechaObjetivo,
      fechaCreacion: cur.fechaCreacion,
      fechaActualizacion: DateTime.now(),
      ticketsCount: tickets.where((t) => t.proyectoId == id).length,
      adjuntos: body.containsKey('adjuntos')
          ? _parseAdjuntos(body['adjuntos'])
          : cur.adjuntos,
    );
    proyectos[i] = updated;
    if (cur.estado != updated.estado) {
      _recordHistorial(
        tipo: 'proyecto',
        refId: updated.id,
        titulo: updated.titulo,
        estadoAnterior: cur.estado,
        estadoNuevo: updated.estado,
        usuarioId: actorId,
        usuarioNombre: actorName,
      );
    }
    return updated;
  }

  void deleteProyecto(int id) {
    final existed = proyectos.any((p) => p.id == id);
    if (!existed) throw StateError('Proyecto $id no encontrado');
    final tareaIds = tareas.where((t) => t.proyectoId == id).map((t) => t.id).toSet();
    proyectos.removeWhere((p) => p.id == id);
    tareas.removeWhere((t) => t.proyectoId == id);
    // Tickets vinculados: se desvinculan (como SET_NULL en backend).
    for (var i = 0; i < tickets.length; i++) {
      final t = tickets[i];
      if (t.proyectoId == id) {
        tickets[i] = Ticket(
          id: t.id,
          titulo: t.titulo,
          descripcion: t.descripcion,
          areaId: t.areaId,
          sistemaAfectado: t.sistemaAfectado,
          estado: t.estado,
          prioridad: t.prioridad,
          impacto: t.impacto,
          reportadoPorId: t.reportadoPorId,
          reportadoPorNombre: t.reportadoPorNombre,
          asignadoAId: t.asignadoAId,
          asignadoANombre: t.asignadoANombre,
          proyectoId: null,
          proyectoTitulo: null,
          fechaCreacion: t.fechaCreacion,
          fechaActualizacion: t.fechaActualizacion,
          adjuntos: t.adjuntos,
        );
      }
    }
    comentarios.removeWhere(
      (c) =>
          (c.tipo == 'proyecto' && c.refId == id) ||
          (c.tipo == 'tarea' && tareaIds.contains(c.refId)),
    );
    historial.removeWhere(
      (e) =>
          (e.tipo == 'proyecto' && e.refId == id) ||
          (e.tipo == 'tarea' && tareaIds.contains(e.refId)),
    );
  }

  List<Comentario> listComentarios(String tipo, int refId) {
    return comentarios.where((c) => c.tipo == tipo && c.refId == refId).toList();
  }

  Comentario createComentario(String tipo, int refId, String cuerpo, {required int userId, required String userName}) {
    _comentarioSeq += 1;
    final c = Comentario(
      id: _comentarioSeq,
      tipo: tipo,
      refId: refId,
      autorId: userId,
      autorNombre: userName,
      cuerpo: cuerpo,
      fechaCreacion: DateTime.now(),
    );
    comentarios.add(c);
    return c;
  }

  List<HistorialEstado> listHistorial(String tipo, int refId) {
    final items = historial.where((e) => e.tipo == tipo && e.refId == refId).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    return [
      for (var i = 0; i < items.length; i++)
        HistorialEstado(
          id: i + 1,
          tipo: items[i].tipo,
          refId: items[i].refId,
          estadoAnterior: items[i].estadoAnterior,
          estadoNuevo: items[i].estadoNuevo,
          usuarioId: items[i].usuarioId,
          usuarioNombre: items[i].usuarioNombre,
          fecha: items[i].fecha,
        ),
    ];
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  // ── Tareas ────────────────────────────────────────────────────────────

  List<Tarea> listTareas({int? proyectoId}) {
    if (proyectoId == null) return List<Tarea>.from(tareas);
    return tareas.where((t) => t.proyectoId == proyectoId).toList();
  }

  Tarea createTarea(Map<String, dynamic> body, {required String? asignadoNombre, int? actorId, String? actorName}) {
    final tarea = Tarea(
      id: ++_tareaSeq,
      titulo: (body['titulo'] ?? '') as String,
      descripcion: (body['descripcion'] ?? '') as String,
      estado: (body['estado'] ?? 'pendiente') as String,
      asignadoAId: body['asignado_a'] as int?,
      asignadoANombre: asignadoNombre,
      proyectoId: body['proyecto'] as int,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    tareas.add(tarea);
    // Crédito al asignado; si no hay, quien creó la tarea.
    _recordHistorial(
      tipo: 'tarea',
      refId: tarea.id,
      titulo: tarea.titulo,
      estadoAnterior: '',
      estadoNuevo: tarea.estado,
      usuarioId: tarea.asignadoAId ?? actorId,
      usuarioNombre: tarea.asignadoANombre ?? actorName,
    );
    return tarea;
  }

  Tarea updateTarea(int id, Map<String, dynamic> body, {String? asignadoNombre, int? actorId, String? actorName}) {
    final i = tareas.indexWhere((t) => t.id == id);
    if (i < 0) throw StateError('Tarea $id no encontrada');
    final cur = tareas[i];
    final newAsignadoId =
        body.containsKey('asignado_a') ? body['asignado_a'] as int? : cur.asignadoAId;
    final newAsignadoNombre = body.containsKey('asignado_a')
        ? (newAsignadoId == null ? null : (asignadoNombre ?? nameForUser(newAsignadoId) ?? 'Usuario #$newAsignadoId'))
        : cur.asignadoANombre;
    final newEstado = (body['estado'] as String?) ?? cur.estado;
    final updated = Tarea(
      id: cur.id,
      titulo: (body['titulo'] as String?) ?? cur.titulo,
      descripcion: (body['descripcion'] as String?) ?? cur.descripcion,
      estado: newEstado,
      asignadoAId: newAsignadoId,
      asignadoANombre: newAsignadoNombre,
      proyectoId: cur.proyectoId,
      fechaCreacion: cur.fechaCreacion,
      fechaActualizacion: DateTime.now(),
    );
    tareas[i] = updated;
    if (cur.estado != newEstado) {
      // Crédito al asignado de la tarea, no a quien arrastró la tarjeta.
      _recordHistorial(
        tipo: 'tarea',
        refId: updated.id,
        titulo: updated.titulo,
        estadoAnterior: cur.estado,
        estadoNuevo: newEstado,
        usuarioId: updated.asignadoAId ?? actorId,
        usuarioNombre: updated.asignadoANombre ?? actorName,
      );
    }
    return updated;
  }

  void deleteTarea(int id) {
    tareas.removeWhere((t) => t.id == id);
  }

  void _recordHistorial({
    required String tipo,
    required int refId,
    required String titulo,
    required String estadoAnterior,
    required String estadoNuevo,
    required int? usuarioId,
    required String? usuarioNombre,
  }) {
    if (estadoAnterior == estadoNuevo) return;
    historial.insert(
      0,
      ProductividadEvento(
        fecha: DateTime.now(),
        usuarioId: usuarioId,
        usuarioNombre: usuarioNombre,
        tipo: tipo,
        refId: refId,
        titulo: titulo,
        estadoAnterior: estadoAnterior,
        estadoNuevo: estadoNuevo,
      ),
    );
  }

  /// Agrega ranking + timeline entre [desde] y [hasta] (inclusive).
  /// El crédito va al asignado de la tarea/ticket; si no hay, al usuario del evento.
  ProductividadReport productividad({
    required DateTime desde,
    required DateTime hasta,
  }) {
    final start = DateTime(desde.year, desde.month, desde.day);
    final end = DateTime(hasta.year, hasta.month, hasta.day).add(const Duration(days: 1));

    final raw = historial
        .where((e) =>
            (e.tipo == 'ticket' || e.tipo == 'tarea') &&
            !e.fecha.isBefore(start) &&
            e.fecha.isBefore(end))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    // Remapear crédito al asignado actual de la entidad.
    final eventos = raw.map((e) {
      if (e.tipo == 'tarea') {
        Tarea? t;
        for (final x in tareas) {
          if (x.id == e.refId) {
            t = x;
            break;
          }
        }
        if (t?.asignadoAId != null) {
          return ProductividadEvento(
            fecha: e.fecha,
            usuarioId: t!.asignadoAId,
            usuarioNombre: t.asignadoANombre,
            tipo: e.tipo,
            refId: e.refId,
            titulo: e.titulo,
            estadoAnterior: e.estadoAnterior,
            estadoNuevo: e.estadoNuevo,
          );
        }
      } else if (e.tipo == 'ticket') {
        Ticket? t;
        for (final x in tickets) {
          if (x.id == e.refId) {
            t = x;
            break;
          }
        }
        if (t?.asignadoAId != null) {
          return ProductividadEvento(
            fecha: e.fecha,
            usuarioId: t!.asignadoAId,
            usuarioNombre: t.asignadoANombre,
            tipo: e.tipo,
            refId: e.refId,
            titulo: e.titulo,
            estadoAnterior: e.estadoAnterior,
            estadoNuevo: e.estadoNuevo,
          );
        }
      }
      return e;
    }).toList();

    final rankingMap = <int, ProductividadRanking>{};
    for (final u in assignableUsers) {
      if (u.rol == null ||
          u.rol!.toLowerCase().contains('desarrollador') ||
          u.rol!.toLowerCase().contains('líder') ||
          u.rol!.toLowerCase().contains('lider') ||
          u.rol!.toLowerCase().contains('gestor')) {
        rankingMap[u.id] = ProductividadRanking(
          userId: u.id,
          nombre: u.fullName,
        );
      }
    }

    for (final e in eventos) {
      final uid = e.usuarioId;
      if (uid == null) continue;
      final cur = rankingMap[uid] ??
          ProductividadRanking(userId: uid, nombre: e.usuarioNombre ?? 'Usuario #$uid');
      var tareasHechas = cur.tareasHechas;
      var ticketsResueltos = cur.ticketsResueltos;
      if (e.tipo == 'tarea' && e.estadoNuevo == 'hecho') tareasHechas += 1;
      if (e.tipo == 'ticket' && (e.estadoNuevo == 'resuelto' || e.estadoNuevo == 'cerrado')) {
        ticketsResueltos += 1;
      }
      rankingMap[uid] = ProductividadRanking(
        userId: uid,
        nombre: cur.nombre,
        tareasHechas: tareasHechas,
        ticketsResueltos: ticketsResueltos,
      );
    }

    final ranking = rankingMap.values.toList()
      ..sort((a, b) {
        final cmp = b.total.compareTo(a.total);
        if (cmp != 0) return cmp;
        return b.tareasHechas.compareTo(a.tareasHechas);
      });

    return ProductividadReport(ranking: ranking, actividad: eventos);
  }
}