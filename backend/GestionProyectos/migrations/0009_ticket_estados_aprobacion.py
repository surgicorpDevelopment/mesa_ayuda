from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('GestionProyectos', '0008_tarea_esperando'),
    ]

    operations = [
        migrations.AlterField(
            model_name='gp_ticket',
            name='estado',
            field=models.CharField(
                choices=[
                    ('por_aprobar', 'Por aprobar'),
                    ('nuevo', 'Nuevo'),
                    ('en_proceso', 'En Proceso'),
                    ('esperando', 'Esperando'),
                    ('resuelto', 'Resuelto'),
                    ('rechazado', 'Rechazado'),
                    ('cerrado', 'Cerrado'),
                ],
                db_index=True,
                default='nuevo',
                max_length=20,
            ),
        ),
    ]
