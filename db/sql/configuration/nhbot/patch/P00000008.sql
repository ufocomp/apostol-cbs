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

DROP INDEX IF EXISTS db.product_turnover_product_client_timestamp_idx;

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', :'admin');

SELECT GetErrorMessage();

SELECT ExecuteObjectAction(id, GetAction('return')) FROM api.delivery WHERE IsDisabled(id);
SELECT ExecuteObjectAction(id, GetAction('return')) FROM api.order WHERE IsDisabled(id);
SELECT DoDelete(id) FROM api.product WHERE NOT IsDeleted(id);

SELECT DoDelete(id) FROM api.delivery WHERE IsActive(id);
SELECT DoDelete(id) FROM api.order WHERE IsActive(id);

SELECT DeleteDeliveryItem(id) FROM api.delivery;
SELECT DeleteOrderItem(id) FROM api.order;

SELECT SignOut();

\connect :dbname kernel

DELETE FROM db.product_turnover;
DELETE FROM db.product_balance;

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', :'admin');

SELECT GetErrorMessage();

SELECT DoDrop(id) FROM api.delivery;
SELECT DoDrop(id) FROM api.order;
SELECT DoDrop(id) FROM api.product;

SELECT SignOut();

\connect :dbname kernel

DROP TABLE db.delivery_item CASCADE;
DROP TABLE db.delivery CASCADE;

DROP TABLE db.order_item CASCADE;
DROP TABLE db.order CASCADE;

DROP TABLE db.product_turnover CASCADE;
DROP TABLE db.product_balance CASCADE;
DROP TABLE db.product CASCADE;

\ir '../entity/object/document/product/create.psql'
\ir '../entity/object/document/order/create.psql'
\ir '../entity/object/document/delivery/create.psql'
