--------------------------------------------------------------------------------
-- CreateOrder -----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Создаёт ордер
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
 * @return {uuid} - Id
 */
CREATE OR REPLACE FUNCTION CreateOrder (
  pParent       uuid,
  pType         uuid,
  pStorage      uuid,
  pClient       uuid,
  pInsurance    uuid default null,
  pAccount      uuid default null,
  pCode         text default null,
  pAmount       numeric default null,
  pLabel        text default null,
  pDescription	text default null
) RETURNS 	    uuid
AS $$
DECLARE
  uId		    uuid;
  uOrder	    uuid;
  uDocument	    uuid;

  uClass	    uuid;
  uMethod	    uuid;
BEGIN
  SELECT class INTO uClass FROM type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'order' THEN
    PERFORM IncorrectClassType();
  END IF;

  SELECT id INTO uId FROM db.order WHERE code = pCode;

  IF FOUND THEN
    PERFORM OrderCodeExists(pCode);
  END IF;

  IF pStorage IS NOT NULL THEN
	SELECT id INTO uId FROM db.storage WHERE id = pStorage;
	IF NOT FOUND THEN
	  PERFORM ObjectNotFound('место хранения', 'id', pStorage);
	END IF;
  END IF;

  IF pClient IS NOT NULL THEN
	SELECT id INTO uId FROM db.client WHERE id = pClient;
	IF NOT FOUND THEN
	  PERFORM ObjectNotFound('клиент', 'id', pClient);
	END IF;
  ELSE
	SELECT client INTO pClient FROM db.storage WHERE id = pStorage;
  END IF;

  IF pInsurance IS NOT NULL THEN
	SELECT id INTO uId FROM db.client WHERE id = pInsurance;
	IF NOT FOUND THEN
	  PERFORM ObjectNotFound('клиент', 'id', pInsurance);
	END IF;
  END IF;

  IF pAccount IS NOT NULL THEN
	SELECT id INTO uId FROM db.account WHERE id = pAccount;
	IF NOT FOUND THEN
	  PERFORM ObjectNotFound('счёт', 'id', pAccount);
	END IF;
  END IF;

  IF pCode IS NULL THEN
	pCode := lpad(nextval('sequence_order')::text, 8, '0');
  END IF;

  IF pLabel IS NULL THEN
    pLabel := concat(GetTypeName(pType), ' № ', pCode);
  END IF;

  uDocument := CreateDocument(pParent, pType, pLabel, pDescription);

  INSERT INTO db.order (id, document, storage, client, insurance, account, code, amount)
  VALUES (uDocument, uDocument, pStorage, pClient, pInsurance, pAccount, pCode, coalesce(pAmount, 0))
  RETURNING id INTO uOrder;

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uOrder, uMethod);

  RETURN uOrder;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditOrder -------------------------------------------------------------------
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
CREATE OR REPLACE FUNCTION EditOrder (
  pId		    uuid,
  pParent       uuid default null,
  pType         uuid default null,
  pStorage      uuid default null,
  pClient       uuid default null,
  pInsurance    uuid default null,
  pAccount      uuid default null,
  pCode         text default null,
  pAmount       numeric default null,
  pLabel        text default null,
  pDescription	text default null
) RETURNS 	    void
AS $$
DECLARE
  uId		    uuid;
  uClass	    uuid;
  uMethod	    uuid;

  -- current
  cCode		    text;
