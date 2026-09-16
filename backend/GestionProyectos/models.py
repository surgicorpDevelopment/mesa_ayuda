from django.conf import settings
from django.db import models


class Prioridad(models.TextChoices):
    ALTA = 'alta', 'Alta'
    MEDIA = 'media', 'Media'
    BAJA = 'baja', 'Baja'


class EstadoProyecto(models.TextChoices):
    IDEA = 'idea', 'En Idea'
    PLANIFICADO = 'planificado', 'Planificado'
    EN_PROCESO = 'en_proceso', 'En Proceso'
    PAUSADO = 'pausado', 'Pausado'
    COMPLETADO = 'completado', 'Completado'
    CANCELADO = 'cancelado', 'Cancelado'


class EstadoTicket(models.TextChoices):
    NUEVO = 'nuevo', 'Nuevo'
    EN_PROCESO = 'en_proceso', 'En Proceso'
    ESPERANDO = 'esperando', 'Esperando'
    RESUELTO = 'resuelto', 'Resuelto'
    CERRADO = 'cerrado', 'Cerrado'


class EstadoTarea(models.TextChoices):
    PENDIENTE   = 'pendiente',   'Pendiente'
    EN_PROGRESO = 'en_progreso', 'En progreso'
    HECHO       = 'hecho',       'Hecho'


class TipoEntidad(models.TextChoices):
    PROYECTO = 'proyecto', 'Proyecto'
    TICKET = 'ticket', 'Ticket'
    TAREA = 'tarea', 'Tarea'


class GP_Sistema(models.Model):
    """Catálogo editable de aplicaciones / sistemas afectados por tickets."""

    codigo = models.CharField(
        max_length=80,
        unique=True,
        help_text='Clave estable: hoja_picking, vacaciones, power_apps…',
    )
    nombre = models.CharField(max_length=120)
    descripcion = models.CharField(max_length=255, blank=True, default='')
    activo = models.BooleanField(default=True, db_index=True)
    orden = models.PositiveIntegerField(default=100, db_index=True)
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'GP_Sistema'
        ordering = ['orden', 'nombre']
        verbose_name = 'Sistema / aplicación'
        verbose_name_plural = 'Sistemas / aplicaciones'

    def __str__(self):
        return self.nombre


class GP_Proyecto(models.Model):
    titulo = models.CharField(max_length=255)
    descripcion = models.TextField(blank=True, default='')
    area_id = models.IntegerField(
        null=True,
        blank=True,
        help_text='FK lógica a EU_Area.id',
        db_index=True,
    )
    estado = models.CharField(
        max_length=20,
        choices=EstadoProyecto.choices,
        default=EstadoProyecto.IDEA,
        db_index=True,
    )
    prioridad = models.CharField(
        max_length=10,
        choices=Prioridad.choices,
        default=Prioridad.MEDIA,
        db_index=True,
    )
    responsable = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='gp_proyectos_responsable',
    )
    creado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='gp_proyectos_creados',
    )
    fecha_inicio = models.DateField(null=True, blank=True)
    fecha_objetivo = models.DateField(
        null=True,
        blank=True,
        help_text='Fecha fin planificada del proyecto',
    )
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'GP_Proyecto'
        ordering = ['-fecha_actualizacion']
        verbose_name = 'Proyecto'
        verbose_name_plural = 'Proyectos'

    def __str__(self):
        return self.titulo


class GP_Ticket(models.Model):
    titulo = models.CharField(max_length=255)
    descripcion = models.TextField(blank=True, default='')
    area_id = models.IntegerField(
        null=True,
        blank=True,
        help_text='FK lógica a EU_Area.id',
        db_index=True,
    )
    sistema_afectado = models.CharField(
        max_length=100,
        blank=True,
        default='',
        help_text='Código de GP_Sistema.codigo (o texto libre si es "otro")',
        db_index=True,
    )
    estado = models.CharField(
        max_length=20,
        choices=EstadoTicket.choices,
        default=EstadoTicket.NUEVO,
        db_index=True,
    )
    prioridad = models.CharField(
        max_length=10,
        choices=Prioridad.choices,
        default=Prioridad.MEDIA,
        db_index=True,
    )
    impacto = models.CharField(
        max_length=10,
        choices=Prioridad.choices,
        default=Prioridad.MEDIA,
    )
    reportado_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='gp_tickets_reportados',
    )
    asignado_a = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='gp_tickets_asignados',
    )
    proyecto = models.ForeignKey(
        GP_Proyecto,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='tickets',
    )
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'GP_Ticket'
        ordering = ['-fecha_actualizacion']
        verbose_name = 'Ticket'
        verbose_name_plural = 'Tickets'

    def __str__(self):
        return self.titulo


