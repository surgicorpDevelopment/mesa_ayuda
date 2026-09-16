from django.contrib import admin

from .models import (
    GP_Comentario,
    GP_HistorialEstado,
    GP_Proyecto,
    GP_Sistema,
    GP_Ticket,
    GP_TicketAdjunto,
)


@admin.register(GP_Sistema)
class GP_SistemaAdmin(admin.ModelAdmin):
    list_display = ('id', 'orden', 'codigo', 'nombre', 'activo', 'fecha_actualizacion')
    list_filter = ('activo',)
    search_fields = ('codigo', 'nombre', 'descripcion')
    list_editable = ('orden', 'activo')
    ordering = ('orden', 'nombre')


@admin.register(GP_Proyecto)
class GP_ProyectoAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'titulo',
        'estado',
        'prioridad',
        'area_id',
        'responsable',
        'fecha_inicio',
        'fecha_objetivo',
        'fecha_actualizacion',
    )
    list_filter = ('estado', 'prioridad', 'area_id')
    search_fields = ('titulo', 'descripcion')


@admin.register(GP_Ticket)
class GP_TicketAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'titulo',
        'estado',
        'prioridad',
        'sistema_afectado',
        'reportado_por',
        'asignado_a',
        'fecha_actualizacion',
    )
    list_filter = ('estado', 'prioridad', 'sistema_afectado', 'area_id')
    search_fields = ('titulo', 'descripcion')


@admin.register(GP_TicketAdjunto)
class GP_TicketAdjuntoAdmin(admin.ModelAdmin):
    list_display = ('id', 'ticket', 'nombre', 'mime_type', 'size_bytes', 'fecha_creacion')
    search_fields = ('nombre',)


@admin.register(GP_Comentario)
class GP_ComentarioAdmin(admin.ModelAdmin):
    list_display = ('id', 'tipo', 'ref_id', 'autor', 'fecha_creacion')
    list_filter = ('tipo',)


@admin.register(GP_HistorialEstado)
class GP_HistorialEstadoAdmin(admin.ModelAdmin):
    list_display = ('id', 'tipo', 'ref_id', 'estado_anterior', 'estado_nuevo', 'usuario', 'fecha')
    list_filter = ('tipo',)
