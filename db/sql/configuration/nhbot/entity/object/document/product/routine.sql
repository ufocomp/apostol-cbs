--------------------------------------------------------------------------------
-- CreateProduct ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION CreateProduct (
  pParent       uuid,
  pType         uuid,
  pClient       uuid,
  pStorage      uuid,
  pModel        uuid,
  pMeasure      uuid,
  pCurrency     uuid,
  pCode         text,
  pPrice        numeric,
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
DECLARE
  r             db.product%rowtype;

  uDocument     uuid;
  uClass        uuid;
  uMethod       uuid;

  vName         text;
  vDescription  text;
BEGIN
  SELECT class INTO uClass FROM db.type WHERE id = pType;

  IF GetEntityCode(uClass) <> 'product' THEN
    PERFORM IncorrectClassType();
  END IF;

  IF pParent IS NOT NULL THEN
    SELECT * INTO r FROM db.product WHERE id = pParent;
    IF FOUND THEN
	  pClient := coalesce(pClient, r.client);
	  pStorage := coalesce(pStorage, r.storage);
	  pModel := coalesce(pModel, r.model);
	  pMeasure := coalesce(pMeasure, r.measure);
	  pCurrency := coalesce(pCurrency, r.currency);
	  pPrice := coalesce(pPrice, r.price);
	  pRack := CheckNull(coalesce(pRack, r.rack, '<null>'));
	  pCell := CheckNull(coalesce(pCell, r.cell, '<null>'));
	  pSort := CheckNull(coalesce(pSort, r.sort, '<null>'));
	  pProfile := CheckNull(coalesce(pProfile, r.profile, '<null>'));
	  pSize := CheckNull(coalesce(pSize, r.size, '<null>'));
	  pNorm := CheckNull(coalesce(pNorm, r.norm, 0));
	  pExpire := CheckNull(coalesce(pExpire, r.expire, MINDATE()));
    END IF;
  END IF;

  IF pModel IS NOT NULL THEN
	SELECT name, description INTO vName, vDescription FROM Reference WHERE id = pModel;
  END IF;

  pMeasure := coalesce(pMeasure, GetMeasure('796'));
  pCurrency := coalesce(pCurrency, GetCurrency('RUB'));

  uDocument := CreateDocument(pParent, pType, coalesce(pLabel, vName), coalesce(pDescription, vDescription));

  INSERT INTO db.product (id, document, client, storage, model, measure, currency, code, rack, cell, price, sort, profile, size, norm, expire)
  VALUES (uDocument, uDocument, pClient, pStorage, pModel, pMeasure, pCurrency, pCode, pRack, pCell, pPrice, pSort, pProfile, pSize, pNorm, pExpire);

  uMethod := GetMethod(uClass, GetAction('create'));
  PERFORM ExecuteMethod(uDocument, uMethod);

  RETURN uDocument;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- EditProduct -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EditProduct (
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
  uClass        uuid;
  uMethod       uuid;
BEGIN
  PERFORM EditDocument(pId, pParent, pType, pLabel, pDescription, pDescription, current_locale());

  UPDATE db.product
     SET client = coalesce(pClient, client),
         storage = coalesce(pStorage, storage),
         model = coalesce(pModel, model),
         measure = coalesce(pMeasure, measure),
         currency = coalesce(pCurrency, currency),
         code = coalesce(pCode, code),
         price = coalesce(pPrice, price),
         rack = CheckNull(coalesce(pRack, rack, '<null>')),
         cell = CheckNull(coalesce(pCell, cell, '<null>')),
         sort = CheckNull(coalesce(pSort, sort, '<null>')),
         profile = CheckNull(coalesce(pProfile, profile, '<null>')),
         size = CheckNull(coalesce(pSize, size, '<null>')),
         norm = CheckNull(coalesce(pNorm, norm, 0)),
         expire = CheckNull(coalesce(pExpire, expire, MINDATE()))
   WHERE id = pId;

  uClass := GetObjectClass(pId);
  uMethod := GetMethod(uClass, GetAction('edit'));
  PERFORM ExecuteMethod(pId, uMethod);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetProductId ----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetProductId (
  pStorage  uuid,
  pModel    uuid,
  pMeasure  uuid,
  pCurrency uuid,
  pPrice    numeric
) RETURNS	uuid
AS $$
  SELECT id
    FROM db.product
   WHERE storage = pStorage
     AND model = pModel
     AND measure = pMeasure
     AND currency = pCurrency
     AND price = pPrice;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetProduct ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetProduct (
  pCode		text
) RETURNS	uuid
AS $$
  SELECT id FROM db.product WHERE code = pCode;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetProductCode --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetProductCode (
  pProduct uuid
) RETURNS       text
AS $$
  SELECT code FROM db.product WHERE id = pProduct;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetProductClient ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetProductClient (
  pProduct  uuid
) RETURNS   uuid
AS $$
  SELECT client FROM db.product WHERE id = pProduct;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetProductPrice -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION GetProductPrice (
  pProduct  uuid
) RETURNS   numeric
AS $$
  SELECT price FROM db.product WHERE id = pProduct;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- ChangeProductBalance --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Меняет остаток товара (ТМЦ) на складе.
 * @param {uuid} pProduct - Продукт (товар)
 * @param {numeric} pAmount - Сумма
 * @param {timestamptz} pDateFrom - Дата
 * @return {void}
 */
CREATE OR REPLACE FUNCTION ChangeProductBalance (
  pProduct      uuid,
  pAmount       numeric,
  pDateFrom     timestamptz DEFAULT Now()
) RETURNS       void
AS $$
DECLARE
  dtDateFrom    timestamptz;
  dtDateTo      timestamptz;
BEGIN
  -- получим дату значения в текущем диапозоне дат
  SELECT validFromDate, validToDate INTO dtDateFrom, dtDateTo
    FROM db.product_balance
   WHERE product = pProduct
     AND validFromDate <= pDateFrom
     AND validToDate > pDateFrom;

  IF coalesce(dtDateFrom, MINDATE()) = pDateFrom THEN
    -- обновим значение в текущем диапозоне дат
    UPDATE db.product_balance SET amount = pAmount
     WHERE product = pProduct
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;
  ELSE
    -- обновим дату значения в текущем диапозоне дат
    UPDATE db.product_balance SET validToDate = pDateFrom
     WHERE product = pProduct
       AND validFromDate <= pDateFrom
       AND validToDate > pDateFrom;

    INSERT INTO db.product_balance (product, amount, validfromdate, validToDate)
    VALUES (pProduct, pAmount, pDateFrom, coalesce(dtDateTo, MAXDATE()));
  END IF;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- NewProductTurnOver ----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Новое запись в карточке учёта материалов.
 * @param {uuid} pProduct -  Продукт (товар)
 * @param {uuid} pDocument - Ссылка на первичный документ (ордер, накладная)
 * @param {uuid} pClient - Клиент
 * @param {uuid} pMeasure - Мера
 * @param {numeric} pDebit - Сумма обота по дебету
 * @param {numeric} pCredit - Сумма обота по кредиту
 * @param {timestamptz} pTimestamp - Дата
 * @return {integer}
 */
CREATE OR REPLACE FUNCTION NewProductTurnOver (
  pProduct      uuid,
  pDocument		uuid,
  pClient       uuid,
  pMeasure		uuid,
  pDebit        numeric,
  pCredit       numeric,
  pTimestamp    timestamptz DEFAULT Now()
) RETURNS       integer
AS $$
DECLARE
  nOrderId      integer;
BEGIN
  SELECT max(orderId) INTO nOrderId FROM db.product_turnover WHERE product = pProduct;

  nOrderId := coalesce(nOrderId, 0) + 1;

  INSERT INTO db.product_turnover (product, orderId, document, client, measure, debit, credit, timestamp)
  VALUES (pProduct, nOrderId, pDocument, pClient, pMeasure, pDebit, pCredit, pTimestamp);

  RETURN nOrderId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- UpdateProductBalance --------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Обновляет остаток товара (ТМЦ) на складе.
 * @param {uuid} pProduct -  Продукт (товар)
 * @param {uuid} pDocument - Ссылка на первичный документ (ордер, накладная)
 * @param {uuid} pClient - Клиент
 * @param {uuid} pMeasure - Мера
 * @param {numeric} pAmount - Сумма изменения остатка. Если сумма положительная, то это получение, если сумма отрицательная - то это списание.
 * @param {timestamptz} pDateFrom - Дата
 * @return {numeric} - Баланс (остаток)
 */
CREATE OR REPLACE FUNCTION UpdateProductBalance (
  pProduct      uuid,
  pDocument		uuid,
  pClient       uuid,
  pMeasure		uuid,
  pAmount       numeric,
  pDateFrom     timestamptz DEFAULT Now()
) RETURNS       numeric
AS $$
DECLARE
  nOrderId      integer;
  nBalance      numeric;
BEGIN
  IF pAmount > 0 THEN
    nOrderId := NewProductTurnOver(pProduct, pDocument, pClient, pMeasure, 0, pAmount, pDateFrom);
  END IF;

  IF pAmount < 0 THEN
    nOrderId := NewProductTurnOver(pProduct, pDocument, pClient, pMeasure, pAmount, 0, pDateFrom);
  END IF;

  if nOrderId IS NOT NULL THEN
    SELECT Sum(credit) + Sum(debit) INTO nBalance
      FROM db.product_turnover
     WHERE product = pProduct;

    PERFORM ChangeProductBalance(pProduct, nBalance, pDateFrom);
  END IF;

  RETURN nBalance;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- GetProductBalance -----------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * Возвращает остаток товара (ТМЦ) на складе.
 * @param {numeric} pProduct -  Продукт (товар)
 * @param {timestamptz} pDateFrom - Дата
 * @return {numeric} - Баланс (остаток)
 */
CREATE OR REPLACE FUNCTION GetProductBalance (
  pProduct      uuid,
  pDateFrom     timestamptz DEFAULT oper_date()
) RETURNS       numeric
AS $$
  SELECT amount
    FROM db.product_balance
   WHERE product = pProduct
     AND validFromDate <= pDateFrom
     AND validToDate > pDateFrom;
$$ LANGUAGE sql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
