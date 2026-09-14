from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import EU_Area, ExtendedUser


@admin.register(ExtendedUser)
class ExtendedUserAdmin(UserAdmin):
    fieldsets = UserAdmin.fieldsets + (
        ('Surgicorp', {'fields': ('area', 'area_id', 'puesto')}),
    )
    list_display = ('username', 'email', 'first_name', 'last_name', 'area', 'is_staff')


@admin.register(EU_Area)
class EU_AreaAdmin(admin.ModelAdmin):
    list_display = ('id', 'nombre')
    search_fields = ('nombre',)
