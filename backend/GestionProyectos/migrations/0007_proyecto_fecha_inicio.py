from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('GestionProyectos', '0006_gp_ticketadjunto'),
    ]

    operations = [
        migrations.AddField(
            model_name='gp_proyecto',
            name='fecha_inicio',
            field=models.DateField(blank=True, null=True),
        ),
        migrations.AlterField(
            model_name='gp_proyecto',
            name='fecha_objetivo',
            field=models.DateField(
                blank=True,
                help_text='Fecha fin planificada del proyecto',
                null=True,
            ),
        ),
    ]
