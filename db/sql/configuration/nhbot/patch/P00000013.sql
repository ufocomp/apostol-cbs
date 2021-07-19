\ir '../entity/object/document/maintenance/create.psql'

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', :'admin');

SELECT GetErrorMessage();

SELECT CreateEntityMaintenance(GetClass('document'));

SELECT SignOut();

\connect :dbname kernel