BEGIN
  SELECT code INTO cCode FROM db.order WHERE id = pId;

  pCode := coalesce(pCode, cCode);

  IF pCode IS DISTINCT FROM cCode THEN
    SELECT id INTO uId FROM db.order WHERE code = pCode;
    IF FOUND THEN
      PERFORM OrderCodeExists(pCode);
    END IF;
  END IF;

  IF pStorage IS NOT NULL THEN
	SELECT id INTO uId FROM db.storage WHERE id = pStorage;
	IF NOT FOUND THEN
	  PERFORM ObjectNotFound('место хранения', 'id', pStorage);
	END IF;
  END IF;

  IF pClient IS NOT NULL THEN
	SELECT id INTO uId FROM db.client WHERE id = pClient;
	IF NOT FOUND THEN
	  PERFORM ObjectNotFound('клиент', 'id', pClient);
	END IF;
  END IF;

  IF pInsurance IS NOT NULL THEN
	SELECT id INTO uId FROM db.client WHERE id = pInsurance;
	IF NOT FOUND THEN
	  PERFORM ObjectNotFound('клиент', 'id', pInsurance);
	END IF;
  END IF;

  IF pAccount IS NOT NULL THEN
	SELECT id INTO uId FROM db.account WHERE id = pAccount;
	IF NOT FOUND THEN
	  PERFORM ObjectNotFound('счёт', 'id', pAccount);
	END IF;
  END IF;

  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription, pDescription, current_locale());

  UPDATE db.order
     SET storage = coalesce(pStorage, storage),
         client = coalesce(pClient, client),
         insurance = coalesce(pInsurance, insurance),
         account = coalesce(pAccount, account),
         code = coalesce(pCode, code),
         amount = coalesce(pAmount, amount)
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetOrder --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetOrder (
  pCode		text
) RETURNS	uuid
AS $$
  SELECT id FROM db.order WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetOrderAmount --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetOrderAmount (
  pOrder	uuid
) RETURNS	numeric
AS $$
  SELECT amount FROM db.order WHERE id = pOrder;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- AddOrderItem ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет запись в таблицу ордера
 * @param {uuid} pDocument - Ссылка на документ (ордер)
 * @param {uuid} pModel - Модель
 * @param {uuid} pMeasure - Мера
 * @param {uuid} pCurrency - Валюта
 * @param {uuid} pPrice - Цена
 * @param {uuid} pVolume - Объём
 * @param {text} pVat - Ставка НДС
 * @return {integer}
 */
CREATE OR REPLACE FUNCTION AddOrderItem (
  pDocument     uuid,
  pModel        uuid,
  pMeasure      uuid,
  pCurrency     uuid,
  pPrice        numeric,
  pVolume       numeric,
  pVat          numeric
) RETURNS 	    integer
AS $$
DECLARE
  nItemId	    integer;
BEGIN
  SELECT max(itemId) INTO nItemId FROM db.order_item WHERE document = pDocument;

  nItemId := coalesce(nItemId, 0) + 1;

  pMeasure := coalesce(pMeasure, GetMeasure('796'));
  pCurrency := coalesce(pCurrency, GetCurrency('RUB'));

  INSERT INTO db.order_item (document, itemId, model, measure, currency, price, volume, vat)
  VALUES (pDocument, nItemId, pModel, pMeasure, pCurrency, pPrice, pVolume, pVat);

  PERFORM ExecuteMethod(pDocument, GetMethod(GetObjectClass(pDocument), GetAction('edit')));

  RETURN nItemId;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- UpdateOrderItem -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет запись в таблице ордера
 * @param {uuid} pDocument - Ссылка на документ (ордер)
 * @param {integer} pItemId - Номер по порядку (номенклатурный номер)
 * @param {uuid} pModel - Модель
 * @param {uuid} pMeasure - Мера
 * @param {uuid} pCurrency - Валюта
 * @param {uuid} pPrice - Цена
 * @param {uuid} pVolume - Объём
 * @param {text} pVat - Ставка НДС
 * @return {boolean}
 */
CREATE OR REPLACE FUNCTION UpdateOrderItem (
  pDocument     uuid,
  pItemId       integer,
  pModel        uuid DEFAULT null,
  pMeasure      uuid DEFAULT null,
  pCurrency     uuid DEFAULT null,
  pPrice        numeric DEFAULT null,
  pVolume       numeric DEFAULT null,
  pVat          numeric DEFAULT null
) RETURNS 	    boolean
AS $$
BEGIN
  UPDATE db.order_item
     SET model = coalesce(pModel, model),
         measure = coalesce(pMeasure, measure),
         currency = coalesce(pCurrency, currency),
         price = coalesce(pPrice, price),
         volume = coalesce(pVolume, volume),
         vat = coalesce(pVat, vat)
   WHERE document = pDocument
     AND itemId = pItemId;

  IF FOUND THEN
	PERFORM ExecuteMethod(pDocument, GetMethod(GetObjectClass(pDocument), GetAction('edit')));
    RETURN true;
  END IF;

  RETURN false;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- DeleteOrderItem -------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Удаляет запись в таблице ордера
 * @param {uuid} pDocument - Ссылка на документ (ордер)
 * @param {integer} pItemId - Номер по порядку (номенклатурный номер)
 * @return {boolean}
 */
CREATE OR REPLACE FUNCTION DeleteOrderItem (
  pDocument     uuid,
  pItemId       integer DEFAULT null
) RETURNS 	    boolean
AS $$
DECLARE
  nAmount		numeric;
