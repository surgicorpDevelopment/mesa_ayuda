from __future__ import annotations

from django.apps import apps
from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import GP_Comentario, GP_HistorialEstado, GP_Proyecto, GP_ProyectoAdjunto, GP_Sistema, GP_Tarea, GP_Ticket, GP_TicketAdjunto, TipoEntidad

User = get_user_model()

_AREA_CACHE = {}


def _area_nombre(area_id):
    """Resuelve EU_Area.nombre sin acoplar GestionProyectos a un app label fijo."""
    if area_id is None:
        return None
    if area_id in _AREA_CACHE:
        return _AREA_CACHE[area_id]
    nombre = None
    for model in apps.get_models():
        if model.__name__ != 'EU_Area' and getattr(model._meta, 'db_table', '') != 'EU_Area':
            continue
        nombre = model.objects.filter(pk=area_id).values_list('nombre', flat=True).first()
        if nombre:
            break
    _AREA_CACHE[area_id] = nombre
    return nombre


class UserMiniSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'full_name', 'email']

    def get_full_name(self, obj):
        name = f'{obj.first_name or ""} {obj.last_name or ""}'.strip()
        return name or obj.username


class GP_SistemaSerializer(serializers.ModelSerializer):
    class Meta:
        model = GP_Sistema
        fields = [
            'id',
            'codigo',
            'nombre',
            'descripcion',
            'activo',
            'orden',
            'fecha_creacion',
            'fecha_actualizacion',
        ]
        read_only_fields = ['fecha_creacion', 'fecha_actualizacion']


class GP_ProyectoAdjuntoSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = GP_ProyectoAdjunto
        fields = ['id', 'nombre', 'url', 'mime_type', 'size_bytes', 'fecha_creacion']
        read_only_fields = fields

    def get_url(self, obj):
        request = self.context.get('request')
        if request and obj.archivo:
            return request.build_absolute_uri(obj.archivo.url)
        return None


class GP_ProyectoSerializer(serializers.ModelSerializer):
    responsable_detail = UserMiniSerializer(source='responsable', read_only=True)
    creado_por_detail = UserMiniSerializer(source='creado_por', read_only=True)
    tickets_count = serializers.IntegerField(source='tickets.count', read_only=True)
    adjuntos = GP_ProyectoAdjuntoSerializer(many=True, read_only=True)
    area_nombre = serializers.SerializerMethodField()

    class Meta:
        model = GP_Proyecto
        fields = [
            'id',
            'titulo',
            'descripcion',
            'area_id',
            'area_nombre',
            'estado',
            'prioridad',
            'responsable',
            'responsable_detail',
            'creado_por',
            'creado_por_detail',
            'adjuntos',
            'fecha_inicio',
            'fecha_objetivo',
            'fecha_creacion',
            'fecha_actualizacion',
            'tickets_count',
        ]
        read_only_fields = ['creado_por', 'fecha_creacion', 'fecha_actualizacion', 'area_nombre']

    def get_area_nombre(self, obj):
        return _area_nombre(obj.area_id)

    def validate(self, attrs):
        instance = self.instance
        inicio = attrs.get(
            'fecha_inicio',
            getattr(instance, 'fecha_inicio', None) if instance is not None else None,
        )
        fin = attrs.get(
            'fecha_objetivo',
            getattr(instance, 'fecha_objetivo', None) if instance is not None else None,
        )
        if inicio and fin and inicio > fin:
            raise serializers.ValidationError(
                {'fecha_inicio': 'La fecha de inicio no puede ser posterior a la fecha fin.'}
            )
        return attrs


class GP_TareaSerializer(serializers.ModelSerializer):
    asignado_a_nombre = serializers.SerializerMethodField()

    class Meta:
        model = GP_Tarea
        fields = [
            'id',
            'titulo',
            'descripcion',
            'estado',
            'asignado_a',
            'asignado_a_nombre',
            'orden',
            'proyecto',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['created_at', 'updated_at', 'asignado_a_nombre']

    def get_asignado_a_nombre(self, obj):
        u = obj.asignado_a
        if u is None:
            return None
        name = f'{u.first_name or ""} {u.last_name or ""}'.strip()
        return name or u.username


class GP_TicketAdjuntoSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = GP_TicketAdjunto
        fields = ['id', 'nombre', 'url', 'mime_type', 'size_bytes', 'fecha_creacion']
        read_only_fields = fields

    def get_url(self, obj):
        request = self.context.get('request')
        if request and obj.archivo:
            return request.build_absolute_uri(obj.archivo.url)
        return None


class GP_TicketSerializer(serializers.ModelSerializer):
    reportado_por_detail = UserMiniSerializer(source='reportado_por', read_only=True)
    asignado_a_detail = UserMiniSerializer(source='asignado_a', read_only=True)
    proyecto_titulo = serializers.CharField(source='proyecto.titulo', read_only=True, default=None)
    adjuntos = GP_TicketAdjuntoSerializer(many=True, read_only=True)

    class Meta:
        model = GP_Ticket
        fields = [
            'id',
            'titulo',
            'descripcion',
            'area_id',
            'sistema_afectado',
            'estado',
            'prioridad',
            'impacto',
            'reportado_por',
            'reportado_por_detail',
            'asignado_a',
            'asignado_a_detail',
            'proyecto',
            'proyecto_titulo',
            'adjuntos',
            'fecha_creacion',
            'fecha_actualizacion',
        ]
        read_only_fields = ['reportado_por', 'fecha_creacion', 'fecha_actualizacion']


class GP_ComentarioSerializer(serializers.ModelSerializer):
    autor_detail = UserMiniSerializer(source='autor', read_only=True)

    class Meta:
        model = GP_Comentario
        fields = [
            'id',
            'tipo',
            'ref_id',
            'autor',
            'autor_detail',
            'cuerpo',
            'fecha_creacion',
        ]
        read_only_fields = ['autor', 'fecha_creacion']

    def validate(self, attrs):
        tipo = attrs.get('tipo')
        ref_id = attrs.get('ref_id')
        if tipo == TipoEntidad.PROYECTO and not GP_Proyecto.objects.filter(pk=ref_id).exists():
            raise serializers.ValidationError({'ref_id': 'Proyecto no encontrado.'})
        if tipo == TipoEntidad.TICKET and not GP_Ticket.objects.filter(pk=ref_id).exists():
            raise serializers.ValidationError({'ref_id': 'Ticket no encontrado.'})
        if tipo == TipoEntidad.TAREA and not GP_Tarea.objects.filter(pk=ref_id).exists():
            raise serializers.ValidationError({'ref_id': 'Tarea no encontrada.'})
        return attrs


class GP_HistorialEstadoSerializer(serializers.ModelSerializer):
    usuario_detail = UserMiniSerializer(source='usuario', read_only=True)

    class Meta:
        model = GP_HistorialEstado
        fields = [
            'id',
            'tipo',
            'ref_id',
            'estado_anterior',
            'estado_nuevo',
            'usuario',
            'usuario_detail',
            'fecha',
        ]
        read_only_fields = fields
