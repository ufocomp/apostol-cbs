--------------------------------------------------------------------------------
-- REST ORDER ------------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Запрос данных в формате REST JSON API (Ордер).
 * @param {text} pPath - Путь
 * @param {jsonb} pPayload - JSON
 * @return {SETOF json} - Записи в JSON
 */
CREATE OR REPLACE FUNCTION rest.order (
  pPath       text,
  pPayload    jsonb default null
) RETURNS     SETOF json
AS $$
DECLARE
  r           record;
  e           record;

  arKeys      text[];
BEGIN
  IF pPath IS NULL THEN
    PERFORM RouteIsEmpty();
  END IF;

  IF current_session() IS NULL THEN
	PERFORM LoginFailed();
  END IF;

  CASE pPath
  WHEN '/order/type' THEN

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(fields jsonb)
    LOOP
      FOR e IN EXECUTE format('SELECT %s FROM api.type($1)', JsonbToFields(r.fields, GetColumns('type', 'api'))) USING GetEntity('order')
      LOOP
        RETURN NEXT row_to_json(e);
      END LOOP;
    END LOOP;

  WHEN '/order/method' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id uuid)
      LOOP
        FOR e IN SELECT r.id, api.get_methods(GetObjectClass(r.id), GetObjectState(r.id)) as method FROM api.get_order(r.id) ORDER BY id
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id uuid)
      LOOP
        FOR e IN SELECT r.id, api.get_methods(GetObjectClass(r.id), GetObjectState(r.id)) as method FROM api.get_order(r.id) ORDER BY id
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/order/count' THEN

    IF pPayload IS NOT NULL THEN
      arKeys := array_cat(arKeys, ARRAY['search', 'filter', 'reclimit', 'recoffset', 'orderby']);
      PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);
    ELSE
      pPayload := '{}';
    END IF;

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(search jsonb, filter jsonb, reclimit integer, recoffset integer, orderby jsonb)
      LOOP
        FOR e IN SELECT count(*) FROM api.list_order(r.search, r.filter, r.reclimit, r.recoffset, r.orderby)
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(search jsonb, filter jsonb, reclimit integer, recoffset integer, orderby jsonb)
      LOOP
        FOR e IN SELECT count(*) FROM api.list_order(r.search, r.filter, r.reclimit, r.recoffset, r.orderby)
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/order/set' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, GetRoutines('set_order', 'api', false));
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN EXECUTE format('SELECT row_to_json(api.set_order(%s)) FROM jsonb_to_recordset($1) AS x(%s)', array_to_string(GetRoutines('set_order', 'api', false, 'x'), ', '), array_to_string(GetRoutines('set_order', 'api', true), ', ')) USING pPayload
      LOOP
        RETURN NEXT r;
      END LOOP;

    ELSE

      FOR r IN EXECUTE format('SELECT row_to_json(api.set_order(%s)) FROM jsonb_to_record($1) AS x(%s)', array_to_string(GetRoutines('set_order', 'api', false, 'x'), ', '), array_to_string(GetRoutines('set_order', 'api', true), ', ')) USING pPayload
      LOOP
        RETURN NEXT r;
      END LOOP;

    END IF;

  WHEN '/order/get' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['id', 'fields']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(id uuid, fields jsonb)
      LOOP
        FOR e IN EXECUTE format('SELECT %s FROM api.get_order($1)', JsonbToFields(r.fields, GetColumns('order', 'api'))) USING r.id
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(id uuid, fields jsonb)
      LOOP
        FOR e IN EXECUTE format('SELECT %s FROM api.get_order($1)', JsonbToFields(r.fields, GetColumns('order', 'api'))) USING r.id
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/order/list' THEN

    IF pPayload IS NOT NULL THEN
      arKeys := array_cat(arKeys, ARRAY['fields', 'search', 'filter', 'reclimit', 'recoffset', 'orderby']);
      PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);
    ELSE
      pPayload := '{}';
    END IF;

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(fields jsonb, search jsonb, filter jsonb, reclimit integer, recoffset integer, orderby jsonb)
    LOOP
      FOR e IN EXECUTE format('SELECT %s FROM api.list_order($1, $2, $3, $4, $5)', JsonbToFields(r.fields, GetColumns('order', 'api'))) USING r.search, r.filter, r.reclimit, r.recoffset, r.orderby
      LOOP
        RETURN NEXT row_to_json(e);
      END LOOP;
    END LOOP;

  WHEN '/order/item' THEN

	IF pPayload IS NULL THEN
	  PERFORM JsonIsEmpty();
	END IF;

	arKeys := array_cat(arKeys, ARRAY['document', 'items']);
	PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

	IF jsonb_typeof(pPayload) = 'array' THEN

	  FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(document uuid, items json)
	  LOOP
		IF r.items IS NOT NULL THEN
		  FOR e IN SELECT * FROM api.set_order_item_json(r.document, r.items)
		  LOOP
			RETURN NEXT row_to_json(e);
		  END LOOP;
		ELSE
		  RETURN NEXT api.get_order_item_json(r.document);
		END IF;
	  END LOOP;

	ELSE

	  FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(document uuid, items json)
	  LOOP
		IF r.items IS NOT NULL THEN
		  FOR e IN SELECT * FROM api.set_order_item_json(r.document, r.items)
		  LOOP
			RETURN NEXT row_to_json(e);
		  END LOOP;
		ELSE
		  RETURN NEXT api.get_order_item_json(r.document);
		END IF;
	  END LOOP;

	END IF;

  WHEN '/order/item/count' THEN

    IF pPayload IS NOT NULL THEN
      arKeys := array_cat(arKeys, ARRAY['search', 'filter', 'reclimit', 'recoffset', 'orderby']);
      PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);
    ELSE
      pPayload := '{}';
    END IF;

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(search jsonb, filter jsonb, reclimit integer, recoffset integer, orderby jsonb)
      LOOP
        FOR e IN SELECT count(*) FROM api.list_order_item(r.search, r.filter, r.reclimit, r.recoffset, r.orderby)
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(search jsonb, filter jsonb, reclimit integer, recoffset integer, orderby jsonb)
      LOOP
        FOR e IN SELECT count(*) FROM api.list_order_item(r.search, r.filter, r.reclimit, r.recoffset, r.orderby)
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/order/item/set' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, GetRoutines('set_order_item', 'api', false));
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN EXECUTE format('SELECT row_to_json(api.set_order_item(%s)) FROM jsonb_to_recordset($1) AS x(%s)', array_to_string(GetRoutines('set_order_item', 'api', false, 'x'), ', '), array_to_string(GetRoutines('set_order_item', 'api', true), ', ')) USING pPayload
      LOOP
        RETURN NEXT r;
      END LOOP;

    ELSE

      FOR r IN EXECUTE format('SELECT row_to_json(api.set_order_item(%s)) FROM jsonb_to_record($1) AS x(%s)', array_to_string(GetRoutines('set_order_item', 'api', false, 'x'), ', '), array_to_string(GetRoutines('set_order_item', 'api', true), ', ')) USING pPayload
      LOOP
        RETURN NEXT r;
      END LOOP;

    END IF;

  WHEN '/order/item/get' THEN

    IF pPayload IS NULL THEN
      PERFORM JsonIsEmpty();
    END IF;

    arKeys := array_cat(arKeys, ARRAY['document', 'itemid', 'fields']);
    PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

    IF jsonb_typeof(pPayload) = 'array' THEN

      FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(document uuid, itemid integer, fields jsonb)
      LOOP
        FOR e IN EXECUTE format('SELECT %s FROM api.get_order_item($1, $2)', JsonbToFields(r.fields, GetColumns('order_item', 'api'))) USING r.document, r.itemid
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    ELSE

      FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(document uuid, itemid integer, fields jsonb)
      LOOP
        FOR e IN EXECUTE format('SELECT %s FROM api.get_order_item($1, $2)', JsonbToFields(r.fields, GetColumns('order_item', 'api'))) USING r.document, r.itemid
        LOOP
          RETURN NEXT row_to_json(e);
        END LOOP;
      END LOOP;

    END IF;

  WHEN '/order/item/delete' THEN

	IF pPayload IS NULL THEN
	  PERFORM JsonIsEmpty();
	END IF;

    arKeys := array_cat(arKeys, ARRAY['document', 'itemid']);
	PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

	IF jsonb_typeof(pPayload) = 'array' THEN

	  FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(document uuid, itemid integer)
	  LOOP
		FOR e IN SELECT r.document, r.itemid, api.delete_order_item(r.document, r.itemid) AS success
		LOOP
		  RETURN NEXT row_to_json(e);
		END LOOP;
	  END LOOP;

	ELSE

	  FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(document uuid, itemid integer)
	  LOOP
		FOR e IN SELECT r.document, r.itemid, api.delete_order_item(r.document, r.itemid) AS success
		LOOP
		  RETURN NEXT row_to_json(e);
		END LOOP;
	  END LOOP;

	END IF;

  WHEN '/order/item/clear' THEN

	IF pPayload IS NULL THEN
	  PERFORM JsonIsEmpty();
	END IF;

	arKeys := array_cat(arKeys, ARRAY['document']);
	PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);

	IF jsonb_typeof(pPayload) = 'array' THEN

	  FOR r IN SELECT * FROM jsonb_to_recordset(pPayload) AS x(document uuid)
	  LOOP
		FOR e IN SELECT r.document, api.clear_order_item(r.document) AS success
		LOOP
		  RETURN NEXT row_to_json(e);
		END LOOP;
	  END LOOP;

	ELSE

	  FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(document uuid)
	  LOOP
		FOR e IN SELECT r.document, api.clear_order_item(r.document) AS success
		LOOP
		  RETURN NEXT row_to_json(e);
		END LOOP;
	  END LOOP;

	END IF;

  WHEN '/order/item/list' THEN

    IF pPayload IS NOT NULL THEN
      arKeys := array_cat(arKeys, ARRAY['fields', 'search', 'filter', 'reclimit', 'recoffset', 'orderby']);
      PERFORM CheckJsonbKeys(pPath, arKeys, pPayload);
    ELSE
      pPayload := '{}';
    END IF;

    FOR r IN SELECT * FROM jsonb_to_record(pPayload) AS x(fields jsonb, search jsonb, filter jsonb, reclimit integer, recoffset integer, orderby jsonb)
    LOOP
      FOR e IN EXECUTE format('SELECT %s FROM api.list_order_item($1, $2, $3, $4, $5)', JsonbToFields(r.fields, GetColumns('order_item', 'api'))) USING r.search, r.filter, r.reclimit, r.recoffset, r.orderby
      LOOP
        RETURN NEXT row_to_json(e);
      END LOOP;
    END LOOP;

  ELSE
    RETURN NEXT ExecuteDynamicMethod(pPath, pPayload);
  END CASE;

  RETURN;
END;
$$ LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = kernel, pg_temp;
