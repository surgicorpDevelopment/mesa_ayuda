"""
Registrar en ServidorCaminitos/urls.py:

    from GestionProyectos.urls import register_gp_routes
    register_gp_routes(router)
"""

from rest_framework.routers import DefaultRouter

from .views import (
    GP_ComentarioViewSet,
    GP_HistorialEstadoViewSet,
    GP_ProductividadViewSet,
    GP_ProyectoViewSet,
    GP_SistemaViewSet,
    GP_TareaViewSet,
    GP_TicketViewSet,
    GP_UsuarioViewSet,
)


def register_gp_routes(router: DefaultRouter) -> None:
    router.register(r'GP_Proyecto', GP_ProyectoViewSet, basename='gp-proyecto')
    router.register(r'GP_Ticket', GP_TicketViewSet, basename='gp-ticket')
    router.register(r'GP_Tarea', GP_TareaViewSet, basename='gp-tarea')
    router.register(r'GP_Comentario', GP_ComentarioViewSet, basename='gp-comentario')
    router.register(r'GP_HistorialEstado', GP_HistorialEstadoViewSet, basename='gp-historial')
    router.register(r'GP_Sistema', GP_SistemaViewSet, basename='gp-sistema')
    router.register(r'GP_Usuario', GP_UsuarioViewSet, basename='gp-usuario')
    router.register(r'GP_Productividad', GP_ProductividadViewSet, basename='gp-productividad')
