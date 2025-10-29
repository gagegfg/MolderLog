CREATE OR REPLACE FUNCTION public.crear_lista_empaque_completa(
    p_legajo real,
    p_cliente_razonsocial text,
    p_fecha_despacho date,
    p_razon_social_transporte text,
    p_retiran_desde_planta boolean,
    p_detalles jsonb
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_id_cliente int;
    v_id_lista_nueva bigint;
    v_detalle record;
BEGIN
    -- 1. Buscar el ID del cliente por su razón social
    SELECT idcli INTO v_id_cliente FROM public.clientes WHERE razonsocial = p_cliente_razonsocial;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cliente no encontrado: %', p_cliente_razonsocial;
    END IF;

    -- 2. Crear la cabecera de la lista de empaque
    INSERT INTO public.listaempaque (idcliente, legajo)
    VALUES (v_id_cliente, p_legajo)
    RETURNING idlista INTO v_id_lista_nueva;

    -- 3. Crear el registro de despacho asociado
    INSERT INTO public.despachoListaEmpaque (idListaEmpaque, fechaDespacho, retiranDesdePlanta, razonSocialTransporte)
    VALUES (v_id_lista_nueva, p_fecha_despacho, p_retiran_desde_planta, p_razon_social_transporte);

    -- 4. Insertar los detalles desde el JSON
    IF p_detalles IS NOT NULL AND jsonb_array_length(p_detalles) > 0 THEN
        FOR v_detalle IN SELECT * FROM jsonb_to_recordset(p_detalles) AS x(nropallet bigint, lotesproduccion text, cantidad double precision)
        LOOP
            INSERT INTO public.detallelistaempaque (idlista, nropallet, lotesproduccion, cantidad)
            VALUES (v_id_lista_nueva, v_detalle.nropallet, v_detalle.lotesproduccion, v_detalle.cantidad);
        END LOOP;
    END IF;

    -- 5. Retornar el ID de la lista creada
    RETURN v_id_lista_nueva;
END;
$$;