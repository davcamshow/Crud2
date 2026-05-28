from django.contrib import admin
from .models import Producto

@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    list_display = ['id', 'nombre', 'categoria', 'precio', 'stock', 'fecha_creacion']
    list_filter = ['categoria', 'fecha_creacion']
    search_fields = ['nombre', 'descripcion',]
    readonly_fields = ['fecha_creacion', 'fecha_actualizacion']