from django.db import models
from django.contrib.auth.models import User

class Producto(models.Model):
    CATEGORIAS = [
        ('bebidas', 'Bebidas'),
        ('panaderia', 'Panadería'),
        ('lacteos', 'Lácteos'),
        ('abarrotes', 'Abarrotes'),
        ('limpieza', 'Limpieza'),
        ('otros', 'Otros'),
    ]

    nombre = models.CharField(max_length=200, verbose_name='Nombre del producto')
    descripcion = models.TextField(verbose_name='Descripción')
    precio = models.DecimalField(max_digits=10, decimal_places=2, verbose_name='Precio')
    stock = models.IntegerField(verbose_name='Stock disponible')
    categoria = models.CharField(max_length=50, choices=CATEGORIAS, verbose_name='Categoría')
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)
    usuario_creador = models.ForeignKey(User, on_delete=models.CASCADE, related_name='productos_creados')

    class Meta:
        verbose_name = 'Producto'
        verbose_name_plural = 'Productos'
        ordering = ['-fecha_creacion']

    def __str__(self):
        return self.nombre