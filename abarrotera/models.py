from django.utils.ipv6 import MAX_IPV6_ADDRESS_LENGTH
from django.db import models
from django.contrib.auth.models import User

# Catalogo
class Categoria(models.Model):
    nombre = models.CharField(max_length=100, unique=True)
    descripcion = models.TextField(null=True, blank=True)

    def __str__(self):
        return self.nombre

class Proveedor(models.Model):
    nombre_empresa = models.CharField(max_length=200)
    rfc = models.CharField(max_length=13, unique=True, blank=True)
    telefono = models.CharField(max_length=20, null=True, blank=True)
    email = models.EmailField(max_length=254, null=True, blank=True)

    def __str__(self):
        return self.nombre_empresa

class Producto(models.Model):
    nombre = models.CharField(max_length=200)
    descripcion = models.TextField()
    precio = models.DecimalField(max_digits=10, decimal_places=2)
    stock = models.IntegerField()
    
    # Nuevas llaves foráneas (tienen null=True para no romper tus datos existentes)
    categoria = models.ForeignKey(Categoria, on_delete=models.PROTECT, null=True)
    proveedor = models.ForeignKey(Proveedor, on_delete=models.PROTECT, null=True)
    
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    fecha_actualizacion = models.DateTimeField(auto_now=True)
    usuario_creador = models.ForeignKey(User, on_delete=models.PROTECT)

    class Meta:
        verbose_name = 'Producto'
        verbose_name_plural = 'Productos'
        ordering = ['-fecha_creacion']

    def __str__(self):
        return self.nombre

# Tablas Transaccionales
class Venta(models.Model):
    fecha_venta = models.DateTimeField(auto_now_add=True)
    total = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    usuario_cajero = models.ForeignKey(User, on_delete=models.PROTECT)

    def __str__(self):
        return f"Venta #{self.id} - {self.fecha_venta.strftime('%d/%m/%Y')}"

class DetalleVenta(models.Model):
    venta = models.ForeignKey(Venta, on_delete=models.CASCADE, related_name='detalles')
    producto = models.ForeignKey(Producto, on_delete=models.PROTECT)
    cantidad = models.IntegerField()
    precio_unitario = models.DecimalField(max_digits=10, decimal_places=2)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return f"{self.cantidad} x {self.producto.nombre}"

# Seguridad y Auditoría (Requisito clave del proyecto)
class AuditoriaInventario(models.Model):
    # Nota: Esta tabla será alimentada por Triggers de PostgreSQL, no por vistas de Django.
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    accion = models.CharField(max_length=50) # 'ENTRADA', 'SALIDA', 'AJUSTE'
    stock_anterior = models.IntegerField()
    stock_nuevo = models.IntegerField()
    fecha_movimiento = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Auditoria de inventario'
        verbose_name_plural = 'Auditorias de inventario'
        ordering = ['-fecha_movimiento']

    def __str__(self):
        return f"{self.accion} - {self.producto.nombre}"
