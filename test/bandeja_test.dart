import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_proyectos/models/models.dart';
import 'package:gestor_proyectos/utils/bandeja.dart';

void main() {
  final ahora = DateTime(2026, 10, 1, 12);

  Ticket ticket({
    required int id,
    String estado = 'nuevo',
    int? asignadoAId,
    String? asignadoANombre,
    DateTime? fechaActualizacion,
  }) {
    return Ticket(
      id: id,
      titulo: 'T$id',
      estado: estado,
      asignadoAId: asignadoAId,
      asignadoANombre: asignadoANombre,
      fechaActualizacion: fechaActualizacion,
    );
  }

  Tarea tarea({
    required int id,
    String estado = 'pendiente',
    int? asignadoAId,
    String? asignadoANombre,
    int proyectoId = 1,
    List<TareaEspera> esperando = const [],
    DateTime? fechaActualizacion,
  }) {
    return Tarea(
      id: id,
      titulo: 'Ta$id',
      estado: estado,
      asignadoAId: asignadoAId,
      asignadoANombre: asignadoANombre,
      proyectoId: proyectoId,
      esperando: esperando,
      fechaActualizacion: fechaActualizacion,
    );
  }

  test('lo mío incluye esperando y deja fuera la cola y lo cerrado', () {
    final items = [
      ticket(id: 1, estado: 'esperando', asignadoAId: 3),
      ticket(id: 2, estado: 'en_proceso', asignadoAId: 3),
      ticket(id: 3, estado: 'nuevo', asignadoAId: 3),
      ticket(id: 4, estado: 'por_aprobar', asignadoAId: 3),
      ticket(id: 5, estado: 'nuevo'),
      ticket(id: 6, estado: 'cerrado', asignadoAId: 3),
      ticket(id: 7, estado: 'en_proceso', asignadoAId: 9),
    ];

    final mios = ticketsDeAlcance(items, alcance: 'yo', yoId: 3);
    expect(mios.map((t) => t.id), [1, 2, 3]);

    final cola = ticketsDeAlcance(items, alcance: 'cola', yoId: 3);
    expect(cola.map((t) => t.id), [4, 5]);

    final sinAsignar = ticketsDeAlcance(
      items,
      alcance: 'cola',
      yoId: 3,
      estado: 'sin_asignar',
    );
    expect(sinAsignar.map((t) => t.id), [5]);
  });

  test('la misma persona y el mismo estado significan lo mismo', () {
    final items = [
      ticket(id: 1, estado: 'esperando', asignadoAId: 9, asignadoANombre: 'Ana'),
      ticket(id: 2, estado: 'resuelto', asignadoAId: 9, asignadoANombre: 'Ana'),
    ];
    final abiertos = ticketsDeAlcance(
      items,
      alcance: 'persona',
      yoId: 3,
      personaId: 9,
    );
    final resueltos = ticketsDeAlcance(
      items,
      alcance: 'persona',
      yoId: 3,
      personaId: 9,
      estado: 'resuelto',
    );
    expect(abiertos.map((t) => t.id), [1]);
    expect(resueltos.map((t) => t.id), [2]);
  });

  test('sin movimiento solo cuenta ítems abiertos con más de 5 días', () {
    final fresco = ticket(
      id: 1,
      estado: 'en_proceso',
      asignadoAId: 3,
      fechaActualizacion: ahora.subtract(const Duration(days: 2)),
    );
    final viejo = ticket(
      id: 2,
      estado: 'esperando',
      asignadoAId: 3,
      fechaActualizacion: ahora.subtract(const Duration(days: 5)),
    );
    final cerrado = ticket(
      id: 3,
      estado: 'cerrado',
      asignadoAId: 3,
      fechaActualizacion: ahora.subtract(const Duration(days: 40)),
    );
    expect(ticketSinMovimiento(fresco, ahora: ahora), isFalse);
    expect(ticketSinMovimiento(viejo, ahora: ahora), isTrue);
    expect(ticketSinMovimiento(cerrado, ahora: ahora), isFalse);
  });

  test('el equipo agrupa lo abierto de los demás y marca espera', () {
    final tickets = [
      ticket(id: 1, estado: 'en_proceso', asignadoAId: 9, asignadoANombre: 'Ana'),
      ticket(
        id: 2,
        estado: 'esperando',
        asignadoAId: 9,
        asignadoANombre: 'Ana',
        fechaActualizacion: ahora.subtract(const Duration(days: 8)),
      ),
      ticket(id: 3, estado: 'en_proceso', asignadoAId: 3, asignadoANombre: 'Yo'),
      ticket(id: 4, estado: 'cerrado', asignadoAId: 8, asignadoANombre: 'Luis'),
    ];
    final tareas = [
      tarea(
        id: 1,
        asignadoAId: 9,
        asignadoANombre: 'Ana',
        esperando: const [TareaEspera(nombre: 'Compras')],
      ),
      tarea(id: 2, estado: 'hecho', asignadoAId: 9, asignadoANombre: 'Ana'),
    ];

    final cargas = cargasPorPersona(
      tickets: tickets,
      tareas: tareas,
      excluirId: 3,
      ahora: ahora,
    );
    expect(cargas.map((c) => c.id), [9]);
    expect(cargas.single.ticketsAbiertos, 2);
    expect(cargas.single.tareasAbiertas, 1);
    expect(cargas.single.enEspera, 2);
    expect(cargas.single.sinMovimiento, 1);

    final deAna = tareasDeAlcance(
      tareas,
      alcance: 'persona',
      yoId: 3,
      personaId: 9,
    );
    expect(deAna.map((t) => t.id), [1]);
    expect(etiquetaEspera(deAna.single), 'Espera a Compras');
  });

  test('las rutas de inicio abren la misma bandeja', () {
    expect(
      RutaBandeja.tickets(const {'bandeja': 'por_aprobar'}).alcance,
      'cola',
    );
    expect(
      RutaBandeja.tickets(const {'bandeja': 'por_aprobar'}).estado,
      'por_aprobar',
    );
    expect(RutaBandeja.tickets(const {'unassigned': '1'}).estado, 'sin_asignar');
    expect(RutaBandeja.tickets(const {'mine': '1'}).alcance, 'yo');
    expect(RutaBandeja.tickets(const {'mine': '1'}).estado, isNull);
    expect(
      RutaBandeja.tickets(const {'persona': '9'}).personaId,
      9,
    );
    expect(
      RutaBandeja.tareas(const {'estado': 'pendiente'}).alcance,
      'yo',
    );
    expect(
      RutaBandeja.tareas(const {'alcance': 'equipo'}).alcance,
      'equipo',
    );

    final ruta = RutaBandeja(alcance: 'persona', personaId: 9);
    final otra = RutaBandeja.tickets(
      Uri.parse(ruta.ticketsPath).queryParameters,
    );
    expect(otra.alcance, 'persona');
    expect(otra.personaId, 9);
    expect(otra.estado, isNull);
  });

  test('un proyecto es mío si soy responsable o tengo una tarea', () {
    const proyecto = Proyecto(id: 1, titulo: 'P', responsableId: 4);
    final tareas = [tarea(id: 1, asignadoAId: 3)];
    expect(proyectoEsMio(proyecto, 4, tareas), isTrue);
    expect(proyectoEsMio(proyecto, 3, tareas), isTrue);
    expect(proyectoEsMio(proyecto, 8, tareas), isFalse);
  });

  test('el resumen nombra a quien tiene tareas abiertas', () {
    final tareas = [
      tarea(id: 1, asignadoAId: 9, asignadoANombre: 'Ana Ruiz'),
      tarea(id: 2, asignadoAId: 9, asignadoANombre: 'Ana Ruiz'),
      tarea(id: 3, estado: 'hecho', asignadoAId: 8, asignadoANombre: 'Luis'),
    ];
    expect(resumenAbiertasPorPersona(tareas), 'Ana Ruiz 2');
    expect(resumenAbiertasPorPersona(const []), 'Sin tareas abiertas');
  });
}
