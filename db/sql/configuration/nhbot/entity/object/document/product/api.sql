--------------------------------------------------------------------------------
-- NOMENCLATURE ----------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- api.product -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.product
AS
  SELECT * FROM ObjectProduct;

GRANT SELECT ON api.product TO administrator;

--------------------------------------------------------------------------------
-- api.product_turnover --------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW api.product_turnover
AS
  SELECT * FROM ProductTurnover;

GRANT SELECT ON api.product_turnover TO administrator;

--------------------------------------------------------------------------------
-- api.add_product -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет продукт (ТМЦ).
 * @param {uuid} pParent - Идентификатор родителя | null
 * @param {text} pType -Идентификатор типа
 * @param {uuid} pClient - Идентификатор сотрудника (МОЛ)
 * @param {uuid} pStorage - Идентификатор места хранения
 * @param {uuid} pModel - Идентификатор модели
 * @param {uuid} pMeasure - Идентификатор меры
 * @param {uuid} pCurrency - Идентификатор валюты
 * @param {text} pCode - Номенклатурный номер
 * @param {text} pRack - Стеллаж
 * @param {text} pCell - Ячейка
 * @param {numeric} pPrice - Цена
 * @param {text} pSort - Сорт
 * @param {text} pProfile - Профиль
 * @param {text} pSize - Размер
 * @param {numeric} pNorm - Норма запаса
 * @param {timestamptz} pExpire - Срок годности
 * @param {text} pName - Наименование (если не указать подтянется из модели)
 * @param {text} pDescription - Описание (если не указать подтянется из модели)
 * @return {uuid}
 */
