\ir '../entity/object/document/repair/create.psql'

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', :'admin');

SELECT GetErrorMessage();

SELECT CreateEntityRepair(GetClass('document'));

SELECT SignOut();

\connect :dbname kernel
