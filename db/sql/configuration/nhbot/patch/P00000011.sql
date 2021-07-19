\ir '../entity/object/reference/activity/create.psql'
\ir '../matching/create.psql'
\ir '../participant/create.psql'

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', :'admin');

SELECT GetErrorMessage();

SELECT CreateEntityActivity(GetClass('reference'));

SELECT SignOut();

\connect :dbname kernel
