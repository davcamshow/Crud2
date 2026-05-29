-- =============================================================================
-- Script: 05_indices.sql
-- Proyecto: Abarrotera Tecnológico
-- Descripción: Índices para optimización de rendimiento (tablespace ts_index)
-- Integrante 3: Seguridad, Monitoreo y Alta Disponibilidad
-- =============================================================================

-- 1. Búsqueda de productos por nombre
CREATE INDEX IF NOT EXISTS idx_producto_nombre
  ON abarrotera_producto(nombre)
  TABLESPACE ts_index;

-- 2. Búsqueda textual full-text en español
CREATE INDEX IF NOT EXISTS idx_producto_nombre_fts
  ON abarrotera_producto USING gin(to_tsvector('spanish', nombre))
  TABLESPACE ts_index;

-- 3. Filtro por categoría
CREATE INDEX IF NOT EXISTS idx_producto_categoria
  ON abarrotera_producto(categoria_id)
  TABLESPACE ts_index;

-- 4. Stock crítico
CREATE INDEX IF NOT EXISTS idx_producto_stock
  ON abarrotera_producto(stock)
  TABLESPACE ts_index;

-- 5. Ordenar/filtrar por precio
CREATE INDEX IF NOT EXISTS idx_producto_precio
  ON abarrotera_producto(precio)
  TABLESPACE ts_index;

-- 6. Ventas por fecha (optimiza v_ventas_del_dia)
CREATE INDEX IF NOT EXISTS idx_venta_fecha
  ON abarrotera_venta(fecha_venta)
  TABLESPACE ts_index;

-- 7. Ventas por cajero
CREATE INDEX IF NOT EXISTS idx_venta_usuario
  ON abarrotera_venta(usuario_cajero_id)
  TABLESPACE ts_index;

-- 8. Detalle de venta por venta
CREATE INDEX IF NOT EXISTS idx_detalle_venta
  ON abarrotera_detalleventa(venta_id)
  TABLESPACE ts_index;

-- 9. Detalle de venta por producto
CREATE INDEX IF NOT EXISTS idx_detalle_producto
  ON abarrotera_detalleventa(producto_id)
  TABLESPACE ts_index;

-- 10. Auditoría por fecha (optimiza sp_purgar_auditoria)
CREATE INDEX IF NOT EXISTS idx_auditoria_fecha
  ON abarrotera_auditoriainventario(fecha_movimiento)
  TABLESPACE ts_index;

-- 11. Auditoría por producto
CREATE INDEX IF NOT EXISTS idx_auditoria_producto
  ON abarrotera_auditoriainventario(producto_id)
  TABLESPACE ts_index;

-- 12. Proveedor por nombre
CREATE INDEX IF NOT EXISTS idx_proveedor_nombre
  ON abarrotera_proveedor(nombre_empresa)
  TABLESPACE ts_index;

-- =============================================================================
-- Verificar índices creados
-- =============================================================================

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename LIKE 'abarrotera_%'
ORDER BY tablename, indexname;
