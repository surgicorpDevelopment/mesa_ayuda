from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('GestionProyectos', '0010_ticket_autorizacion'),
    ]

    operations = [
        migrations.AlterField(
            model_name='gp_ticketadjunto',
            name='archivo',
            field=models.FileField(
                upload_to='NewAPI/static/GestionProyectos/gp_tickets/%Y/%m/',
            ),
        ),
        migrations.AlterField(
            model_name='gp_proyectoadjunto',
            name='archivo',
            field=models.FileField(
                upload_to='NewAPI/static/GestionProyectos/gp_proyectos/%Y/%m/',
            ),
        ),
    ]
