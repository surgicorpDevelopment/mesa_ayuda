from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group
from django.core.management.base import BaseCommand

from GestionProyectos.permissions import (
    GROUP_DESARROLLADOR,
    GROUP_GESTOR,
    GROUP_LIDER_AREA,
    GROUP_USUARIO,
)
from localdev.models import EU_Area

User = get_user_model()

PASSWORD = 'local123'

AREAS = (
    'Tecnología de la Información',
    'Comercial',
    'Operaciones',
)

USERS = (
    {
        'username': 'usuario',
        'first_name': 'Ana',
        'last_name': 'Usuario',
        'email': 'usuario@local.test',
        'puesto': 'Analista',
        'groups': (GROUP_USUARIO,),
        'is_staff': False,
        'is_superuser': False,
    },
    {
        'username': 'dev',
        'first_name': 'Diego',
        'last_name': 'Desarrollador',
        'email': 'dev@local.test',
        'puesto': 'Desarrollador',
        'groups': (GROUP_DESARROLLADOR,),
        'is_staff': False,
        'is_superuser': False,
    },
    {
        'username': 'lider',
        'first_name': 'Laura',
        'last_name': 'Líder',
        'email': 'lider@local.test',
        'puesto': 'Líder de área',
        'groups': (GROUP_LIDER_AREA,),
        'is_staff': False,
        'is_superuser': False,
    },
    {
        'username': 'gestor',
        'first_name': 'Gabriel',
        'last_name': 'Gestor',
        'email': 'gestor@local.test',
        'puesto': 'Gestor de proyectos',
        'groups': (GROUP_GESTOR,),
        'is_staff': False,
        'is_superuser': False,
    },
    {
        'username': 'admin',
        'first_name': 'Admin',
        'last_name': 'Local',
        'email': 'admin@local.test',
        'puesto': 'Administrador',
        'groups': (),
        'is_staff': True,
        'is_superuser': True,
    },
)


class Command(BaseCommand):
    help = 'Crea áreas y usuarios de prueba del harness local (password: local123).'

    def handle(self, *args, **options):
        areas = []
        for nombre in AREAS:
            area, created = EU_Area.objects.get_or_create(nombre=nombre)
            areas.append(area)
            if created:
                self.stdout.write(self.style.SUCCESS(f'Área creada: {nombre} (id={area.id})'))
            else:
                self.stdout.write(f'Área ya existe: {nombre} (id={area.id})')

        ti = areas[0]
        for spec in USERS:
            user, created = User.objects.get_or_create(
                username=spec['username'],
                defaults={
                    'first_name': spec['first_name'],
                    'last_name': spec['last_name'],
                    'email': spec['email'],
                    'puesto': spec['puesto'],
                    'area': ti.nombre,
                    'area_id': ti.id,
                    'is_staff': spec['is_staff'],
                    'is_superuser': spec['is_superuser'],
                },
            )
            user.set_password(PASSWORD)
            user.first_name = spec['first_name']
            user.last_name = spec['last_name']
            user.email = spec['email']
            user.puesto = spec['puesto']
            user.area = ti.nombre
            user.area_id = ti.id
            user.is_staff = spec['is_staff']
            user.is_superuser = spec['is_superuser']
            user.save()
            user.groups.clear()
            for group_name in spec['groups']:
                group = Group.objects.get(name=group_name)
                user.groups.add(group)
            verb = 'Creado' if created else 'Actualizado'
            roles = ', '.join(spec['groups']) or 'superuser'
            self.stdout.write(self.style.SUCCESS(f'{verb} {user.username} ({roles})'))

        self.stdout.write(self.style.SUCCESS(f'Password de todos: {PASSWORD}'))
