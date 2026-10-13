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
    """Gestor y desarrollador ven todos los proyectos: al dev le piden revisar cualquiera.
    El líder ve su área y los que creó o de los que es responsable."""
    qs = GP_Proyecto.objects.select_related('responsable', 'creado_por').all()
    if is_gestor(user) or (is_desarrollador(user) and not is_lider(user)):
        return qs
    if is_lider(user):
        area_id = get_user_area_id(user)
        q = Q(responsable=user) | Q(creado_por=user)
        if area_id is not None:
            q |= Q(area_id=area_id)
        return qs.filter(q)
    return qs.none()


# Pendientes de aprobación: los ve cualquier desarrollador, no solo el área.
Q_POR_APROBAR = Q(estado=EstadoTicket.POR_APROBAR)


def visible_tickets(user):
    """El desarrollador ve todos los tickets. El líder, los de su área, la cola y los suyos."""
    qs = GP_Ticket.objects.select_related(
        'reportado_por', 'asignado_a', 'proyecto', 'aprobado_por', 'autorizado_por',
    ).all()
    if is_gestor(user) or (is_desarrollador(user) and not is_lider(user)):
        return qs
    area_id = get_user_area_id(user)
    if is_lider(user):
        q = Q(reportado_por=user) | Q(asignado_a=user) | Q_COLA_SIN_ASIGNAR | Q_POR_APROBAR
        if area_id is not None:
            q |= Q(area_id=area_id)
        return qs.filter(q)
    return qs.filter(reportado_por=user)


def visible_tareas(user):
    """Una tarea se ve si se ve su proyecto."""
    return GP_Tarea.objects.select_related('proyecto', 'asignado_a').filter(
        proyecto_id__in=visible_proyectos(user).values('id')
    )
