import '../models/models.dart';

/// Días sin [fechaActualizacion] (o creación) para marcar un ítem abierto.
const int kDiasSinMovimiento = 5;

/// Trabajo que la persona tiene que mover. `por_aprobar` vive en la cola.
const Set<String> kEstadosTicketEnCurso = {
  'nuevo',
  'en_proceso',
  'esperando',
};

const Set<String> kEstadosTareaAbiertos = {
  'pendiente',
  'en_progreso',
};

bool ticketEnCurso(Ticket t) => kEstadosTicketEnCurso.contains(t.estado);

bool tareaAbierta(Tarea t) => kEstadosTareaAbiertos.contains(t.estado);

/// Cola: nuevo y todavía sin asignado.
bool ticketEnCola(Ticket t) => t.asignadoAId == null && t.estado == 'nuevo';

bool ticketPorAprobar(Ticket t) => t.estado == 'por_aprobar';

bool ticketEnAlgunaCola(Ticket t) => ticketPorAprobar(t) || ticketEnCola(t);

/// Abiertos asignados a [userId], incluido `esperando`.
bool ticketEnBandejaYo(Ticket t, int userId) =>
    t.asignadoAId == userId && ticketEnCurso(t);

bool tareaAbiertaDe(Tarea t, int userId) =>
    t.asignadoAId == userId && tareaAbierta(t);

DateTime? actividadDe(DateTime? actualizacion, DateTime? creacion) =>
    actualizacion ?? creacion;

bool sinMovimiento(DateTime? fecha, {DateTime? ahora}) {
  if (fecha == null) return false;
  final now = ahora ?? DateTime.now();
  return now.difference(fecha) >= const Duration(days: kDiasSinMovimiento);
}

bool ticketSinMovimiento(Ticket t, {DateTime? ahora}) {
  final abierto = ticketEnCurso(t) || ticketPorAprobar(t);
  if (!abierto) return false;
  return sinMovimiento(
    actividadDe(t.fechaActualizacion, t.fechaCreacion),
    ahora: ahora,
  );
}

bool tareaSinMovimiento(Tarea t, {DateTime? ahora}) {
  if (!tareaAbierta(t)) return false;
  return sinMovimiento(
    actividadDe(t.fechaActualizacion, t.fechaCreacion),
    ahora: ahora,
  );
}

bool tareaEnEspera(Tarea t) =>
    tareaAbierta(t) &&
    t.esperando.any((e) => !e.cumplido && e.nombre.trim().isNotEmpty);

String? etiquetaEspera(Tarea t) {
  final nombres = t.esperando
      .where((e) => !e.cumplido && e.nombre.trim().isNotEmpty)
      .map((e) => e.nombre.trim())
      .toList();
  if (nombres.isEmpty) return null;
  return 'Espera a ${nombres.join(', ')}';
}

/// Tickets del alcance elegido.
///
/// [estado] en cola: `por_aprobar`, `sin_asignar` o null (las dos).
/// [estado] en yo/persona: un estado concreto, o null para los abiertos
/// (`nuevo`, `en_proceso`, `esperando`).
List<Ticket> ticketsDeAlcance(
  List<Ticket> items, {
  required String alcance,
  required int? yoId,
  int? personaId,
  String? estado,
}) {
  if (alcance == 'cola') {
    return items.where((t) {
      if (estado == 'por_aprobar') return ticketPorAprobar(t);
      if (estado == 'sin_asignar') return ticketEnCola(t);
      return ticketEnAlgunaCola(t);
    }).toList();
  }

  final id = alcance == 'persona' ? personaId : yoId;
  if (id == null) return const [];
  return items.where((t) {
    if (t.asignadoAId != id) return false;
    if (estado == null || estado == 'abiertos') return ticketEnCurso(t);
    return t.estado == estado;
  }).toList();
}

