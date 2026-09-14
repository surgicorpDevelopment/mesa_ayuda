from django.http import JsonResponse
from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from .models import EU_Area
from .serializers import EU_AreaSerializer


def health_check(request):
    return JsonResponse({'status': 'ok', 'service': 'gp-local'})


class EU_AreaViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = EU_Area.objects.all()
    serializer_class = EU_AreaSerializer
    permission_classes = [IsAuthenticated]
    pagination_class = None
