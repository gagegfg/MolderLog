-- 1. Función para obtener el número de pallet más alto.
-- Esta función ahora consulta la tabla `nroPallet` como fuente principal,
-- y también `detallelotes` para ser más robusto, devolviendo el mayor valor encontrado.

CREATE OR REPLACE FUNCTION get_max_pallet_number()
RETURNS bigint AS $$
BEGIN
  RETURN (
    SELECT COALESCE(GREATEST(
      (SELECT MAX(nrPallet) FROM public.nroPallet),
      (SELECT MAX(nropallet) FROM public.detallelotes)
    ), 0)
  );
END;
$$ LANGUAGE plpgsql;


-- 2. Función para la inserción atómica de un nuevo pallet.
-- Se ha modificado para que también inserte el nuevo número de pallet en la tabla `nroPallet`.

CREATE OR REPLACE FUNCTION crear_nuevo_pallet(
    p_sku text,
    p_descripcion text,
    p_numero_pallet bigint,
    p_lotes_produccion text,
    p_fecha_produccion date,
    p_cantidad double precision,
    p_unidad_medida text,
    p_observacion text
)
RETURNS void AS $$
DECLARE
    v_idsku int;
BEGIN
    -- Primero, encontramos el idsku correspondiente al SKU de texto.
    SELECT idsku INTO v_idsku FROM public.articulos WHERE sku = p_sku;

    IF v_idsku IS NULL THEN
        RAISE EXCEPTION 'No se encontró el artículo con SKU: %', p_sku;
    END IF;

    -- Insertamos en la tabla principal `detallelotes`.
    INSERT INTO public.detallelotes(idsku, nropallet, loteproducto, fechaproduccion, cantidad, um)
    VALUES (v_idsku, p_numero_pallet, p_lotes_produccion, p_fecha_produccion, p_cantidad, p_unidad_medida);

    -- También registramos el número en la tabla `nroPallet` para mantenerla sincronizada.
    INSERT INTO public.nroPallet(nrPallet) VALUES (p_numero_pallet) ON CONFLICT (nrPallet) DO NOTHING;

    -- Si hay una observación, la insertamos en la tabla `notasskulote`.
    IF p_observacion IS NOT NULL AND LENGTH(p_observacion) > 0 THEN
        INSERT INTO public.notasskulote(nropallet, nota)
        VALUES (p_numero_pallet, p_observacion);
    END IF;
END;
$$ LANGUAGE plpgsql;


-- 3. Función para forzar manualmente un número de pallet.
-- Modificada para registrar también el número forzado en la tabla `nroPallet`.
-- DEBE CREAR UN ARTÍCULO CON SKU = '000-MANUAL' en su tabla de `articulos`.

CREATE OR REPLACE FUNCTION force_set_pallet_number(new_number bigint)
RETURNS void AS $$
DECLARE
    v_idsku int;
BEGIN
    -- Se busca el idsku del artículo reservado para ajustes manuales.
    SELECT idsku INTO v_idsku FROM public.articulos WHERE sku = '000-MANUAL';

    IF v_idsku IS NULL THEN
        RAISE EXCEPTION 'Artículo de ajuste manual no encontrado. Por favor, cree un artículo con SKU = ''000-MANUAL''.';
    END IF;

    -- Se verifica si el número de pallet ya existe para evitar errores de clave duplicada.
    IF EXISTS (SELECT 1 FROM public.detallelotes WHERE nropallet = new_number) THEN
        RAISE EXCEPTION 'El número de pallet % ya existe.', new_number;
    END IF;

    -- Se inserta un registro simple para "reservar" el número de pallet.
    INSERT INTO public.detallelotes(idsku, nropallet, loteproducto, fechaproduccion, cantidad, um)
    VALUES (v_idsku, new_number, 'AJUSTE MANUAL', NOW()::date, 0, 'N/A');

    -- También registramos el número forzado en la tabla `nroPallet`.
    INSERT INTO public.nroPallet(nrPallet) VALUES (new_number) ON CONFLICT (nrPallet) DO NOTHING;
END;
$$ LANGUAGE plpgsql;