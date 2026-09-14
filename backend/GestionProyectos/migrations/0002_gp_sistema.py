# Generated for GP_Sistema catalog

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('GestionProyectos', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='GP_Sistema',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('codigo', models.CharField(help_text='Clave estable: hoja_picking, vacaciones, power_apps…', max_length=80, unique=True)),
                ('nombre', models.CharField(max_length=120)),
                ('descripcion', models.CharField(blank=True, default='', max_length=255)),
                ('activo', models.BooleanField(db_index=True, default=True)),
                ('orden', models.PositiveIntegerField(db_index=True, default=100)),
                ('fecha_creacion', models.DateTimeField(auto_now_add=True)),
                ('fecha_actualizacion', models.DateTimeField(auto_now=True)),
            ],
            options={
                'verbose_name': 'Sistema / aplicación',
                'verbose_name_plural': 'Sistemas / aplicaciones',
                'db_table': 'GP_Sistema',
                'ordering': ['orden', 'nombre'],
            },
        ),
        migrations.AlterField(
            model_name='gp_ticket',
            name='sistema_afectado',
            field=models.CharField(
                blank=True,
                db_index=True,
                default='',
                help_text='Código de GP_Sistema.codigo (o texto libre si es "otro")',
                max_length=100,
            ),
        ),
    ]
