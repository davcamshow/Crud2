-- Indices del sistema de abarrotera
-- Todos en el tablespace ts_index (disco separado)

-- 1. Busqueda de productos por nombre
CREATE INDEX idx_producto_nombre 
  ON abarrotera_producto(nombre) 
  TABLESPACE ts_index;

-- 2. Filtro por categoria
CREATE INDEX idx_producto_categoria 
  ON abarrotera_producto(categoria_id) 
  TABLESPACE ts_index;

-- 3. Stock critico
CREATE INDEX idx_producto_stock 
  ON abarrotera_producto(stock) 
  TABLESPACE ts_index;

-- 4. Ventas por fecha
CREATE INDEX idx_venta_fecha 
  ON abarrotera_venta(fecha_venta) 
  TABLESPACE ts_index;

-- 5. Ventas por cajero
CREATE INDEX idx_venta_usuario 
  ON abarrotera_venta(usuario_cajero_id) 
  TABLESPACE ts_index;

-- 6. Detalle de venta por venta
CREATE INDEX idx_detalle_venta 
  ON abarrotera_detalleventa(venta_id) 
  TABLESPACE ts_index;

-- 7. Detalle de venta por producto
CREATE INDEX idx_detalle_producto 
  ON abarrotera_detalleventa(producto_id) 
  TABLESPACE ts_index;

-- 8. Auditoria por fecha
CREATE INDEX idx_auditoria_fecha 
  ON abarrotera_auditoriainventario(fecha_movimiento) 
  TABLESPACE ts_index;

-- 9. Auditoria por producto
CREATE INDEX idx_auditoria_producto 
  ON abarrotera_auditoriainventario(producto_id) 
  TABLESPACE ts_index;

-- 10. Proveedor por nombre
CREATE INDEX idx_proveedor_nombre 
  ON abarrotera_proveedor(nombre_empresa) 
  TABLESPACE ts_index;