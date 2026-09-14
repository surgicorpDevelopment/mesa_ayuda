from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('GestionProyectos', '0003_gp_proyectoadjunto'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='GP_Tarea',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('titulo', models.CharField(max_length=200)),
                ('descripcion', models.TextField(blank=True, default='')),
                ('estado', models.CharField(
                    choices=[('pendiente', 'Pendiente'), ('en_progreso', 'En progreso'), ('hecho', 'Hecho')],
                    default='pendiente',
                    max_length=20,
                    db_index=True,
                )),
                ('orden', models.IntegerField(default=0)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('asignado_a', models.ForeignKey(
                    blank=True,
                    null=True,
                    on_delete=django.db.models.deletion.SET_NULL,
                    related_name='gp_tareas_asignadas',
                    to=settings.AUTH_USER_MODEL,
                )),
                ('proyecto', models.ForeignKey(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='tareas',
                    to='GestionProyectos.gp_proyecto',
                )),
            ],
            options={
                'verbose_name': 'Tarea',
                'verbose_name_plural': 'Tareas',
                'db_table': 'GP_Tarea',
                'ordering': ['orden', 'created_at'],
            },
        ),
    ]
