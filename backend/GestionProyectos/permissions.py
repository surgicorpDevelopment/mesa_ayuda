"""
Roles del MVP (Django Groups):
  - gp_usuario
  - gp_desarrollador
  - gp_lider_area
  - gp_gestor_proyectos
"""

from rest_framework.permissions import BasePermission, SAFE_METHODS

GROUP_USUARIO = 'gp_usuario'
GROUP_DESARROLLADOR = 'gp_desarrollador'
GROUP_LIDER_AREA = 'gp_lider_area'
GROUP_GESTOR = 'gp_gestor_proyectos'

ALL_GP_GROUPS = (
    GROUP_USUARIO,
    GROUP_DESARROLLADOR,
    GROUP_LIDER_AREA,
    GROUP_GESTOR,
)


def user_group_names(user):
    if not user or not user.is_authenticated:
        return set()
    return set(user.groups.values_list('name', flat=True))


def is_gestor(user):
    if user and user.is_superuser:
        return True
    return GROUP_GESTOR in user_group_names(user)


def is_lider(user):
    return GROUP_LIDER_AREA in user_group_names(user) or is_gestor(user)


def is_desarrollador(user):
    names = user_group_names(user)
    return (
        GROUP_DESARROLLADOR in names
        or GROUP_LIDER_AREA in names
        or GROUP_GESTOR in names
        or (user and user.is_superuser)
    )


def get_user_area_id(user):
    """Obtiene area_id desde ExtendedUsers si existe; si no, None."""
    if not user or not user.is_authenticated:
        return None
    # ExtendedUsers suele ser AUTH_USER_MODEL o OneToOne
    area = getattr(user, 'area_id', None)
    if area is None:
        return None
    # Puede ser int o objeto relacionado
    if hasattr(area, 'id'):
        return area.id
    if isinstance(area, dict):
        return area.get('id')
    try:
        return int(area)
    except (TypeError, ValueError):
        return None


class IsGPAuthenticated(BasePermission):
    """JWT requerido. Staff/superuser siempre OK."""

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)


class CanManageProyectos(BasePermission):
    """Crear/editar proyectos: líder o gestor. Lectura: desarrollador+."""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.method in SAFE_METHODS:
            return is_desarrollador(request.user) or is_gestor(request.user)
        return is_lider(request.user)


class CanManageTareas(BasePermission):
    """Tablero Kanban: desarrollador+ lee y escribe; borrar queda para líder o gestor."""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.method == 'DELETE':
            return is_lider(request.user)
        return is_desarrollador(request.user)


class CanManageTickets(BasePermission):
    """Cualquier autenticado puede crear/listar (queryset filtra). Escritura avanzada en object."""

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)


class CanManageSistemas(BasePermission):
    """Lectura: cualquier autenticado. Alta/edición: gestor o staff."""

    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.method in SAFE_METHODS:
            return True
        return is_gestor(request.user) or bool(request.user.is_staff)
