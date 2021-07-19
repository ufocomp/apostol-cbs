DROP TABLE db.catalog CASCADE;
DROP TABLE db.element CASCADE;

DROP FUNCTION CreateCatalog(uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, integer);
DROP FUNCTION EditCatalog(uuid, uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, integer);

DROP FUNCTION CreateElement(uuid, uuid, uuid, uuid, text, jsonb, text, text);
DROP FUNCTION EditElement(uuid, uuid, uuid, uuid, uuid, text, jsonb, text, text);

DROP FUNCTION api.add_catalog(uuid, text, uuid, uuid, uuid, uuid, text, text, text, integer);
DROP FUNCTION api.update_catalog(uuid, uuid, text, uuid, uuid, uuid, uuid, text, text, text, integer);

DROP FUNCTION api.add_element(uuid, text, uuid, uuid, text, jsonb, text, text);
DROP FUNCTION api.update_element(uuid, uuid, text, uuid, uuid, text, jsonb, text, text);

\ir '../entity/object/reference/catalog/create.psql'
\ir '../entity/object/reference/specification/create.psql'
\ir '../entity/object/document/element/create.psql'

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', 'admin');

SELECT GetErrorMessage();

SELECT CreateEntitySpecification(GetClass('reference'));

SELECT CreateProject(null, GetType('ship.project'), 'mpsv12.project', 'MPSV-12', 'Проект многофункционального аварийно-спасательного судна.');
SELECT CreateShip(null, GetType('powered.ship'), GetProject('mpsv12.project'), 'kalas.ship', 'КАЛАС', 'Многофункциональное аварийно-спасательное судно.');

SELECT CreateDemoSpecification(GetProject('mpsv12.project'));

SELECT SignOut();

\connect :dbname kernel