BEGIN
  IF pItemId IS NOT NULL THEN
    DELETE FROM db.order_item WHERE document = pDocument AND itemId = pItemId;
  ELSE
    DELETE FROM db.order_item WHERE document = pDocument;
  END IF;

  IF FOUND THEN
    SELECT Sum(amount) INTO nAmount FROM db.order_item WHERE document = pDocument;
    PERFORM EditOrder(pDocument, pAmount => nAmount);

    PERFORM SortOrderItem(pDocument);

    RETURN true;
  END IF;

  RETURN false;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- SetOrderItem ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Добавляет или обновляет запись в таблице ордера
 * @param {uuid} pDocument - Ссылка на документ (ордер)
 * @param {integer} pItemId - Номер по порядку (номенклатурный номер)
 * @param {uuid} pModel - Модель
 * @param {uuid} pMeasure - Мера
 * @param {uuid} pCurrency - Валюта
 * @param {uuid} pPrice - Цена
 * @param {uuid} pVolume - Объём
 * @param {text} pVat - Ставка НДС
 * @return {integer}
 */
CREATE OR REPLACE FUNCTION SetOrderItem (
  pDocument     uuid,
  pItemId       integer,
  pModel        uuid DEFAULT null,
  pMeasure      uuid DEFAULT null,
  pCurrency     uuid DEFAULT null,
  pPrice        numeric DEFAULT null,
  pVolume       numeric DEFAULT null,
  pVat          numeric DEFAULT null
) RETURNS 	    integer
AS $$
DECLARE
  uId		    uuid;
  nAmount       numeric;
BEGIN
  SELECT id INTO uId FROM db.order WHERE id = pDocument;
  IF NOT FOUND THEN
	PERFORM ObjectNotFound('ордер', 'id', pDocument);
  END IF;

  SELECT id INTO uId FROM db.model WHERE id = pModel;
  IF NOT FOUND THEN
	PERFORM ObjectNotFound('модель', 'id', pModel);
  END IF;

  SELECT id INTO uId FROM db.measure WHERE id = pMeasure;
  IF NOT FOUND THEN
	PERFORM ObjectNotFound('мера', 'id', pMeasure);
  END IF;

  IF nullif(pItemId, 0) IS NULL THEN
	pItemId := AddOrderItem(pDocument, pModel, pMeasure, pCurrency, pPrice, pVolume, pVat);
  ELSE
    IF NOT UpdateOrderItem(pDocument, pItemId, pModel, pMeasure, pCurrency, pPrice, pVolume, pVat) THEN
      PERFORM ValueOutOfRange(pItemId);
	END IF;
  END IF;

  SELECT Sum(amount) INTO nAmount FROM db.order_item WHERE document = pDocument;

  PERFORM EditOrder(pDocument, pAmount => nAmount);

  RETURN pItemId;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION SetOrderId ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION SetOrderId (
  pDocument uuid,
  pOldId	integer,
  pNewId	integer,
  pDelta	integer
) RETURNS 	void
AS $$
DECLARE
  uId		uuid;
BEGIN
  IF pDelta <> 0 THEN
    SELECT document INTO uId
      FROM db.order_item
     WHERE document = pDocument
       AND itemId = pNewId;

    IF FOUND THEN
      PERFORM SetOrderId(pDocument, pNewId, pNewId + pDelta, pDelta);
    END IF;
  END IF;

  IF pOldId IS DISTINCT FROM pNewId THEN
    UPDATE db.order_item SET itemId = pNewId WHERE document = pDocument AND itemId = pOldId;
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FUNCTION SortOrderItem ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION SortOrderItem (
  pDocument uuid
) RETURNS 	void
AS $$
DECLARE
  r         record;
BEGIN
  FOR r IN
    SELECT itemId, (row_number() OVER(order by itemId))::int as newitemId
      FROM db.order_item
     WHERE document IS NOT DISTINCT FROM pDocument
  LOOP
    PERFORM SetOrderId(pDocument, r.itemId, r.newitemId, 0);
  END LOOP;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetOrderItemJson ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetOrderItemJson (
  pDocument	uuid
) RETURNS	json
AS $$
DECLARE
  r			record;
  arResult	json[];
BEGIN
  FOR r IN
    SELECT *
      FROM OrderItemJson
     WHERE DocumentId = pDocument
     ORDER BY ItemId
  LOOP
    arResult := array_append(arResult, row_to_json(r));
  END LOOP;

  RETURN array_to_json(arResult);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetOrderItemJsonb -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetOrderItemJsonb (
  pDocument	uuid
) RETURNS	jsonb
AS $$
BEGIN
  RETURN GetOrderItemJson(pDocument);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