class GP_Comentario(models.Model):
    tipo = models.CharField(max_length=20, choices=TipoEntidad.choices, db_index=True)
    ref_id = models.PositiveIntegerField(db_index=True)
    autor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='gp_comentarios',
    )
    cuerpo = models.TextField()
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'GP_Comentario'
        ordering = ['fecha_creacion']
        verbose_name = 'Comentario'
        verbose_name_plural = 'Comentarios'
        indexes = [
            models.Index(fields=['tipo', 'ref_id'], name='GP_Comentar_tipo_8f3b2e_idx'),
        ]

    def __str__(self):
        return f'{self.tipo}:{self.ref_id} — {self.cuerpo[:40]}'


class GP_HistorialEstado(models.Model):
    tipo = models.CharField(max_length=20, choices=TipoEntidad.choices, db_index=True)
    ref_id = models.PositiveIntegerField(db_index=True)
    estado_anterior = models.CharField(max_length=20, blank=True, default='')
    estado_nuevo = models.CharField(max_length=20)
    usuario = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='gp_historial',
    )
    fecha = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'GP_HistorialEstado'
        ordering = ['-fecha']
        verbose_name = 'Historial de estado'
        verbose_name_plural = 'Historial de estados'
        indexes = [
            models.Index(fields=['tipo', 'ref_id'], name='GP_Historia_tipo_5d2a1c_idx'),
        ]

    def __str__(self):
        return f'{self.tipo}:{self.ref_id} {self.estado_anterior}→{self.estado_nuevo}'


class GP_TicketAdjunto(models.Model):
    ticket = models.ForeignKey(
        GP_Ticket,
        on_delete=models.CASCADE,
        related_name='adjuntos',
    )
    nombre = models.CharField(max_length=255)
    archivo = models.FileField(upload_to='gp_tickets/%Y/%m/')
    mime_type = models.CharField(max_length=100, blank=True, default='')
    size_bytes = models.PositiveIntegerField(default=0)
    subido_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='gp_adjuntos',
    )
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'GP_TicketAdjunto'
        ordering = ['fecha_creacion']
        verbose_name = 'Adjunto de ticket'
        verbose_name_plural = 'Adjuntos de ticket'

    def __str__(self):
        return self.nombre


class GP_Tarea(models.Model):
    """Pieza de trabajo dentro de un proyecto (tablero Kanban)."""

    proyecto = models.ForeignKey(
        GP_Proyecto,
        on_delete=models.CASCADE,
        related_name='tareas',
    )
    titulo = models.CharField(max_length=200)
    descripcion = models.TextField(blank=True, default='')
    estado = models.CharField(
        max_length=20,
        choices=EstadoTarea.choices,
        default=EstadoTarea.PENDIENTE,
        db_index=True,
    )
    asignado_a = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='gp_tareas_asignadas',
    )
    orden = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'GP_Tarea'
        ordering = ['orden', 'created_at']
        verbose_name = 'Tarea'
        verbose_name_plural = 'Tareas'

    def __str__(self):
        return self.titulo


class GP_ProyectoAdjunto(models.Model):
    """Archivo adjunto de un proyecto (planos, specs, referencias, etc.)."""

    proyecto = models.ForeignKey(
        GP_Proyecto,
        on_delete=models.CASCADE,
        related_name='adjuntos',
    )
    nombre = models.CharField(max_length=255)
    archivo = models.FileField(upload_to='gp_proyectos/%Y/%m/')
    mime_type = models.CharField(max_length=100, blank=True, default='')
    size_bytes = models.PositiveIntegerField(default=0)
    subido_por = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='gp_proyectos_adjuntos',
    )
    fecha_creacion = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'GP_ProyectoAdjunto'
        ordering = ['fecha_creacion']
        verbose_name = 'Adjunto de proyecto'
        verbose_name_plural = 'Adjuntos de proyecto'

    def __str__(self):
        return self.nombre
