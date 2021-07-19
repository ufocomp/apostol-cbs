\ir '../entity/object/document/storage/create.psql'

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', 'admin');

SELECT GetErrorMessage();

SELECT CreateEntityStorage(GetClass('document'));

SELECT SignOut();

\connect :dbname kernel