List<Tarea> tareasDeAlcance(
  List<Tarea> items, {
  required String alcance,
  required int? yoId,
  int? personaId,
  String? estado,
}) {
  return items.where((t) {
    if (alcance == 'persona') {
      if (personaId == null || t.asignadoAId != personaId) return false;
    } else if (alcance == 'equipo') {
      if (t.asignadoAId == null || t.asignadoAId == yoId) return false;
    } else {
      if (yoId == null || t.asignadoAId != yoId) return false;
    }
    if (estado == null || estado == 'abiertas') return tareaAbierta(t);
    return t.estado == estado;
  }).toList();
}

class CargaPersona {
  const CargaPersona({
    required this.id,
    required this.nombre,
    this.ticketsAbiertos = 0,
    this.tareasAbiertas = 0,
    this.sinMovimiento = 0,
    this.enEspera = 0,
    this.tieneTickets = false,
    this.tieneTareas = false,
  });

  final int id;
  final String nombre;
  final int ticketsAbiertos;
  final int tareasAbiertas;
  final int sinMovimiento;
  final int enEspera;
  final bool tieneTickets;
  final bool tieneTareas;

  int get abiertos => ticketsAbiertos + tareasAbiertas;
}

class _CargaAcc {
  _CargaAcc(this.id);
  final int id;
  String nombre = '';
  int ticketsAbiertos = 0;
  int tareasAbiertas = 0;
  int sinMovimiento = 0;
  int enEspera = 0;
  bool tieneTickets = false;
  bool tieneTareas = false;
}

/// Personas con trabajo asignado. [excluirId] saca al usuario actual del equipo.
///
/// Con [soloConAbiertos], quien solo tiene ítems cerrados no aparece.
List<CargaPersona> cargasPorPersona({
  required List<Ticket> tickets,
  required List<Tarea> tareas,
  int? excluirId,
  bool soloConAbiertos = true,
  DateTime? ahora,
}) {
  final map = <int, _CargaAcc>{};

  void touch(int id, String? nombre) {
    final acc = map.putIfAbsent(id, () => _CargaAcc(id));
    final n = nombre?.trim() ?? '';
    if (n.isNotEmpty) acc.nombre = n;
  }

  for (final t in tickets) {
    final id = t.asignadoAId;
    if (id == null || id == excluirId) continue;
    touch(id, t.asignadoANombre);
    final acc = map[id]!;
    acc.tieneTickets = true;
    if (!ticketEnCurso(t)) continue;
    acc.ticketsAbiertos++;
    if (ticketSinMovimiento(t, ahora: ahora)) acc.sinMovimiento++;
    if (t.estado == 'esperando') acc.enEspera++;
  }

  for (final t in tareas) {
    final id = t.asignadoAId;
    if (id == null || id == excluirId) continue;
    touch(id, t.asignadoANombre);
    final acc = map[id]!;
    acc.tieneTareas = true;
    if (!tareaAbierta(t)) continue;
    acc.tareasAbiertas++;
    if (tareaSinMovimiento(t, ahora: ahora)) acc.sinMovimiento++;
    if (tareaEnEspera(t)) acc.enEspera++;
  }

  final list = map.values
      .where((a) => !soloConAbiertos || a.ticketsAbiertos + a.tareasAbiertas > 0)
      .map(
        (a) => CargaPersona(
          id: a.id,
          nombre: a.nombre.isEmpty ? 'Usuario #${a.id}' : a.nombre,
          ticketsAbiertos: a.ticketsAbiertos,
          tareasAbiertas: a.tareasAbiertas,
          sinMovimiento: a.sinMovimiento,
          enEspera: a.enEspera,
          tieneTickets: a.tieneTickets,
          tieneTareas: a.tieneTareas,
        ),
      )
      .toList()
    ..sort((a, b) {
      final c = b.abiertos.compareTo(a.abiertos);
      if (c != 0) return c;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });
  return list;
}

/// Cómo se abre la misma bandeja desde Inicio, Tickets o Tareas.
class RutaBandeja {
  const RutaBandeja({
    this.alcance = 'yo',
    this.estado,
    this.personaId,
  });

  /// Tickets: `cola` | `yo` | `persona`. Tareas: `yo` | `equipo` | `persona`.
  final String alcance;
  final String? estado;
  final int? personaId;

