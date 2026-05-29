-- =============================================================================
-- Script: 05_indices.sql
-- Proyecto: Abarrotera Tecnológico
-- Descripción: Índices recomendados para optimización de rendimiento
-- Integrante 3: Seguridad, Monitoreo y Alta Disponibilidad
-- =============================================================================

-- 1. Índice para búsqueda textual de productos por nombre (full-text search)
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_producto_nombre_fts
ON abarrotera_producto USING gin(to_tsvector('spanish', nombre));

-- 2. Índice para ordenar y filtrar productos por precio
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_producto_precio
ON abarrotera_producto(precio);

-- 3. Índice para consultas de ventas por fecha (optimiza v_ventas_del_dia)
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_venta_fecha
ON abarrotera_venta(fecha_venta);

-- 4. Índice para búsqueda de detalles por venta
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_detalleventa_venta
ON abarrotera_detalleventa(venta_id);

-- 5. Índice para búsqueda de detalles por producto
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_detalleventa_producto
ON abarrotera_detalleventa(producto_id);

-- 6. Índice para purga de auditoría por fecha (optimiza sp_purgar_auditoria)
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_auditoria_fecha
ON abarrotera_auditoriainventario(fecha_movimiento);

-- 7. Índice para búsqueda en auditoría por producto
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_auditoria_producto
ON abarrotera_auditoriainventario(producto_id);

-- 8. Índice para búsqueda de productos por categoría
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_producto_categoria
ON abarrotera_producto(categoria_id);

-- 9. Índice para búsqueda de productos por proveedor
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_producto_proveedor
ON abarrotera_producto(proveedor_id);

-- =============================================================================
-- Verificar índices creados
-- =============================================================================

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename LIKE 'abarrotera_%'
ORDER BY tablename, indexname;
