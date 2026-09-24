"""
Reglas de visibilidad por rol compartidas por todos los ViewSets de la app.

Antes vivían dentro de GP_ProyectoViewSet y GP_TicketViewSet; los recursos
genéricos (comentarios, historial) y las tareas no las aplicaban.
"""

from django.db.models import Q

from .models import EstadoTicket, GP_Proyecto, GP_Tarea, GP_Ticket
from .permissions import get_user_area_id, is_desarrollador, is_gestor, is_lider

# Cola helpdesk: aprobados y sin asignar. Por aprobar y rechazados no entran.
Q_COLA_SIN_ASIGNAR = Q(asignado_a__isnull=True) & ~Q(
    estado__in=[
        EstadoTicket.POR_APROBAR,
        EstadoTicket.RECHAZADO,
        EstadoTicket.RESUELTO,
        EstadoTicket.CERRADO,
    ]
)


def visible_proyectos(user):
    """Gestor ve todo; líder su área y los suyos; desarrollador los suyos y los de su área."""
    qs = GP_Proyecto.objects.select_related('responsable', 'creado_por').all()
    if is_gestor(user):
        return qs
    area_id = get_user_area_id(user)
    if is_lider(user) and area_id is not None:
        return qs.filter(Q(area_id=area_id) | Q(responsable=user) | Q(creado_por=user))
    if is_desarrollador(user):
        q = Q(responsable=user)
        if area_id is not None:
            q |= Q(area_id=area_id)
        return qs.filter(q)
    return qs.none()


# Pendientes de aprobación: los ve cualquier desarrollador, no solo el área.
Q_POR_APROBAR = Q(estado=EstadoTicket.POR_APROBAR)


def visible_tickets(user):
    """Desarrollador+ ve los suyos, los de su área, la cola y los por aprobar."""
    qs = GP_Ticket.objects.select_related(
        'reportado_por', 'asignado_a', 'proyecto', 'aprobado_por', 'autorizado_por',
    ).all()
    if is_gestor(user):
        return qs
    area_id = get_user_area_id(user)
    if is_lider(user):
        q = Q(reportado_por=user) | Q(asignado_a=user) | Q_COLA_SIN_ASIGNAR | Q_POR_APROBAR
        if area_id is not None:
            q |= Q(area_id=area_id)
        return qs.filter(q)
    if is_desarrollador(user):
        q = (
            Q(asignado_a=user)
            | Q(reportado_por=user)
            | Q_COLA_SIN_ASIGNAR
            | Q_POR_APROBAR
        )
        if area_id is not None:
            q |= Q(area_id=area_id)
        return qs.filter(q)
    return qs.filter(reportado_por=user)


def visible_tareas(user):
    """Una tarea se ve si se ve su proyecto."""
    return GP_Tarea.objects.select_related('proyecto', 'asignado_a').filter(
        proyecto_id__in=visible_proyectos(user).values('id')
    )
