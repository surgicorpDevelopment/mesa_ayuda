import os

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import get_user_model
from django.db.models import Q
from django.utils.dateparse import parse_date

from .models import (
    EstadoTicket,
    GP_Comentario,
    GP_HistorialEstado,
    GP_ProyectoAdjunto,
    GP_Sistema,
    GP_Tarea,
    GP_Ticket,
    GP_TicketAdjunto,
    TipoEntidad,
)
from .permissions import (
    CanManageProyectos,
    CanManageSistemas,
    CanManageTareas,
    CanManageTickets,
    GROUP_DESARROLLADOR,
    GROUP_GESTOR,
    GROUP_LIDER_AREA,
    get_user_area_id,
    is_desarrollador,
    is_gestor,
    is_lider,
)
from .scoping import (
    Q_COLA_SIN_ASIGNAR,
    visible_proyectos,
    visible_tareas,
    visible_tickets,
)
from .serializers import (
    GP_ComentarioSerializer,
    GP_HistorialEstadoSerializer,
    GP_ProyectoAdjuntoSerializer,
    GP_ProyectoSerializer,
    GP_SistemaSerializer,
    GP_TareaSerializer,
    GP_TicketAdjuntoSerializer,
    GP_TicketSerializer,
)

User = get_user_model()

_ALLOWED_ATTACHMENT_EXTS = {
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
    '.bmp',
    '.pdf',
    '.doc',
    '.docx',
}


def _reject_if_invalid_adjunto(archivo):
    name = archivo.name or ''
    ext = os.path.splitext(name)[1].lower()
    if ext not in _ALLOWED_ATTACHMENT_EXTS:
        return Response(
            {
                'detail': (
                    'Tipo de archivo no permitido. '
                    'Usa imágenes (PNG, JPG), PDF o Word (DOC, DOCX).'
                )
            },
            status=status.HTTP_400_BAD_REQUEST,
        )
    return None


def _scoped_generic(qs, user):
    """Filtra una tabla genérica (tipo, ref_id) por las entidades que el usuario puede ver."""
    return qs.filter(
        Q(tipo=TipoEntidad.TICKET, ref_id__in=visible_tickets(user).values('id'))
        | Q(tipo=TipoEntidad.PROYECTO, ref_id__in=visible_proyectos(user).values('id'))
        | Q(tipo=TipoEntidad.TAREA, ref_id__in=visible_tareas(user).values('id'))
    )


def _puede_ver_ref(user, tipo, ref_id):
    if tipo == TipoEntidad.TICKET:
        return visible_tickets(user).filter(pk=ref_id).exists()
    if tipo == TipoEntidad.PROYECTO:
        return visible_proyectos(user).filter(pk=ref_id).exists()
    if tipo == TipoEntidad.TAREA:
        return visible_tareas(user).filter(pk=ref_id).exists()
    return False


def _record_estado_change(tipo, ref_id, estado_anterior, estado_nuevo, usuario):
    if estado_anterior == estado_nuevo:
        return
    GP_HistorialEstado.objects.create(
        tipo=tipo,
        ref_id=ref_id,
        estado_anterior=estado_anterior or '',
        estado_nuevo=estado_nuevo,
        usuario=usuario,
    )


