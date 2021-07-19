--------------------------------------------------------------------------------
-- ORDER -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventOrderCreate ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderCreate (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Ордер создан.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderOpen --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderOpen (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'open', 'Ордер открыт.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderEdit --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderEdit (
  pObject	uuid default context_object(),
  pParams	jsonb default context_params()
) RETURNS	void
AS $$
BEGIN
  IF IsDisabled(pObject) THEN
	RAISE EXCEPTION 'ERR-40000: Изменения недопустимы.';
  END IF;

  PERFORM WriteToEventLog('M', 1000, 'edit', 'Ордер изменён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderSave --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderSave (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'save', 'Ордер сохранён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderEnable ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderEnable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Ордер отправлен.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderCancel ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderCancel (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'cancel', 'Ордер отменён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderApprove -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderApprove (
  pObject       uuid default context_object()
) RETURNS       void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'approve', 'Ордер утверждён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderReturn ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderReturn (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
DECLARE
  r				record;

  uProduct		uuid;
  uStorage		uuid;

  uClient		uuid;
BEGIN
  SELECT storage, client INTO uStorage, uClient FROM db.order WHERE id = pObject;

  FOR r IN SELECT * FROM db.order_item WHERE document = pObject ORDER BY itemid
  LOOP
	uProduct := GetProductId(uStorage, r.model, r.measure, r.currency, r.price);

	IF uProduct IS NOT NULL THEN
      PERFORM UpdateProductBalance(uProduct, pObject, uClient, r.measure, r.volume * -1);
	END IF;
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'return', 'Ордер возвращён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderDisable -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderDisable (
  pObject		uuid default context_object()
) RETURNS		void
AS $$
DECLARE
  r				record;

  uProduct		uuid;
  uStorage		uuid;

  uClient		uuid;
BEGIN
  SELECT storage, client INTO uStorage, uClient FROM db.order WHERE id = pObject;

  FOR r IN SELECT * FROM db.order_item WHERE document = pObject ORDER BY itemid
  LOOP
	uProduct := GetProductId(uStorage, r.model, r.measure, r.currency, r.price);

	IF uProduct IS NULL THEN
	  uProduct := CreateProduct(pObject, GetType('m17.product'), uClient, uStorage, r.model, r.measure, r.currency, null, r.price);
	END IF;

	PERFORM UpdateProductBalance(uProduct, pObject, uClient, r.measure, r.volume);
  END LOOP;

  PERFORM WriteToEventLog('M', 1000, 'disable', 'Ордер выполнен.', pObject);
END
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderDelete ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderDelete (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'delete', 'Ордер удалён.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderRestore -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderRestore (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'restore', 'Ордер восстановлен.', pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventOrderDrop --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventOrderDrop (
  pObject   uuid default context_object()
) RETURNS   void
AS $$
DECLARE
  r         record;
BEGIN
  SELECT label INTO r FROM db.object_text WHERE object = pObject AND locale = current_locale();

  PERFORM DeleteOrderItem(pObject);
  DELETE FROM db.order WHERE id = pObject;

  PERFORM WriteToEventLog('M', 2000, 'drop', '[' || pObject || '] [' || coalesce(r.label, '<null>') || '] Ордер уничтожен.');
END;
$$ LANGUAGE plpgsql;