  static RutaBandeja tickets(Map<String, String> q) {
    final persona = int.tryParse(q['persona'] ?? '');
    if (persona != null) {
      return RutaBandeja(
        alcance: 'persona',
        personaId: persona,
        estado: _estadoTicket(q['estado']),
      );
    }
    if (q['unassigned'] == '1' || q['alcance'] == 'cola' || q['bandeja'] == 'por_aprobar') {
      var estado = q['estado'];
      if (q['bandeja'] == 'por_aprobar') estado = 'por_aprobar';
      if (estado == null && q['unassigned'] == '1') estado = 'sin_asignar';
      if (estado != 'por_aprobar' && estado != 'sin_asignar') estado = null;
      return RutaBandeja(alcance: 'cola', estado: estado);
    }
    var estado = _estadoTicket(q['estado']);
    if (q['bandeja'] == 'en_progreso' || q['bandeja'] == 'en_curso') {
      estado ??= 'en_proceso';
    }
    return RutaBandeja(alcance: 'yo', estado: estado);
  }

  static RutaBandeja tareas(Map<String, String> q) {
    final persona = int.tryParse(q['persona'] ?? '');
    final estado = _estadoTarea(q['estado']);
    if (persona != null) {
      return RutaBandeja(alcance: 'persona', personaId: persona, estado: estado);
    }
    if (q['alcance'] == 'equipo') {
      return RutaBandeja(alcance: 'equipo', estado: estado);
    }
    return RutaBandeja(alcance: 'yo', estado: estado);
  }

  static String? _estadoTicket(String? estado) {
    const validos = {
      'por_aprobar',
      'sin_asignar',
      'nuevo',
      'en_proceso',
      'esperando',
      'resuelto',
      'rechazado',
      'cerrado',
    };
    if (estado == null || estado == 'abiertos') return null;
    return validos.contains(estado) ? estado : null;
  }

  static String? _estadoTarea(String? estado) {
    const validos = {'pendiente', 'en_progreso', 'hecho'};
    if (estado == null || estado == 'abiertas') return null;
    return validos.contains(estado) ? estado : null;
  }

  String get ticketsPath {
    final params = <String, String>{'alcance': alcance == 'persona' ? 'persona' : alcance};
    if (estado != null) params['estado'] = estado!;
    if (personaId != null) params['persona'] = '$personaId';
    return Uri(path: '/tickets', queryParameters: params).toString();
  }

  String get tareasPath {
    final params = <String, String>{};
    if (alcance == 'equipo') params['alcance'] = 'equipo';
    if (alcance == 'persona') params['alcance'] = 'persona';
    if (estado != null) params['estado'] = estado!;
    if (personaId != null) params['persona'] = '$personaId';
    if (params.isEmpty) return '/tareas';
    return Uri(path: '/tareas', queryParameters: params).toString();
  }
}

bool proyectoEsMio(Proyecto p, int userId, List<Tarea> tareas) {
  if (p.responsableId == userId) return true;
  return tareas.any((t) => t.asignadoAId == userId);
}

/// "Ana 2 · Luis 1" con las tareas abiertas del proyecto. Vacío si no hay.
String resumenAbiertasPorPersona(List<Tarea> tareas) {
  final counts = <String, int>{};
  for (final t in tareas.where(tareaAbierta)) {
    final name = (t.asignadoANombre ?? '').trim();
    final label = name.isEmpty ? 'Sin asignar' : name;
    counts[label] = (counts[label] ?? 0) + 1;
  }
  if (counts.isEmpty) return 'Sin tareas abiertas';
  final entries = counts.entries.toList()
    ..sort((a, b) {
      final c = b.value.compareTo(a.value);
      if (c != 0) return c;
      return a.key.toLowerCase().compareTo(b.key.toLowerCase());
    });
  const max = 3;
  final shown = entries.take(max).map((e) => '${e.key} ${e.value}');
  final extra = entries.length - max;
  final base = shown.join(' · ');
  if (extra > 0) return '$base · +$extra';
  return base;
}
