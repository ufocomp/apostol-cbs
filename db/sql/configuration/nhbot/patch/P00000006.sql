\ir '../entity/object/document/demand/create.psql'
\ir '../entity/object/document/order/create.psql'
\ir '../entity/object/document/product/create.psql'
\ir '../entity/object/document/delivery/create.psql'

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', 'admin');

SELECT GetErrorMessage();

SELECT CreateEntityDemand(GetClass('document'));
SELECT CreateEntityOrder(GetClass('document'));
SELECT CreateEntityProduct(GetClass('document'));
SELECT CreateEntityDelivery(GetClass('document'));

SELECT SignOut();

\connect :dbname kernel

