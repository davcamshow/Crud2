-- Auditoría Automática de Stock
CREATE OR REPLACE FUNCTION fn_auditoria_stock() RETURNS TRIGGER AS $$
BEGIN
    -- Solo registra si el stock realmente cambió
    IF NEW.stock <> OLD.stock THEN
        INSERT INTO abarrotera_auditoriainventario 
        (producto_id, accion, stock_anterior, stock_nuevo, fecha_movimiento)
        VALUES (
            OLD.id, 
            CASE WHEN NEW.stock > OLD.stock THEN 'ENTRADA' ELSE 'SALIDA' END, 
            OLD.stock, 
            NEW.stock, 
            CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auditoria_stock
AFTER UPDATE OF stock ON abarrotera_producto
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_stock();

-- Evitar Stock Negativo (Validación estricta)
CREATE OR REPLACE FUNCTION fn_evitar_stock_negativo() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.stock < 0 THEN
        RAISE EXCEPTION 'Operación denegada: El producto % no puede tener stock negativo.', NEW.nombre;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_evitar_stock_negativo
BEFORE INSERT OR UPDATE ON abarrotera_producto
FOR EACH ROW EXECUTE FUNCTION fn_evitar_stock_negativo();

-- Descontar Stock Automáticamente al Vender
CREATE OR REPLACE FUNCTION fn_descontar_stock_venta() RETURNS TRIGGER AS $$
BEGIN
    UPDATE abarrotera_producto
    SET stock = stock - NEW.cantidad
    WHERE id = NEW.producto_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_descontar_stock_venta
AFTER INSERT ON abarrotera_detalleventa
FOR EACH ROW EXECUTE FUNCTION fn_descontar_stock_venta();

-- Validar Precios Reales
CREATE OR REPLACE FUNCTION fn_validar_precio() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.precio <= 0 THEN
        RAISE EXCEPTION 'Operación denegada: El precio de % debe ser mayor a cero. (Intentaste poner: $%)', NEW.nombre, NEW.precio;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_precio
BEFORE INSERT OR UPDATE ON abarrotera_producto
FOR EACH ROW EXECUTE FUNCTION fn_validar_precio();

-- Auditoría de Nuevos Productos
CREATE OR REPLACE FUNCTION fn_auditoria_nuevo_producto() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO abarrotera_auditoriainventario 
    (producto_id, accion, stock_anterior, stock_nuevo, fecha_movimiento)
    VALUES (NEW.id, 'ALTA INICIAL', 0, NEW.stock, CURRENT_TIMESTAMP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auditoria_nuevo_producto
AFTER INSERT ON abarrotera_producto
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_nuevo_producto();
