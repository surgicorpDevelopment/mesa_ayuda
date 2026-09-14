from django.core.management.base import BaseCommand
from django.contrib.auth.models import Group

from GestionProyectos.permissions import ALL_GP_GROUPS


class Command(BaseCommand):
    help = 'Crea los grupos Django del Gestor de Proyectos/Tickets si no existen.'

    def handle(self, *args, **options):
        created = []
        for name in ALL_GP_GROUPS:
            group, was_created = Group.objects.get_or_create(name=name)
            if was_created:
                created.append(name)
                self.stdout.write(self.style.SUCCESS(f'Creado grupo: {name}'))
            else:
                self.stdout.write(f'Ya existe: {name}')
        if not created:
            self.stdout.write(self.style.WARNING('Ningún grupo nuevo.'))
        else:
            self.stdout.write(self.style.SUCCESS(f'Grupos creados: {", ".join(created)}'))
        self.stdout.write(
            'Asigna usuarios con: user.groups.add(Group.objects.get(name="gp_gestor_proyectos"))'
        )
