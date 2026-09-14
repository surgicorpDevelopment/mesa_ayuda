from django.core.management.base import BaseCommand

from GestionProyectos.models import GP_Sistema

# Semilla inicial (puedes ampliar/editar después en /admin o POST /GP_Sistema/)
SEED = [
    ('hoja_picking', 'Hoja de Picking', '', 10),
    ('rotulado_bultos', 'Rotulado de Bultos', '', 20),
    ('vacaciones', 'Vacaciones', '', 30),
    ('caja_chica', 'Caja Chica', '', 40),
    ('stock_inventario', 'Stock / Inventario', '', 50),
    ('licitaciones', 'Licitaciones', '', 60),
    ('comisiones', 'Comisiones', '', 70),
    ('cotizaciones', 'Cotizaciones', '', 80),
    ('facturacion', 'Facturación', '', 90),
    ('whatsapp', 'WhatsApp / Integraciones', '', 100),
    ('power_apps', 'Power Apps (apps de negocio)', 'Cubre las apps de Power Platform', 110),
    ('erp', 'ERP / Guías / Pedidos', '', 120),
    ('n8n', 'Automatizaciones (n8n)', '', 130),
    ('otro', 'Otro…', 'Texto libre en el ticket', 999),
]


class Command(BaseCommand):
    help = 'Carga el catálogo inicial de GP_Sistema (no duplica códigos existentes).'

    def handle(self, *args, **options):
        created = 0
        for codigo, nombre, descripcion, orden in SEED:
            obj, was_created = GP_Sistema.objects.get_or_create(
                codigo=codigo,
                defaults={
                    'nombre': nombre,
                    'descripcion': descripcion,
                    'orden': orden,
                    'activo': True,
                },
            )
            if was_created:
                created += 1
                self.stdout.write(self.style.SUCCESS(f'+ {codigo}'))
            else:
                self.stdout.write(f'= {codigo} (ya existe)')
        self.stdout.write(self.style.SUCCESS(f'Listo. Nuevos: {created}'))
