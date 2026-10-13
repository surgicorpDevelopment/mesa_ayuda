"""Datos de prueba para ver Yo / Equipo con cada usuario local.

Password de todos: local123 (la crea seed_local_users).

- usuario (Ana): solo las incidencias que reportó.
- dev (Diego), lider (Laura), gestor (Gabriel): cola, lo propio y el equipo.
- admin: lo mismo que un gestor.

Se puede correr varias veces: actualiza por título y reajusta las fechas
respecto a hoy, para que “sin movimiento” siga siendo de más de 5 días.
"""

from datetime import timedelta

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from GestionProyectos.models import (
    EstadoProyecto,
    EstadoTarea,
    EstadoTicket,
    GP_Comentario,
    GP_HistorialEstado,
    GP_Proyecto,
    GP_Tarea,
    GP_Ticket,
    Prioridad,
    TipoEntidad,
)

User = get_user_model()


class Command(BaseCommand):
    help = 'Carga proyectos, tickets y tareas de prueba en la base local.'

    def handle(self, *args, **options):
        try:
            from localdev.models import EU_Area
        except ImportError:
            self.stderr.write('Este comando solo corre en el harness local.')
            return

        needed = ('usuario', 'dev', 'lider', 'gestor')
        users = {u.username: u for u in User.objects.filter(username__in=needed)}
        missing = [name for name in needed if name not in users]
        if missing:
            self.stderr.write(
                'Faltan usuarios: '
                + ', '.join(missing)
                + '. Corre antes seed_local_users.'
            )
            return

        areas = {a.nombre: a for a in EU_Area.objects.all()}
        ti = areas.get('Tecnología de la Información')
        comercial = areas.get('Comercial')
        if ti is None:
            self.stderr.write('Falta el área de TI. Corre antes seed_local_users.')
            return

        now = timezone.now()
        today = timezone.localdate()
        ana = users['usuario']
        diego = users['dev']
        laura = users['lider']
        gabriel = users['gestor']

        def espera(persona, detalle, cumplido=False):
            return {
                'nombre': persona.get_full_name().strip() or persona.username,
                'usuario_id': persona.id,
                'detalle': detalle,
                'cumplido': cumplido,
            }

        with transaction.atomic():
            mesa = self._proyecto(
                'Mesa de distribución',
                'Seguimiento de pedidos y picking entre almacenes.',
                ti.id,
                EstadoProyecto.EN_PROCESO,
                Prioridad.ALTA,
                laura,
                gabriel,
                today - timedelta(days=20),
                today - timedelta(days=2),
                days=1,
                now=now,
            )
            hub = self._proyecto(
                'Hub de facturación',
                'Estatus y series del módulo de facturación.',
                ti.id,
                EstadoProyecto.EN_PROCESO,
                Prioridad.ALTA,
                diego,
                laura,
                today - timedelta(days=12),
                today + timedelta(days=18),
                days=0,
                now=now,
            )
            vacaciones = self._proyecto(
                'App de vacaciones',
                'Solicitud y saldo de vacaciones para el área.',
                ti.id,
                EstadoProyecto.PLANIFICADO,
                Prioridad.MEDIA,
                gabriel,
                laura,
                today + timedelta(days=5),
                today + timedelta(days=40),
                days=3,
                now=now,
            )
            inventario = self._proyecto(
                'Inventario cíclico',
                'Conteo de almacén 2, ya cerrado.',
                ti.id,
                EstadoProyecto.COMPLETADO,
                Prioridad.BAJA,
                laura,
                diego,
                today - timedelta(days=40),
                today - timedelta(days=10),
                days=10,
                now=now,
            )
            comercial_id = comercial.id if comercial is not None else None
            tablero = self._proyecto(
                'Tablero comercial',
                'Pipeline de licitaciones, en el área Comercial.',
                comercial_id,
                EstadoProyecto.IDEA,
                Prioridad.MEDIA,
                gabriel,
                gabriel,
                today + timedelta(days=15),
                today + timedelta(days=60),
                days=4,
                now=now,
            )

            self._tarea(
                mesa, 'Ajustar API de pedidos', EstadoTarea.EN_PROGRESO, diego,
                'El pedido tiene que llegar a SQL sin perder el picking.',
                days=0, now=now, orden=1,
            )
            self._tarea(
                mesa, 'Revisar adjuntos del vaciado', EstadoTarea.PENDIENTE, diego,
                'Falta el archivo que manda el almacén.',
                esperando=[espera(ana, 'Enviar el Excel del vaciado')],
                days=8, now=now, orden=2,
            )
            self._tarea(
                mesa, 'Validar ruta con operaciones', EstadoTarea.EN_PROGRESO, laura,
                'Confirmar la ruta de la tablet de distribución.',
                days=1, now=now, orden=3,
            )
            self._tarea(
                mesa, 'Definir criterios de cierre', EstadoTarea.PENDIENTE, gabriel,
                'Qué se considera un pedido cerrado.',
                days=6, now=now, orden=4,
            )
            self._tarea(
                mesa, 'Etiqueta de bulto', EstadoTarea.PENDIENTE, None,
                'Todavía no tiene responsable.',
                days=2, now=now, orden=5,
            )
            self._tarea(
                mesa, 'Cerrar sprint de pruebas', EstadoTarea.HECHO, laura,
                'Pruebas del flujo de picking.',
                days=1, now=now, orden=6,
                historial=(('', EstadoTarea.PENDIENTE, 12), (EstadoTarea.PENDIENTE, EstadoTarea.HECHO, 1)),
            )

            self._tarea(
                hub, 'Crear estatus de factura', EstadoTarea.EN_PROGRESO, diego,
                'Alta y edición de estatus en facturación.',
                days=0, now=now, orden=1,
            )
            self._tarea(
                hub, 'Revisar módulo de series', EstadoTarea.PENDIENTE, laura,
                'Series que no cuadran con la guía.',
                esperando=[espera(gabriel, 'Pasar el script de series')],
                days=7, now=now, orden=2,
            )
            self._tarea(
                hub, 'Script de migración', EstadoTarea.EN_PROGRESO, gabriel,
                'Migrar estatus viejos al catálogo nuevo.',
                days=1, now=now, orden=3,
            )

            self._tarea(
                vacaciones, 'Pantalla de solicitud', EstadoTarea.PENDIENTE, laura,
                'Formulario de pedido de vacaciones.',
                days=2, now=now, orden=1,
            )
            self._tarea(
                vacaciones, 'Endpoint de saldo', EstadoTarea.PENDIENTE, diego,
                'Días disponibles por persona.',
                days=1, now=now, orden=2,
            )
            self._tarea(
                vacaciones, 'Reglas de aprobación', EstadoTarea.EN_PROGRESO, gabriel,
                'Quién aprueba según el área.',
                esperando=[espera(laura, 'Confirmar el flujo del líder', cumplido=True)],
                days=0, now=now, orden=3,
            )

            self._tarea(
                inventario, 'Contar almacén 2', EstadoTarea.HECHO, diego,
                'Conteo cerrado.',
                days=11, now=now, orden=1,
                historial=((EstadoTarea.EN_PROGRESO, EstadoTarea.HECHO, 11),),
            )
            self._tarea(
                inventario, 'Conciliar diferencias', EstadoTarea.HECHO, laura,
                'Diferencias ya explicadas.',
                days=10, now=now, orden=2,
                historial=((EstadoTarea.EN_PROGRESO, EstadoTarea.HECHO, 10),),
            )

            self._tarea(
                tablero, 'Mapa de pipeline', EstadoTarea.PENDIENTE, gabriel,
                'Columnas del tablero comercial.',
                days=4, now=now, orden=1,
            )

            self._ticket(
                'Error al adjuntar guía en Power Apps',
                EstadoTicket.POR_APROBAR, Prioridad.ALTA, 'power_apps',
                ana, None, None, ti.id,
                'Desde la cuenta de Luzmila no se adjuntan archivos.',
                days=0, now=now,
            )
            self._ticket(
                'No carga el reporte de comisiones',
                EstadoTicket.POR_APROBAR, Prioridad.MEDIA, 'comisiones',
                ana, None, None, ti.id,
                'El reporte queda en blanco desde el lunes.',
                days=6, now=now,
            )
            self._ticket(
                'Pedido no pasa a SQL al eliminar picking',
                EstadoTicket.NUEVO, Prioridad.ALTA, 'erp',
                ana, None, None, ti.id,
                'Al borrar un picking el pedido no se actualiza.',
                days=1, now=now,
            )
            self._ticket(
                'Tablet de distribución no conecta al hub',
                EstadoTicket.NUEVO, Prioridad.MEDIA, 'erp',
                ana, None, None, ti.id,
                'La tablet del pasillo 3 no ve el hub.',
                days=9, now=now,
            )
            self._ticket(
                'Stock negativo en almacén 2',
                EstadoTicket.NUEVO, Prioridad.ALTA, 'stock_inventario',
                ana, diego, None, ti.id,
                'Un producto quedó en menos uno después del conteo.',
                days=0, now=now,
            )
            self._ticket(
                'Factura no toma el estatus nuevo',
                EstadoTicket.EN_PROCESO, Prioridad.ALTA, 'facturacion',
                ana, diego, hub, ti.id,
                'El estatus se guarda pero la factura sigue en borrador.',
                days=0, now=now,
                historial=((EstadoTicket.NUEVO, EstadoTicket.EN_PROCESO, 0),),
            )
            self._ticket(
                'Falta confirmación de series',
                EstadoTicket.ESPERANDO, Prioridad.MEDIA, 'facturacion',
                ana, diego, hub, ti.id,
                'No se puede cerrar la factura sin la serie.',
                days=7, now=now,
                historial=((EstadoTicket.EN_PROCESO, EstadoTicket.ESPERANDO, 7),),
            )
            self._ticket(
                'Ajuste de ruta en distribución',
                EstadoTicket.EN_PROCESO, Prioridad.MEDIA, 'erp',
                ana, laura, mesa, ti.id,
                'La ruta de la tarde no respeta el orden del picking.',
                days=1, now=now,
            )
            self._ticket(
                'Esperando datos de la cuenta de Luzmila',
                EstadoTicket.ESPERANDO, Prioridad.BAJA, 'power_apps',
                ana, laura, mesa, ti.id,
                'El adjunto falla solo con esa cuenta.',
                days=2, now=now,
            )
            self._ticket(
                'Automatizar aviso de licitación',
                EstadoTicket.NUEVO, Prioridad.MEDIA, 'n8n',
                ana, gabriel, None, ti.id,
                'Avisar al comercial cuando entra una licitación.',
                days=0, now=now,
            )
            self._ticket(
                'WhatsApp duplica el mensaje de guía',
                EstadoTicket.EN_PROCESO, Prioridad.ALTA, 'whatsapp',
                ana, gabriel, None, ti.id,
                'El cliente recibe dos veces el mismo aviso.',
                days=8, now=now,
            )
            self._ticket(
                'Revisar permiso del módulo de proyectos',
                EstadoTicket.EN_PROCESO, Prioridad.MEDIA, 'otro',
                laura, diego, None, ti.id,
                'Un desarrollador no ve un proyecto de su área.',
                days=1, now=now,
            )
            self._ticket(
                'Corregido el redondeo de caja chica',
                EstadoTicket.RESUELTO, Prioridad.BAJA, 'caja_chica',
                ana, diego, None, ti.id,
                'El total ya cuadra con el voucher.',
                days=2, now=now,
                historial=((EstadoTicket.EN_PROCESO, EstadoTicket.RESUELTO, 2),),
            )
            rechazado = self._ticket(
                'Cambiar el logo de cotizaciones',
                EstadoTicket.RECHAZADO, Prioridad.BAJA, 'cotizaciones',
                ana, None, None, ti.id,
                'Piden un logo nuevo en el PDF.',
                days=4, now=now,
            )
            self._comentario(
                TipoEntidad.TICKET,
                rechazado.id,
                laura,
                'Queda fuera de mesa de ayuda: es un cambio de diseño, no una incidencia.',
                days=4,
                now=now,
            )
            self._ticket(
                'Alta de usuario en vacaciones',
                EstadoTicket.CERRADO, Prioridad.BAJA, 'vacaciones',
                ana, laura, vacaciones, ti.id,
                'El usuario ya puede pedir vacaciones.',
                days=12, now=now,
                historial=((EstadoTicket.RESUELTO, EstadoTicket.CERRADO, 12),),
            )

        self.stdout.write(self.style.SUCCESS('Datos de prueba listos. Password: local123'))
        self.stdout.write('  usuario  Ana      solo sus incidencias')
        self.stdout.write('  dev      Diego    ve proyectos y tickets de todas las áreas')
        self.stdout.write('  lider    Laura    su área, más lo que creó o lidera')
        self.stdout.write('  gestor   Gabriel  ve todo')
        self.stdout.write('  admin             ve todo')

    def _proyecto(
        self, titulo, descripcion, area_id, estado, prioridad,
        responsable, creado_por, inicio, objetivo, days, now,
    ):
        obj, _ = GP_Proyecto.objects.update_or_create(
            titulo=titulo,
            defaults={
                'descripcion': descripcion,
                'area_id': area_id,
                'estado': estado,
                'prioridad': prioridad,
                'responsable': responsable,
                'creado_por': creado_por,
                'fecha_inicio': inicio,
                'fecha_objetivo': objetivo,
            },
        )
        when = now - timedelta(days=days)
        GP_Proyecto.objects.filter(pk=obj.pk).update(
            fecha_creacion=when,
            fecha_actualizacion=when,
        )
        return obj

    def _tarea(
        self, proyecto, titulo, estado, asignado, descripcion,
        days, now, orden=0, esperando=None, historial=(),
    ):
        obj, _ = GP_Tarea.objects.update_or_create(
            proyecto=proyecto,
            titulo=titulo,
            defaults={
                'descripcion': descripcion,
                'estado': estado,
                'asignado_a': asignado,
                'esperando': esperando or [],
                'orden': orden,
            },
        )
        when = now - timedelta(days=days)
        GP_Tarea.objects.filter(pk=obj.pk).update(created_at=when, updated_at=when)
        for anterior, nuevo, hace in historial:
            self._historial(TipoEntidad.TAREA, obj.id, anterior, nuevo, asignado, hace, now)
        return obj

    def _ticket(
        self, titulo, estado, prioridad, sistema, reportado, asignado, proyecto,
        area_id, descripcion, days, now, historial=(),
    ):
        obj, _ = GP_Ticket.objects.update_or_create(
            titulo=titulo,
            defaults={
                'descripcion': descripcion,
                'area_id': area_id,
                'sistema_afectado': sistema,
                'estado': estado,
                'prioridad': prioridad,
                'impacto': prioridad,
                'reportado_por': reportado,
                'asignado_a': asignado,
                'proyecto': proyecto,
            },
        )
        when = now - timedelta(days=days)
        GP_Ticket.objects.filter(pk=obj.pk).update(
            fecha_creacion=when,
            fecha_actualizacion=when,
        )
        for anterior, nuevo, hace in historial:
            self._historial(
                TipoEntidad.TICKET, obj.id, anterior, nuevo, asignado or reportado, hace, now,
            )
        return obj

    def _historial(self, tipo, ref_id, anterior, nuevo, usuario, days, now):
        obj, _ = GP_HistorialEstado.objects.get_or_create(
            tipo=tipo,
            ref_id=ref_id,
            estado_anterior=anterior,
            estado_nuevo=nuevo,
            defaults={'usuario': usuario},
        )
        GP_HistorialEstado.objects.filter(pk=obj.pk).update(
            usuario=usuario,
            fecha=now - timedelta(days=days),
        )

    def _comentario(self, tipo, ref_id, autor, cuerpo, days, now):
        obj, _ = GP_Comentario.objects.get_or_create(
            tipo=tipo,
            ref_id=ref_id,
            cuerpo=cuerpo,
            defaults={'autor': autor},
        )
        GP_Comentario.objects.filter(pk=obj.pk).update(
            autor=autor,
            fecha_creacion=now - timedelta(days=days),
        )
