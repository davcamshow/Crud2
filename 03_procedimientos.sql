-- Abastecer Inventario
CREATE OR REPLACE PROCEDURE sp_abastecer_inventario(
    p_producto_id BIGINT, 
    p_cantidad_recibida INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE abarrotera_producto
    SET stock = stock + p_cantidad_recibida,
        fecha_actualizacion = CURRENT_TIMESTAMP
    WHERE id = p_producto_id;
    
    COMMIT;
END;
$$;

-- Aplicar Descuento Masivo por Categoría
CREATE OR REPLACE PROCEDURE sp_aplicar_descuento_masivo(
    p_categoria_id BIGINT, 
    p_porcentaje_descuento DECIMAL
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE abarrotera_producto
    SET precio = precio - (precio * (p_porcentaje_descuento / 100)),
        fecha_actualizacion = CURRENT_TIMESTAMP
    WHERE categoria_id = p_categoria_id;
    
    COMMIT;
END;
$$;

-- Aumento de Precios por Proveedor
CREATE OR REPLACE PROCEDURE sp_aumento_precio_proveedor(
    p_proveedor_id BIGINT, 
    p_porcentaje_aumento DECIMAL
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE abarrotera_producto
    SET precio = precio + (precio * (p_porcentaje_aumento / 100)),
        fecha_actualizacion = CURRENT_TIMESTAMP
    WHERE proveedor_id = p_proveedor_id;
    
    COMMIT;
END;
$$;

-- Actualizar Total de la Venta
CREATE OR REPLACE PROCEDURE sp_actualizar_total_venta(
    p_venta_id BIGINT
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE abarrotera_venta
    SET total = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM abarrotera_detalleventa
        WHERE venta_id = p_venta_id
    )
    WHERE id = p_venta_id;
    
    COMMIT;
END;
$$;

-- Purgar Historial de Auditoría Antiguo
CREATE OR REPLACE PROCEDURE sp_purgar_auditoria(
    p_meses_antiguedad INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM abarrotera_auditoriainventario
    WHERE fecha_movimiento < (CURRENT_DATE - (p_meses_antiguedad * INTERVAL '1 month'));
    
    COMMIT;
END;
$$;
