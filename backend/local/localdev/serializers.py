from rest_framework import serializers

from .models import EU_Area


class EU_AreaSerializer(serializers.ModelSerializer):
    class Meta:
        model = EU_Area
        fields = ['id', 'nombre']
