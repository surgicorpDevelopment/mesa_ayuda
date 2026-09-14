from django.contrib.auth.models import AbstractUser
from django.db import models


class ExtendedUser(AbstractUser):
    """Stub de ExtendedUsers: area / area_id / puesto para GP_Usuario/me y scoping."""

    area = models.CharField(max_length=120, blank=True, default='')
    area_id = models.IntegerField(null=True, blank=True)
    puesto = models.CharField(max_length=120, blank=True, default='')

    class Meta:
        verbose_name = 'usuario'
        verbose_name_plural = 'usuarios'

    def __str__(self):
        full = self.get_full_name().strip()
        return full or self.username


class EU_Area(models.Model):
    """Catálogo mínimo que el frontend consulta en GET /EU_Area/."""

    nombre = models.CharField(max_length=120, unique=True)

    class Meta:
        db_table = 'EU_Area'
        ordering = ['nombre']
        verbose_name = 'Área'
        verbose_name_plural = 'Áreas'

    def __str__(self):
        return self.nombre
