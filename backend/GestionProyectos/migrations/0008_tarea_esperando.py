from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('GestionProyectos', '0007_proyecto_fecha_inicio'),
    ]

    operations = [
        migrations.AddField(
            model_name='gp_tarea',
            name='esperando',
            field=models.JSONField(
                blank=True,
                default=list,
                help_text='Personas de las que depende la tarea: [{nombre, usuario_id?}, ...]',
            ),
        ),
    ]
