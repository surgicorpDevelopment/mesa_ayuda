import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('GestionProyectos', '0005_tipoentidad_tarea'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='GP_TicketAdjunto',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('nombre', models.CharField(max_length=255)),
                ('archivo', models.FileField(upload_to='gp_tickets/%Y/%m/')),
                ('mime_type', models.CharField(blank=True, default='', max_length=100)),
                ('size_bytes', models.PositiveIntegerField(default=0)),
                ('fecha_creacion', models.DateTimeField(auto_now_add=True)),
                (
                    'ticket',
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name='adjuntos',
                        to='GestionProyectos.gp_ticket',
                    ),
                ),
                (
                    'subido_por',
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.SET_NULL,
                        related_name='gp_adjuntos',
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={
                'verbose_name': 'Adjunto de ticket',
                'verbose_name_plural': 'Adjuntos de ticket',
                'db_table': 'GP_TicketAdjunto',
                'ordering': ['fecha_creacion'],
            },
        ),
    ]
