\ir '../entity/object/document/demand/create.psql'

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', 'admin');

SELECT GetErrorMessage();

SELECT CreateEntityDemand(GetClass('document'));

SELECT SignOut();

\connect :dbname kernel
