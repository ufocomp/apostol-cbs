\ir '../entity/object/document/fda/create.psql'

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', :'admin');

SELECT GetErrorMessage();

SELECT CreateEntityFDA(GetClass('document'));

SELECT SignOut();

\connect :dbname kernel
