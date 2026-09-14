from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('GestionProyectos', '0004_gp_tarea'),
    ]

    operations = [
        migrations.AlterField(
            model_name='gp_comentario',
            name='tipo',
            field=models.CharField(
                choices=[('proyecto', 'Proyecto'), ('ticket', 'Ticket'), ('tarea', 'Tarea')],
                db_index=True,
                max_length=20,
            ),
        ),
        migrations.AlterField(
            model_name='gp_historialestado',
            name='tipo',
            field=models.CharField(
                choices=[('proyecto', 'Proyecto'), ('ticket', 'Ticket'), ('tarea', 'Tarea')],
                db_index=True,
                max_length=20,
            ),
        ),
    ]
