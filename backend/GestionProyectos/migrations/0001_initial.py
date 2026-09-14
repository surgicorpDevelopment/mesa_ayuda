# Generated manually for drop-in into DjangoNewAPI.
# On the server: python manage.py migrate GestionProyectos  (sin makemigrations)

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        # ExtendedUsers no está en ServidorCaminitos.0001; igual que CajaChica.
        ('ServidorCaminitos', '0170_gr_regularizacion_lima_provincia'),
    ]

    operations = [
        migrations.CreateModel(
            name='GP_Proyecto',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('titulo', models.CharField(max_length=255)),
                ('descripcion', models.TextField(blank=True, default='')),
                ('area_id', models.IntegerField(blank=True, db_index=True, help_text='FK lógica a EU_Area.id', null=True)),
                ('estado', models.CharField(choices=[('idea', 'En Idea'), ('planificado', 'Planificado'), ('en_proceso', 'En Proceso'), ('pausado', 'Pausado'), ('completado', 'Completado'), ('cancelado', 'Cancelado')], db_index=True, default='idea', max_length=20)),
                ('prioridad', models.CharField(choices=[('alta', 'Alta'), ('media', 'Media'), ('baja', 'Baja')], db_index=True, default='media', max_length=10)),
                ('fecha_objetivo', models.DateField(blank=True, null=True)),
                ('fecha_creacion', models.DateTimeField(auto_now_add=True)),
                ('fecha_actualizacion', models.DateTimeField(auto_now=True)),
                ('creado_por', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='gp_proyectos_creados', to=settings.AUTH_USER_MODEL)),
                ('responsable', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='gp_proyectos_responsable', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Proyecto',
                'verbose_name_plural': 'Proyectos',
                'db_table': 'GP_Proyecto',
                'ordering': ['-fecha_actualizacion'],
            },
        ),
        migrations.CreateModel(
            name='GP_Ticket',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('titulo', models.CharField(max_length=255)),
                ('descripcion', models.TextField(blank=True, default='')),
                ('area_id', models.IntegerField(blank=True, db_index=True, help_text='FK lógica a EU_Area.id', null=True)),
                ('sistema_afectado', models.CharField(blank=True, db_index=True, default='', help_text='Ej: picking, vacaciones, caja_chica', max_length=100)),
                ('estado', models.CharField(choices=[('nuevo', 'Nuevo'), ('en_proceso', 'En Proceso'), ('esperando', 'Esperando'), ('resuelto', 'Resuelto'), ('cerrado', 'Cerrado')], db_index=True, default='nuevo', max_length=20)),
                ('prioridad', models.CharField(choices=[('alta', 'Alta'), ('media', 'Media'), ('baja', 'Baja')], db_index=True, default='media', max_length=10)),
                ('impacto', models.CharField(choices=[('alta', 'Alta'), ('media', 'Media'), ('baja', 'Baja')], default='media', max_length=10)),
                ('fecha_creacion', models.DateTimeField(auto_now_add=True)),
                ('fecha_actualizacion', models.DateTimeField(auto_now=True)),
                ('asignado_a', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='gp_tickets_asignados', to=settings.AUTH_USER_MODEL)),
                ('proyecto', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='tickets', to='GestionProyectos.gp_proyecto')),
                ('reportado_por', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='gp_tickets_reportados', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Ticket',
                'verbose_name_plural': 'Tickets',
                'db_table': 'GP_Ticket',
                'ordering': ['-fecha_actualizacion'],
            },
        ),
        migrations.CreateModel(
            name='GP_HistorialEstado',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('tipo', models.CharField(choices=[('proyecto', 'Proyecto'), ('ticket', 'Ticket')], db_index=True, max_length=20)),
                ('ref_id', models.PositiveIntegerField(db_index=True)),
                ('estado_anterior', models.CharField(blank=True, default='', max_length=20)),
                ('estado_nuevo', models.CharField(max_length=20)),
                ('fecha', models.DateTimeField(auto_now_add=True)),
                ('usuario', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='gp_historial', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Historial de estado',
                'verbose_name_plural': 'Historial de estados',
                'db_table': 'GP_HistorialEstado',
                'ordering': ['-fecha'],
            },
        ),
        migrations.CreateModel(
            name='GP_Comentario',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('tipo', models.CharField(choices=[('proyecto', 'Proyecto'), ('ticket', 'Ticket')], db_index=True, max_length=20)),
                ('ref_id', models.PositiveIntegerField(db_index=True)),
                ('cuerpo', models.TextField()),
                ('fecha_creacion', models.DateTimeField(auto_now_add=True)),
                ('autor', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='gp_comentarios', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Comentario',
                'verbose_name_plural': 'Comentarios',
                'db_table': 'GP_Comentario',
                'ordering': ['fecha_creacion'],
            },
        ),
        migrations.AddIndex(
            model_name='gp_historialestado',
            index=models.Index(fields=['tipo', 'ref_id'], name='GP_Historia_tipo_5d2a1c_idx'),
        ),
        migrations.AddIndex(
            model_name='gp_comentario',
            index=models.Index(fields=['tipo', 'ref_id'], name='GP_Comentar_tipo_8f3b2e_idx'),
        ),
    ]
