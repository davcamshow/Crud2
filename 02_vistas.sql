-- Vista de Productos en Stock Crítico
CREATE OR REPLACE VIEW v_productos_criticos AS
SELECT 
    id, 
    nombre, 
    stock, 
    precio
FROM abarrotera_producto
WHERE stock <= 15
ORDER BY stock ASC;

-- Vista del Catálogo Completo
CREATE OR REPLACE VIEW v_catalogo_completo AS
SELECT
    p.id,
    p.nombre AS producto,
    p.descripcion,
    p.precio,
    p.stock,
    c.nombre AS categoria,
    pr.nombre_empresa AS proveedor
FROM abarrotera_producto p
LEFT JOIN abarrotera_categoria c ON p.categoria_id = c.id
LEFT JOIN abarrotera_proveedor pr ON p.proveedor_id = pr.id;

-- Vista de Ventas del Día
CREATE OR REPLACE VIEW v_ventas_del_dia AS
SELECT
    v.id AS folio_venta,
    v.fecha_venta,
    v.total,
    u.username AS cajero
FROM abarrotera_venta v
JOIN auth_user u ON v.usuario_cajero_id = u.id
WHERE DATE(v.fecha_venta) = CURRENT_DATE;

-- Vista del Top 10 Productos Más Vendidos
CREATE OR REPLACE VIEW v_top_vendidos AS
SELECT
    p.nombre AS producto,
    SUM(dv.cantidad) AS total_unidades_vendidas,
    SUM(dv.subtotal) AS ingresos_generados
FROM abarrotera_detalleventa dv
JOIN abarrotera_producto p ON dv.producto_id = p.id
GROUP BY p.id, p.nombre
ORDER BY total_unidades_vendidas DESC
LIMIT 10;

-- Vista del Historial de Auditoría Legible
CREATE OR REPLACE VIEW v_historial_auditoria AS
SELECT
    a.id AS folio_movimiento,
    p.nombre AS producto,
    a.accion,
    a.stock_anterior,
    a.stock_nuevo,
    a.fecha_movimiento,
FROM abarrotera_auditoriainventario a
JOIN abarrotera_producto p ON a.producto_id = p.id
ORDER BY a.fecha_movimiento DESC;
