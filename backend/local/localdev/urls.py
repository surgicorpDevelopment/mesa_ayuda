from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from GestionProyectos.urls import register_gp_routes

from .views import EU_AreaViewSet, health_check

router = DefaultRouter()
register_gp_routes(router)
router.register(r'EU_Area', EU_AreaViewSet)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('health_check/', health_check),
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('', include(router.urls)),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
