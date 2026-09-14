from django.apps import AppConfig


class LocaldevConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'localdev'
    verbose_name = 'Harness local (no producción)'
