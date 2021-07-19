\ir '../entity/object/document/undertake/create.psql'

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', :'admin');

SELECT GetErrorMessage();

SELECT CreateEntityUndertake(GetClass('document'));

SELECT SignOut();

\connect :dbname kernel
