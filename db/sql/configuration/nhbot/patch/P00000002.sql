\ir '../entity/object/reference/catalog/create.psql'

\connect :dbname admin

SELECT SignIn(CreateSystemOAuth2(), 'admin', 'admin');

SELECT GetErrorMessage();

SELECT CreateEntityShip(GetClass('reference'));
SELECT CreateEntityCatalog(GetClass('reference'));

SELECT CreateEntityElement(GetClass('document'));

SELECT AddType(GetClass('category'), 'item.category', 'Элемент', 'Категория элементов.');
SELECT AddType(GetClass('vendor'), 'equipment.vendor', 'Оборудование', 'Производитель оборудования.');
SELECT AddType(GetClass('model'), 'equipment.model', 'Оборудование', 'Судовое оборудование.');

SELECT CreateCategory(null, GetType('item.category'), 'ship.category', 'Судовое оборудование', 'Судовое оборудование.');
SELECT CreateCategory(null, GetType('item.category'), 'engine.category', 'Двигатель (СДВС)', 'Судовые двигатели внутреннего сгорания.');
SELECT CreateCategory(null, GetType('item.category'), 'navigation.category', 'Навигационное оборудование', 'Судовое навигационное оборудование.');

SELECT CreateCatalog(null, GetType('item.catalog'), null, null, GetCategory('ship.category'), null, 'equipment.catalog', 'Судовое оборудование', 'Каталог судового оборудования.');

SELECT SignOut();

\connect :dbname kernel
