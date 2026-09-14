from django.test import SimpleTestCase

from GestionProyectos.permissions import ALL_GP_GROUPS, GROUP_GESTOR


class GroupsConfigTests(SimpleTestCase):
    def test_groups_defined(self):
        self.assertIn(GROUP_GESTOR, ALL_GP_GROUPS)
        self.assertEqual(len(ALL_GP_GROUPS), 4)
