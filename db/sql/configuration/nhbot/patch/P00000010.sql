\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', :'admin');

SELECT GetErrorMessage();

SELECT ExecuteObjectAction(id, GetAction('return')) FROM api.delivery WHERE IsDisabled(id);
SELECT ExecuteObjectAction(id, GetAction('return')) FROM api.order WHERE IsDisabled(id);

SELECT DoDelete(id) FROM api.product WHERE NOT IsDeleted(id);
SELECT DoDelete(id) FROM api.delivery WHERE NOT IsDeleted(id);
SELECT DoDelete(id) FROM api.order WHERE NOT IsDeleted(id);

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

DELETE FROM db.event WHERE class = GetClass('delivery');
DELETE FROM db.transition WHERE method IN (SELECT id FROM db.method WHERE class = GetClass('delivery'));
DELETE FROM db.method WHERE class = GetClass('delivery');
DELETE FROM db.state WHERE class = GetClass('delivery');
DELETE FROM db.type WHERE class = GetClass('delivery');
DELETE FROM db.class_tree WHERE id = GetClass('delivery');
DELETE FROM db.entity WHERE id = GetEntity('delivery');

SELECT setval('sequence_order', 1, false);
SELECT setval('sequence_delivery', 1, false);

CREATE SEQUENCE IF NOT EXISTS sequence_product
 START WITH 1
 INCREMENT BY 1
 MINVALUE 1;

\ir '../entity/object/document/delivery/init.sql'

SELECT CreateEntityDelivery(GetClass('document'));