CREATE OR REPLACE FUNCTION api.add_product (
  pParent       uuid,
  pType         uuid DEFAULT null,
  pClient       uuid DEFAULT null,
  pStorage      uuid DEFAULT null,
  pModel        uuid DEFAULT null,
  pMeasure      uuid DEFAULT null,
  pCurrency     uuid DEFAULT null,
  pCode         text DEFAULT null,
  pPrice        numeric DEFAULT null,
  pRack         text DEFAULT null,
  pCell         text DEFAULT null,
  pSort         text DEFAULT null,
  pProfile      text DEFAULT null,
  pSize         text DEFAULT null,
  pNorm         numeric DEFAULT null,
  pExpire       timestamptz DEFAULT null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       uuid
AS $$
BEGIN
  RETURN CreateProduct(pParent, coalesce(pType, GetType('m17.product')), pClient, pStorage, pModel, pMeasure, pCurrency, pCode, pPrice, pRack, pCell, pSort, pProfile, pSize, pNorm, pExpire, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.update_product ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет данные продукта (ТМЦ).
 * @param {uuid} pId - Идентификатор
 * @param {uuid} pParent - Идентификатор родителя | null
 * @param {uuid} pType - Идентификатор типа
 * @param {uuid} pClient - Идентификатор сотрудника (МОЛ)
 * @param {uuid} pStorage - Идентификатор места хранения
 * @param {uuid} pModel - Идентификатор модели
 * @param {uuid} pMeasure - Идентификатор меры
 * @param {uuid} pCurrency - Идентификатор валюты
 * @param {text} pCode - Номенклатурный номер
 * @param {text} pRack - Стеллаж
 * @param {text} pCell - Ячейка
 * @param {numeric} pPrice - Цена
 * @param {text} pSort - Сорт
 * @param {text} pProfile - Профиль
 * @param {text} pSize - Размер
 * @param {numeric} pNorm - Норма запаса
 * @param {timestamptz} pExpire - Срок годности
 * @param {text} pName - Наименование (если не указать подтянется из модели)
 * @param {text} pDescription - Описание (если не указать подтянется из модели)
 * @return {void}
 */
CREATE OR REPLACE FUNCTION api.update_product (
  pId           uuid,
  pParent       uuid DEFAULT null,
  pType         uuid DEFAULT null,
  pClient       uuid DEFAULT null,
  pStorage      uuid DEFAULT null,
  pModel        uuid DEFAULT null,
  pMeasure      uuid DEFAULT null,
  pCurrency     uuid DEFAULT null,
  pCode         text DEFAULT null,
  pPrice        numeric DEFAULT null,
  pRack         text DEFAULT null,
  pCell         text DEFAULT null,
  pSort         text DEFAULT null,
  pProfile      text DEFAULT null,
  pSize         text DEFAULT null,
  pNorm         numeric DEFAULT null,
  pExpire       timestamptz DEFAULT null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       void
AS $$
DECLARE
  uProduct      uuid;
BEGIN
  SELECT id INTO uProduct FROM db.product WHERE id = pId;
  IF NOT FOUND THEN
    PERFORM ObjectNotFound('продукт', 'id', pId);
  END IF;

  PERFORM EditProduct(uProduct, pParent, pType, pClient, pStorage, pModel, pMeasure, pCurrency, pCode, pPrice, pRack, pCell, pSort, pProfile, pSize, pNorm, pExpire, pLabel, pDescription);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.set_product -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION api.set_product (
  pId           uuid,
  pParent       uuid DEFAULT null,
  pType         uuid DEFAULT null,
  pClient       uuid DEFAULT null,
  pStorage      uuid DEFAULT null,
  pModel        uuid DEFAULT null,
  pMeasure      uuid DEFAULT null,
  pCurrency     uuid DEFAULT null,
  pCode         text DEFAULT null,
  pPrice        numeric DEFAULT null,
  pRack         text DEFAULT null,
  pCell         text DEFAULT null,
  pSort         text DEFAULT null,
  pProfile      text DEFAULT null,
  pSize         text DEFAULT null,
  pNorm         numeric DEFAULT null,
  pExpire       timestamptz DEFAULT null,
  pLabel        text default null,
  pDescription  text default null
) RETURNS       SETOF api.product
AS $$
BEGIN
  IF pId IS NULL THEN
    pId := api.add_product(pParent, pType, pClient, pStorage, pModel, pMeasure, pCurrency, pCode, pPrice, pRack, pCell, pSort, pProfile, pSize, pNorm, pExpire, pLabel, pDescription);
  ELSE
    PERFORM api.update_product(pId, pParent, pType, pClient, pStorage, pModel, pMeasure, pCurrency, pCode, pPrice, pRack, pCell, pSort, pProfile, pSize, pNorm, pExpire, pLabel, pDescription);
  END IF;

  RETURN QUERY SELECT * FROM api.product WHERE id = pId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_product -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает продукт (ТМЦ)
 * @param {uuid} pId - Идентификатор
 * @return {api.product}
 */
CREATE OR REPLACE FUNCTION api.get_product (
  pId		uuid
) RETURNS	SETOF api.product
AS $$
  SELECT * FROM api.product WHERE id = pId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_product ------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список продуктов (ТМЦ).
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.product}
 */
CREATE OR REPLACE FUNCTION api.list_product (
  pSearch	jsonb DEFAULT null,
  pFilter	jsonb DEFAULT null,
  pLimit	integer DEFAULT null,
  pOffSet	integer DEFAULT null,
  pOrderBy	jsonb DEFAULT null
) RETURNS	SETOF api.product
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'product', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_product_balance -----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает остаток продукта (ТМЦ) на складе
 * @param {uuid} pId - Идентификатор
 * @param {timestamptz} pDateTime - Дата и время
 * @return {numeric}
 */
CREATE OR REPLACE FUNCTION api.get_product_balance (
  pId       uuid,
  pDateTime timestamptz DEFAULT oper_date()
) RETURNS   numeric
AS $$
BEGIN
  IF NOT CheckObjectAccess(pId, B'100') THEN
	PERFORM AccessDenied();
  END IF;

  RETURN GetProductBalance(pId, pDateTime);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.get_product_turnover ----------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает запись из оборотной ведомости продукта (ТМЦ)
 * @param {uuid} pProduct - Идентификатор продукта
 * @param {integer} pOrderId - Порядковый номер (номенклатурный)
 * @return {api.product_turnover}
 */
CREATE OR REPLACE FUNCTION api.get_product_turnover (
  pProduct  uuid,
  pOrderId  integer
) RETURNS	SETOF api.product_turnover
AS $$
  SELECT * FROM api.product_turnover WHERE product = pProduct AND orderId = pOrderId
$$ LANGUAGE SQL
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- api.list_product_turnover ---------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает список записей в оборотной ведомости продукта (ТМЦ).
 * @param {jsonb} pSearch - Условие: '[{"condition": "AND|OR", "field": "<поле>", "compare": "EQL|NEQ|LSS|LEQ|GTR|GEQ|GIN|LKE|ISN|INN", "value": "<значение>"}, ...]'
 * @param {jsonb} pFilter - Фильтр: '{"<поле>": "<значение>"}'
 * @param {integer} pLimit - Лимит по количеству строк
 * @param {integer} pOffSet - Пропустить указанное число строк
 * @param {jsonb} pOrderBy - Сортировать по указанным в массиве полям
 * @return {SETOF api.product_turnover}
 */
CREATE OR REPLACE FUNCTION api.list_product_turnover (
  pSearch	jsonb DEFAULT null,
  pFilter	jsonb DEFAULT null,
  pLimit	integer DEFAULT null,
  pOffSet	integer DEFAULT null,
  pOrderBy	jsonb DEFAULT null
) RETURNS	SETOF api.product_turnover
AS $$
BEGIN
  RETURN QUERY EXECUTE api.sql('api', 'product_turnover', pSearch, pFilter, pLimit, pOffSet, pOrderBy);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
