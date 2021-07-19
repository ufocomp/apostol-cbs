\ir '../entity/object/document/request/create.psql'

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', :'admin');

SELECT GetErrorMessage();

SELECT CreateEntityRequest(GetClass('document'));

SELECT SignOut();

\connect :dbname kernel

