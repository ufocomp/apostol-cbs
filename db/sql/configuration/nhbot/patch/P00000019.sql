\ir '../entity/object/reference/structure/init.psql'

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', :'admin');

SELECT GetErrorMessage();

SELECT SetSessionArea(GetArea(current_database()));

SELECT AddType(GetClass('structure'), 'repair.structure', 'Виды работ', 'Виды работ для технического обслуживания.');
SELECT CreateStructureRepair(null, GetType('repair.structure'), 'repair.structure', 'Виды работ', 'Виды работ для технического обслуживания.');

SELECT SignOut();

SELECT SignIn(CreateOAuth2(GetAudience(oauth2_system_client_id()), 'https://mrs.ship-safety.ru'), 'admin', :'admin');
SELECT CreateStructureRepair(null, GetType('repair.structure'), 'repair.structure', 'Виды работ', 'Виды работ для технического обслуживания.');
SELECT SignOut();

SELECT SignIn(CreateOAuth2(GetAudience(oauth2_system_client_id()), 'https://vss.ship-safety.ru'), 'admin', :'admin');
SELECT CreateStructureRepair(null, GetType('repair.structure'), 'repair.structure', 'Виды работ', 'Виды работ для технического обслуживания.');
SELECT SignOut();

\connect :dbname kernel
