import django.db.models.deletion
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('GestionProyectos', '0009_ticket_estados_aprobacion'),
    ]

    operations = [
        migrations.AddField(
            model_name='gp_ticket',
            name='aprobado_por',
            field=models.ForeignKey(
                blank=True,
                help_text='Quien pulsó Aprobar.',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='gp_tickets_aprobados',
                to=settings.AUTH_USER_MODEL,
            ),
        ),
        migrations.AddField(
            model_name='gp_ticket',
            name='autorizado_por',
            field=models.ForeignKey(
                blank=True,
                help_text='Quien autorizó: el mismo aprobador o un líder/gestor.',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='gp_tickets_autorizados',
                to=settings.AUTH_USER_MODEL,
            ),
        ),
    ]
