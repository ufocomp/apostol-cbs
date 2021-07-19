--------------------------------------------------------------------------------
-- Order -----------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW kernel.Order (Id, Document, Code,
  Storage, StorageCode, StorageName, StorageDescription,
  Client, ClientCode, ClientName,
  Insurance, InsuranceCode, InsuranceName,
  Account, AccountCode, Amount
)
AS
  SELECT o.id, o.document, o.code,
         o.storage, s.code, s.name, s.description,
         o.client, c.code, c.fullname,
         o.insurance, i.code, i.fullname,
         o.account, a.code, o.amount
    FROM db.order o INNER JOIN Storage s ON s.id = o.storage
                    INNER JOIN Client  c ON c.id = o.client
                     LEFT JOIN Client  i ON i.id = o.insurance
                     LEFT JOIN Account a ON a.id = o.account;

GRANT SELECT ON kernel.Order TO administrator;

--------------------------------------------------------------------------------
-- AccessOrder -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessOrder
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('order'), current_userid())
  )
  SELECT o.* FROM kernel.Order o INNER JOIN access ac ON o.id = ac.object;

GRANT SELECT ON AccessOrder TO administrator;

--------------------------------------------------------------------------------
-- ObjectOrder -----------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectOrder (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Storage, StorageCode, StorageName, StorageDescription,
  Client, ClientCode, ClientName,
  Insurance, InsuranceCode, InsuranceName,
  Account, AccountCode, Amount,
  Code, Label, Description,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Area, AreaCode, AreaName, AreaDescription
)
AS
  SELECT o.id, d.object, o.parent,
         o.entity, o.entitycode, o.entityname,
         o.class, o.classcode, o.classlabel,
         o.type, o.typecode, o.typename, o.typedescription,
         t.storage, t.storagecode, t.storagename, t.storagedescription,
         t.client, t.clientcode, t.clientname,
         t.insurance, t.insurancecode, t.insurancename,
         t.account, t.accountcode, t.amount,
         t.code, o.label, d.description,
         o.statetype, o.statetypecode, o.statetypename,
         o.state, o.statecode, o.statelabel, o.lastupdate,
         o.owner, o.ownercode, o.ownername, o.created,
         o.oper, o.opercode, o.opername, o.operdate,
         d.area, d.areacode, d.areaname, d.areadescription
    FROM AccessOrder t INNER JOIN Document d ON t.document = d.id
                       INNER JOIN Object   o ON t.document = o.id;

GRANT SELECT ON ObjectOrder TO administrator;

--------------------------------------------------------------------------------
-- OrderItem -------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW OrderItem (Document, ItemId,
  Model, ModelCode, ModelName, ModelDescription,
  Measure, MeasureCode, MeasureName, MeasureDescription,
  Currency, CurrencyCode, CurrencyName, CurrencyDescription,
  Price, Volume, Amount, Vat
)
AS
  SELECT i.document, i.itemId,
         i.model, m.code, m.name, m.description,
         i.measure, e.code, e.name, e.description,
         i.currency, c.code, c.name, c.description,
         i.price, i.volume, i.amount, i.vat
    FROM db.order_item i INNER JOIN Model    m ON m.id = i.model
                         INNER JOIN Measure  e ON e.id = i.measure
                         INNER JOIN Currency c ON c.id = i.currency;

GRANT SELECT ON OrderItem TO administrator;

--------------------------------------------------------------------------------
-- OrderItemJson ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW OrderItemJson (DocumentId, ModelId, MeasureId, CurrencyId,
  ItemId, Model, Measure, Currency, Price, Volume, Amount, Vat
)
AS
  SELECT i.document, i.model, i.measure, i.currency, i.itemId,
         row_to_json(m), row_to_json(e), row_to_json(c),
         i.price, i.volume, i.amount, i.vat
    FROM db.order_item i INNER JOIN Model   m ON m.id = i.model
                         INNER JOIN Measure  e ON e.id = i.measure
                         INNER JOIN Currency c ON c.id = i.currency;

GRANT SELECT ON OrderItemJson TO administrator;
