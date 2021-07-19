--------------------------------------------------------------------------------
-- ORDER -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.order -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.order
AS
  SELECT * FROM ObjectOrder;

GRANT SELECT ON api.order TO administrator;

--------------------------------------------------------------------------------
-- api.add_order ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет ордер.
 * @param {uuid} pParent - Ссылка на родительский объект: api.document | null
 * @param {uuid} pType - Идентификатор типа
 * @param {uuid} pStorage - Место хранения (склад)
 * @param {uuid} pClient - Клиент
 * @param {uuid} pInsurance - Страховая компания
 * @param {uuid} pAccount - Корреспондирующий счет
 * @param {text} pCode - Код
 * @param {numeric} pAmount - Сумма
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_order (
  pParent       uuid,
  pType         uuid,
  pStorage      uuid,
  pClient       uuid,
  pInsurance    uuid,
  pAccount      uuid,
  pCode         text,
  pAmount       numeric,
  pLabel        text default null,
  pDescription	text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateOrder(pParent, coalesce(pType, GetType('m4.order')), pStorage, pClient, pInsurance, pAccount, pCode, pAmount, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_order ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Редактирует ордер.
 * @param {uuid} pParent - Ссылка на родительский объект: Object.Parent | null
 * @param {uuid} pType - Идентификатор типа
 * @param {uuid} pStorage - Место хранения (склад)
 * @param {uuid} pClient - Клиент
 * @param {uuid} pInsurance - Страховая компания
 * @param {uuid} pAccount - Корреспондирующий счет
 * @param {text} pCode - Код
 * @param {numeric} pAmount - Сумма
 * @param {text} pLabel - Метка
 * @param {text} pDescription - Описание
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_order (
  pId		    uuid,
  pParent	    uuid default null,
  pType		    uuid default null,
  pStorage      uuid default null,
  pClient       uuid default null,
  pInsurance    uuid default null,
  pAccount      uuid default null,
  pCode         text default null,
  pAmount       numeric default null,
  pLabel        text default null,
  pDescription	text default null
) RETURNS       void
AS $$
DECLARE
  uOrder        uuid;
BEGIN
  pId := coalesce(NULLIF(pId, null_uuid()), GetOrder(pCode));

  SELECT c.id INTO uOrder FROM db.order c WHERE c.id = pId;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('ордер', 'id', pId);
  END IF;

  PERFORM EditOrder(uOrder, pParent, pType, pStorage, pClient, pInsurance, pAccount, pCode, pAmount, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_order ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_order (
  pId		    uuid,
  pParent	    uuid default null,
  pType		    uuid default null,
  pStorage      uuid default null,
  pClient       uuid default null,
  pInsurance    uuid default null,
  pAccount      uuid default null,
  pCode         text default null,
  pAmount       numeric default null,
  pLabel        text default null,
  pDescription	text default null
) RETURNS       SETOF api.order
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_order(pParent, pType, pStorage, pClient, pInsurance, pAccount, pCode, pAmount, pLabel, pDescription);
  ELSE
    PERFORM api.update_order(pId, pParent, pType, pStorage, pClient, pInsurance, pAccount, pCode, pAmount, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.order WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_order ---------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает ордер
 * @param {uuid} pId - Идентификатор
 * @return {api.order} - Ордер
 */
CREATE OR REPLACE FUNCTION api.get_order (
  pId		uuid
) RETURNS	api.order
AS $$
  SELECT * FROM api.order WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_order --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список ордеров.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.order} - Ордера
 */
CREATE OR REPLACE FUNCTION api.list_order (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.order
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'order', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- ORDER ITEM ------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.order_item --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.order_item
AS
  SELECT * FROM OrderItemJson;

GRANT SELECT ON api.order_item TO administrator;

--------------------------------------------------------------------------------
-- api.set_order_item_json -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_order_item_json (
  pDocument		uuid,
  pItems        json
) RETURNS		SETOF api.order_item
AS $$
DECLARE
  r				record;
  e				record;

  uOrder        uuid;
  uModel		uuid;
  uMeasure		uuid;
  uCurrency		uuid;

  arKeys		text[];
BEGIN
  SELECT id INTO uOrder FROM db.order WHERE id = pDocument;

  IF NOT FOUND THEN
    PERFORM ObjectNotFound('ордер', 'id', pDocument);
  END IF;

  IF pItems IS NULL THEN
    PERFORM JsonIsEmpty();
  END IF;

  arKeys := array_cat(arKeys, ARRAY['modelid', 'measureid', 'currencyid', 'model', 'measure', 'currency', 'price', 'volume', 'amount', 'vat']);
  PERFORM CheckJsonKeys('/order/item/set', arKeys, pItems);

  PERFORM api.clear_order_item(pDocument);

  FOR r IN SELECT * FROM json_to_recordset(pItems) AS x(modelid uuid, measureid uuid, currencyid uuid, model json, measure json, currency json, price numeric, volume numeric, amount numeric, vat numeric)
  LOOP
    uModel := GetModel('unknown.model');
    uMeasure := GetMeasure('796');
    uCurrency := GetCurrency('RUB');

    IF r.model IS NOT NULL THEN

      arKeys := array_cat(arKeys, GetRoutines('set_model', 'api', false));
      PERFORM CheckJsonbKeys('/order/item/model/set', arKeys, r.model);

      FOR e IN EXECUTE format('SELECT api.set_model(%s) FROM jsonb_to_recordset($1) AS x(%s)', array_to_string(GetRoutines('set_model', 'api', false, 'x'), ', '), array_to_string(GetRoutines('set_model', 'api', true), ', ')) USING r.model
      LOOP
	    uModel := e.id;
      END LOOP;
	END IF;

    IF r.measure IS NOT NULL THEN

	  arKeys := array_cat(arKeys, GetRoutines('set_measure', 'api', false));
      PERFORM CheckJsonbKeys('/order/item/measure/set', arKeys, r.measure);

      FOR e IN EXECUTE format('SELECT api.set_measure(%s) FROM jsonb_to_recordset($1) AS x(%s)', array_to_string(GetRoutines('set_measure', 'api', false, 'x'), ', '), array_to_string(GetRoutines('set_measure', 'api', true), ', ')) USING r.measure
      LOOP
	    uMeasure := e.id;
      END LOOP;
	END IF;

    IF r.currency IS NOT NULL THEN

	  arKeys := array_cat(arKeys, GetRoutines('set_currency', 'api', false));
      PERFORM CheckJsonbKeys('/order/item/currency/set', arKeys, r.currency);

      FOR e IN EXECUTE format('SELECT api.set_currency(%s) FROM jsonb_to_recordset($1) AS x(%s)', array_to_string(GetRoutines('set_currency', 'api', false, 'x'), ', '), array_to_string(GetRoutines('set_currency', 'api', true), ', ')) USING r.currency
      LOOP
	    uCurrency := e.id;
      END LOOP;
	END IF;

	RETURN QUERY SELECT * FROM api.set_order_item(uOrder, 0, coalesce(r.modelId, uModel), coalesce(r.measureId, uMeasure), coalesce(r.currencyId, uCurrency), r.price, r.volume, r.vat);
  END LOOP;

  RETURN;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_order_item_jsonb ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_order_item_jsonb (
  pDocument uuid,
  pItems    jsonb
) RETURNS   SETOF api.order_item
AS $$
BEGIN
  RETURN QUERY SELECT * FROM api.set_order_item_json(pDocument, pItems::json);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_order_item_json -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_order_item_json (
  pDocument     uuid
) RETURNS		json
AS $$
BEGIN
  RETURN GetOrderItemJson(pDocument);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_order_item_jsonb ----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.get_order_item_jsonb (
  pDocument     uuid
) RETURNS       jsonb
AS $$
BEGIN
  RETURN GetOrderItemJsonb(pDocument);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_order_item ----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_order_item (
  pDocument     uuid,
  pItemId       integer,
  pModel        uuid DEFAULT null,
  pMeasure      uuid DEFAULT null,
  pCurrency     uuid DEFAULT null,
  pPrice        numeric DEFAULT null,
  pVolume       numeric DEFAULT null,
  pVat          numeric DEFAULT null
) RETURNS       SETOF api.order_item
AS $$
DECLARE
  nItemId		integer;
BEGIN
  nItemId := SetOrderItem(pDocument, pItemId, pModel, pMeasure, pCurrency, pPrice, pVolume, pVat);

  RETURN QUERY SELECT * FROM api.order_item WHERE documentId = pDocument AND itemId = nItemId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.delete_order_item -------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.delete_order_item (
  pDocument     uuid,
  pItemId       integer
) RETURNS       boolean
AS $$
BEGIN
  RETURN DeleteOrderItem(pDocument, pItemId);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.clear_order_item --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.clear_order_item (
  pDocument     uuid
) RETURNS       boolean
AS $$
BEGIN
  RETURN DeleteOrderItem(pDocument);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_order_item ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает номенклатуру ордера
 * @param {uuid} pDocument - Ссылка на документ (ордер)
 * @param {integer} pItemId - Номер по порядку (номенклатурный номер)
 * @return {api.order} - Ордер
 */
CREATE OR REPLACE FUNCTION api.get_order_item (
  pDocument     uuid,
  pItemId       integer
) RETURNS       api.order_item
AS $$
  SELECT * FROM api.order_item WHERE documentId = pDocument AND itemId = pItemId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_order --------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список номенклатур ордеров.
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.order_item}
 */
CREATE OR REPLACE FUNCTION api.list_order_item (
  pSearch	jsonb default null,
  pFilter	jsonb default null,
  pLimit	integer default null,
  pOffSet	integer default null,
  pOrderBy	jsonb default null
) RETURNS	SETOF api.order_item
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'order_item', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