class GP_ProyectoViewSet(viewsets.ModelViewSet):
    serializer_class = GP_ProyectoSerializer
    permission_classes = [IsAuthenticated, CanManageProyectos]
    filterset_fields = ['estado', 'area_id', 'responsable', 'prioridad']
    search_fields = ['titulo', 'descripcion']
    ordering_fields = ['fecha_actualizacion', 'fecha_creacion', 'prioridad', 'titulo']

    def get_queryset(self):
        return visible_proyectos(self.request.user)

    def perform_create(self, serializer):
        obj = serializer.save(creado_por=self.request.user)
        _record_estado_change(
            TipoEntidad.PROYECTO, obj.id, '', obj.estado, self.request.user
        )

    def perform_update(self, serializer):
        instance = self.get_object()
        prev = instance.estado
        obj = serializer.save()
        if prev != obj.estado:
            _record_estado_change(
                TipoEntidad.PROYECTO, obj.id, prev, obj.estado, self.request.user
            )

    @action(
        detail=True,
        methods=['post'],
        url_path='adjuntos',
        parser_classes=[MultiPartParser, FormParser],
    )
    def add_adjunto(self, request, pk=None):
        """Sube un archivo adjunto al proyecto (multipart/form-data, campo 'archivo')."""
        proyecto = self.get_object()
        archivo = request.FILES.get('archivo')
        if not archivo:
            return Response({'detail': 'Se requiere el campo "archivo".'}, status=status.HTTP_400_BAD_REQUEST)
        rejected = _reject_if_invalid_adjunto(archivo)
        if rejected is not None:
            return rejected
        adj = GP_ProyectoAdjunto.objects.create(
            proyecto=proyecto,
            nombre=archivo.name,
            archivo=archivo,
            mime_type=archivo.content_type or '',
            size_bytes=archivo.size,
            subido_por=request.user,
        )
        serializer = GP_ProyectoAdjuntoSerializer(adj, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['delete'], url_path=r'adjuntos/(?P<adj_id>\d+)')
    def remove_adjunto(self, request, pk=None, adj_id=None):
        """Elimina un adjunto del proyecto."""
        proyecto = self.get_object()
        try:
            adj = GP_ProyectoAdjunto.objects.get(pk=adj_id, proyecto=proyecto)
        except GP_ProyectoAdjunto.DoesNotExist:
            return Response({'detail': 'Adjunto no encontrado.'}, status=status.HTTP_404_NOT_FOUND)
        adj.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class GP_TicketViewSet(viewsets.ModelViewSet):
    serializer_class = GP_TicketSerializer
    permission_classes = [IsAuthenticated, CanManageTickets]
    filterset_fields = [
        'estado',
        'area_id',
        'asignado_a',
        'reportado_por',
        'proyecto',
        'sistema_afectado',
        'prioridad',
        'impacto',
    ]
    search_fields = ['titulo', 'descripcion', 'sistema_afectado']
    ordering_fields = ['fecha_actualizacion', 'fecha_creacion', 'prioridad']

    def get_queryset(self):
        return visible_tickets(self.request.user)

    def perform_create(self, serializer):
        user = self.request.user
        # El usuario final no clasifica prioridad/impacto: lo decide el equipo.
        if not is_desarrollador(user):
            serializer.validated_data.pop('prioridad', None)
            serializer.validated_data.pop('impacto', None)
            serializer.validated_data.pop('asignado_a', None)
            serializer.validated_data.pop('estado', None)
        area_id = serializer.validated_data.get('area_id')
        if area_id is None:
            area_id = get_user_area_id(user)
        ticket = serializer.save(reportado_por=user, area_id=area_id)
        _record_estado_change(
            TipoEntidad.TICKET, ticket.id, '', ticket.estado, user
        )

    def perform_update(self, serializer):
        instance = self.get_object()
        user = self.request.user
        # Usuario genérico solo puede editar título/descripcion de los suyos; no asignar
        if not is_desarrollador(user) and not is_gestor(user):
            allowed = {'titulo', 'descripcion'}
            for field in list(serializer.validated_data.keys()):
                if field not in allowed:
                    serializer.validated_data.pop(field, None)
        prev = instance.estado
        # Solo líder/gestor/dev pueden cambiar asignación y estado
        if not is_desarrollador(user):
            serializer.validated_data.pop('asignado_a', None)
            serializer.validated_data.pop('estado', None)
            serializer.validated_data.pop('prioridad', None)
            serializer.validated_data.pop('impacto', None)
        obj = serializer.save()
        if prev != obj.estado:
            _record_estado_change(
                TipoEntidad.TICKET, obj.id, prev, obj.estado, user
            )

    @action(detail=False, methods=['get'])
    def inbox(self, request):
        """Contadores para el home del frontend."""
        user = request.user
        base = self.get_queryset()
        mis_abiertos = base.filter(
            reportado_por=user
        ).exclude(estado__in=['resuelto', 'cerrado']).count()
        asignados = base.filter(
            asignado_a=user
        ).exclude(estado__in=['resuelto', 'cerrado']).count()
        cola_sin_asignar = 0
        if is_desarrollador(user):
            cola_sin_asignar = base.filter(Q_COLA_SIN_ASIGNAR).count()
        proyectos_activos = visible_proyectos(user).exclude(
            estado__in=['completado', 'cancelado']
        ).count()
        return Response(
            {
                'mis_tickets_abiertos': mis_abiertos,
                'asignados_a_mi': asignados,
                'cola_sin_asignar': cola_sin_asignar,
                'proyectos_activos': proyectos_activos,
            }
        )

    @action(detail=True, methods=['post'])
    def tomar(self, request, pk=None):
        """Asigna el ticket al desarrollador actual (cola helpdesk)."""
        user = request.user
        if not is_desarrollador(user):
            return Response(
                {'detail': 'Solo desarrolladores pueden tomar tickets.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        ticket = self.get_object()
        if ticket.asignado_a_id is not None:
            return Response(
                {'detail': 'El ticket ya está asignado.'},
                status=status.HTTP_409_CONFLICT,
            )
        prev_estado = ticket.estado
        ticket.asignado_a = user
        if ticket.estado == EstadoTicket.NUEVO:
            ticket.estado = EstadoTicket.EN_PROCESO
        ticket.save(update_fields=['asignado_a', 'estado', 'fecha_actualizacion'])
        _record_estado_change(
            TipoEntidad.TICKET, ticket.id, prev_estado, ticket.estado, user
        )
        return Response(GP_TicketSerializer(ticket, context={'request': request}).data)

    @action(
        detail=True,
        methods=['post'],
        url_path='adjuntos',
        parser_classes=[MultiPartParser, FormParser],
    )
    def add_adjunto(self, request, pk=None):
        """Sube un archivo adjunto al ticket (multipart/form-data, campo 'archivo')."""
        ticket = self.get_object()
        archivo = request.FILES.get('archivo')
        if not archivo:
            return Response({'detail': 'Se requiere el campo "archivo".'}, status=status.HTTP_400_BAD_REQUEST)
        rejected = _reject_if_invalid_adjunto(archivo)
        if rejected is not None:
            return rejected
        adj = GP_TicketAdjunto.objects.create(
            ticket=ticket,
            nombre=archivo.name,
            archivo=archivo,
            mime_type=archivo.content_type or '',
            size_bytes=archivo.size,
            subido_por=request.user,
        )
        serializer = GP_TicketAdjuntoSerializer(adj, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['delete'], url_path=r'adjuntos/(?P<adj_id>\d+)')
    def remove_adjunto(self, request, pk=None, adj_id=None):
        """Elimina un adjunto del ticket."""
        ticket = self.get_object()
        try:
            adj = GP_TicketAdjunto.objects.get(pk=adj_id, ticket=ticket)
        except GP_TicketAdjunto.DoesNotExist:
            return Response({'detail': 'Adjunto no encontrado.'}, status=status.HTTP_404_NOT_FOUND)
        adj.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class GP_ComentarioViewSet(viewsets.ModelViewSet):
    serializer_class = GP_ComentarioSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['tipo', 'ref_id', 'autor']
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        return _scoped_generic(
            GP_Comentario.objects.select_related('autor').all(), self.request.user
        )

    def perform_create(self, serializer):
        user = self.request.user
        tipo = serializer.validated_data.get('tipo')
        ref_id = serializer.validated_data.get('ref_id')
        if not _puede_ver_ref(user, tipo, ref_id):
            raise PermissionDenied('No tienes acceso a ese registro.')
        serializer.save(autor=user)


class GP_HistorialEstadoViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = GP_HistorialEstadoSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['tipo', 'ref_id', 'usuario']

    def get_queryset(self):
        return _scoped_generic(
            GP_HistorialEstado.objects.select_related('usuario').all(), self.request.user
        )


class GP_TareaViewSet(viewsets.ModelViewSet):
    """
    CRUD de tareas de un proyecto (tablero Kanban).

    Filtros soportados: ?proyecto=<id>, ?estado=<estado>, ?asignado_a=<id>
    """

    serializer_class = GP_TareaSerializer
    permission_classes = [IsAuthenticated, CanManageTareas]
    filterset_fields = ['proyecto', 'estado', 'asignado_a']
    search_fields = ['titulo', 'descripcion']
    ordering_fields = ['orden', 'created_at']

    def get_queryset(self):
        return visible_tareas(self.request.user)

    def perform_create(self, serializer):
        proyecto = serializer.validated_data.get('proyecto')
        if proyecto is not None and not visible_proyectos(self.request.user).filter(
            pk=proyecto.pk
        ).exists():
            raise PermissionDenied('No tienes acceso a ese proyecto.')
        tarea = serializer.save()
        _record_estado_change(
            TipoEntidad.TAREA, tarea.id, '', tarea.estado, self.request.user
        )

    def perform_update(self, serializer):
        instance = self.get_object()
        prev = instance.estado
        obj = serializer.save()
        if prev != obj.estado:
            _record_estado_change(
                TipoEntidad.TAREA, obj.id, prev, obj.estado, self.request.user
            )


class GP_SistemaViewSet(viewsets.ModelViewSet):
    """Catálogo de sistemas. GET para todos; POST/PATCH/DELETE solo gestor."""

    serializer_class = GP_SistemaSerializer
    permission_classes = [IsAuthenticated, CanManageSistemas]
    filterset_fields = ['activo', 'codigo']
    search_fields = ['codigo', 'nombre', 'descripcion']
    ordering_fields = ['orden', 'nombre', 'codigo']

    def get_queryset(self):
        qs = GP_Sistema.objects.all()
        # Por defecto el frontend pide solo activos; sin filtro se listan todos (admin)
        activo = self.request.query_params.get('activo')
        if activo is None and self.request.method in ('GET', 'HEAD', 'OPTIONS'):
            # Si no es gestor, ocultar inactivos
            if not is_gestor(self.request.user) and not self.request.user.is_staff:
                qs = qs.filter(activo=True)
        return qs


def _user_display_name(user):
    if user is None:
        return None
    name = f'{user.first_name or ""} {user.last_name or ""}'.strip()
    return name or user.username


# De mayor a menor: el primero que coincida es el rol que se muestra.
_ROL_POR_GRUPO = (
    (GROUP_GESTOR, 'Gestor de proyectos'),
    (GROUP_LIDER_AREA, 'Líder de área'),
    (GROUP_DESARROLLADOR, 'Desarrollador'),
)


def _asignables_qs():
    """Usuarios que pueden recibir tickets o tareas: los de los grupos gp_* más superusers."""
    return (
        User.objects.filter(
            Q(groups__name__in=[GROUP_DESARROLLADOR, GROUP_LIDER_AREA, GROUP_GESTOR])
            | Q(is_superuser=True)
        )
        .distinct()
        .order_by('first_name', 'last_name', 'username')
    )


def _rol_display(user, group_names=None):
    names = group_names if group_names is not None else set(
        user.groups.values_list('name', flat=True)
    )
    for grupo, etiqueta in _ROL_POR_GRUPO:
        if grupo in names:
            return etiqueta
    return 'Administrador' if user.is_superuser else ''


def _texto_relacionado(valor):
    """Nombre legible de un campo de ExtendedUsers que puede ser texto o un objeto relacionado."""
    if valor is None or isinstance(valor, (bool, int, float)):
        return None
    return str(valor) or None


class GP_UsuarioViewSet(viewsets.ViewSet):
    """
    Directorio del módulo, para no depender de `/users/` y `/groups/` de ServidorCaminitos.

    GET /GP_Usuario/?q=<texto>  → usuarios asignables (grupos gp_* y superusers)
    GET /GP_Usuario/me/         → perfil del usuario autenticado, con sus grupos y rol efectivo
    """

    permission_classes = [IsAuthenticated]

    def list(self, request):
        qs = _asignables_qs().prefetch_related('groups')
        q = (request.query_params.get('q') or '').strip()
        if q:
            qs = qs.filter(
                Q(first_name__icontains=q)
                | Q(last_name__icontains=q)
                | Q(username__icontains=q)
            )
        return Response(
            [
                {
                    'id': u.id,
                    'username': u.username,
                    'first_name': u.first_name or '',
                    'last_name': u.last_name or '',
                    'full_name': _user_display_name(u),
                    'rol': _rol_display(u, {g.name for g in u.groups.all()}),
                }
                for u in qs
            ]
        )

    @action(detail=False, methods=['get'])
    def me(self, request):
        user = request.user
        group_names = list(user.groups.values_list('name', flat=True))
        return Response(
            {
                'id': user.id,
                'username': user.username,
                'first_name': user.first_name or '',
                'last_name': user.last_name or '',
                'full_name': _user_display_name(user),
                'email': user.email or '',
                'groups': group_names,
                'area': _texto_relacionado(getattr(user, 'area', None)),
                'area_id': get_user_area_id(user),
                'puesto': _texto_relacionado(getattr(user, 'puesto', None)),
                'rol': _rol_display(user, set(group_names)),
                'is_staff': bool(user.is_staff),
                # Calculados con los mismos helpers que autorizan las peticiones,
                # para que el frontend no vuelva a deducir el rol por su cuenta.
                'es_gestor': is_gestor(user),
                'es_lider': is_lider(user),
                'es_desarrollador': is_desarrollador(user),
            }
        )


class GP_ProductividadViewSet(viewsets.ViewSet):
    """
    Ranking y timeline de productividad de desarrolladores.

    GET /GP_Productividad/?desde=YYYY-MM-DD&hasta=YYYY-MM-DD
    """

    permission_classes = [IsAuthenticated]

    def list(self, request):
        if not is_desarrollador(request.user):
            return Response(
                {'detail': 'Solo desarrolladores pueden ver reportes de productividad.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        desde = parse_date(request.query_params.get('desde') or '')
        hasta = parse_date(request.query_params.get('hasta') or '')
        if not desde or not hasta:
            return Response(
                {'detail': 'Se requieren los parámetros desde y hasta (YYYY-MM-DD).'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if hasta < desde:
            return Response(
                {'detail': 'hasta debe ser >= desde.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        from datetime import datetime, time, timedelta
        from django.utils import timezone as dj_tz

        start = dj_tz.make_aware(datetime.combine(desde, time.min))
        end = dj_tz.make_aware(datetime.combine(hasta + timedelta(days=1), time.min))

        historial = (
            GP_HistorialEstado.objects.filter(
                fecha__gte=start,
                fecha__lt=end,
                tipo__in=[TipoEntidad.TICKET, TipoEntidad.TAREA],
            )
            .select_related('usuario')
            .order_by('-fecha')
        )

        ticket_ids = {h.ref_id for h in historial if h.tipo == TipoEntidad.TICKET}
        tarea_ids = {h.ref_id for h in historial if h.tipo == TipoEntidad.TAREA}

        tickets = {
            t.id: t
            for t in GP_Ticket.objects.filter(id__in=ticket_ids).select_related('asignado_a')
        }
        tareas = {
            t.id: t
            for t in GP_Tarea.objects.filter(id__in=tarea_ids).select_related('asignado_a')
        }

        developers = _asignables_qs()
        ranking_map = {}
        for u in developers:
            ranking_map[u.id] = {
                'user_id': u.id,
                'nombre': _user_display_name(u),
                'tareas_hechas': 0,
                'tickets_resueltos': 0,
            }

        def _ensure_ranking(uid, nombre):
            if uid and uid not in ranking_map:
                ranking_map[uid] = {
                    'user_id': uid,
                    'nombre': nombre,
                    'tareas_hechas': 0,
                    'tickets_resueltos': 0,
                }

        actividad = []
        for h in historial:
            # Crédito al asignado de la entidad; si no hay, quien cambió el estado.
            credit_id = h.usuario_id
            credit_nombre = _user_display_name(h.usuario)
            titulo = ''

            if h.tipo == TipoEntidad.TICKET:
                ticket = tickets.get(h.ref_id)
                titulo = ticket.titulo if ticket else f'Ticket #{h.ref_id}'
                if ticket and ticket.asignado_a_id:
                    credit_id = ticket.asignado_a_id
                    credit_nombre = _user_display_name(ticket.asignado_a)
            elif h.tipo == TipoEntidad.TAREA:
                tarea = tareas.get(h.ref_id)
                titulo = tarea.titulo if tarea else f'Tarea #{h.ref_id}'
                if tarea and tarea.asignado_a_id:
                    credit_id = tarea.asignado_a_id
                    credit_nombre = _user_display_name(tarea.asignado_a)

            _ensure_ranking(credit_id, credit_nombre)

            if h.tipo == TipoEntidad.TAREA and h.estado_nuevo == 'hecho' and credit_id:
                ranking_map[credit_id]['tareas_hechas'] += 1
            if (
                h.tipo == TipoEntidad.TICKET
                and h.estado_nuevo in ('resuelto', 'cerrado')
                and credit_id
            ):
                ranking_map[credit_id]['tickets_resueltos'] += 1

            actividad.append({
                'fecha': h.fecha.isoformat(),
                'usuario_id': credit_id,
                'usuario_nombre': credit_nombre,
                'tipo': h.tipo,
                'ref_id': h.ref_id,
                'titulo': titulo,
                'estado_anterior': h.estado_anterior,
                'estado_nuevo': h.estado_nuevo,
            })

        ranking = sorted(
            ranking_map.values(),
            key=lambda r: (r['tareas_hechas'] + r['tickets_resueltos'], r['tareas_hechas']),
            reverse=True,
        )

        return Response({'ranking': ranking, 'actividad': actividad})
