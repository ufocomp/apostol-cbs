--------------------------------------------------------------------------------
-- Product ---------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW Product (Id, Document,
  Client, ClientCode, ClientName,
  Storage, StorageCode, StorageName, StorageDescription,
  Model, ModelCode, ModelName, ModelDescription,
  Measure, MeasureCode, MeasureName, MeasureDescription,
  Currency, CurrencyCode, CurrencyName, CurrencyDescription,
  Code, Rack, Cell, Price, Sort, Profile, Size, Norm, Expire, Balance
)
AS
  SELECT p.id, p.document,
         p.client, c.code, c.fullname,
         p.storage, s.code, s.name, s.description,
         p.model, m.code, m.name, m.description,
         p.measure, e.code, e.name, e.description,
         p.currency, r.code, r.name, r.description,
         p.code, p.rack, p.cell, p.price, p.sort, p.profile, p.size, p.norm, p.expire, b.amount
    FROM db.product p INNER JOIN Client             c ON c.id = p.client
                      INNER JOIN Storage            s ON s.id = p.storage
                      INNER JOIN Model              m ON m.id = p.model
                      INNER JOIN Measure            e ON e.id = p.measure
                      INNER JOIN Currency           r ON r.id = p.currency
                       LEFT JOIN db.product_balance b ON b.product = p.id AND b.validFromDate <= oper_date() AND b.validToDate > oper_date();

GRANT SELECT ON Product TO administrator;

--------------------------------------------------------------------------------
-- AccessProduct ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW AccessProduct
AS
  WITH access AS (
    SELECT * FROM AccessObjectUser(GetEntity('product'), current_userid())
  )
  SELECT p.* FROM Product p INNER JOIN access ac ON p.id = ac.object;

GRANT SELECT ON AccessProduct TO administrator;

--------------------------------------------------------------------------------
-- ObjectProduct ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ObjectProduct (Id, Object, Parent,
  Entity, EntityCode, EntityName,
  Class, ClassCode, ClassLabel,
  Type, TypeCode, TypeName, TypeDescription,
  Client, ClientCode, ClientName,
  Storage, StorageCode, StorageName, StorageDescription,
  Model, ModelCode, ModelName, ModelDescription,
  Measure, MeasureCode, MeasureName, MeasureDescription,
  Currency, CurrencyCode, CurrencyName, CurrencyDescription,
  Code, Label, Rack, Cell, Price, Sort, Profile, Size, Norm, Expire, Balance, Description,
  StateType, StateTypeCode, StateTypeName,
  State, StateCode, StateLabel, LastUpdate,
  Owner, OwnerCode, OwnerName, Created,
  Oper, OperCode, OperName, OperDate,
  Area, AreaCode, AreaName, AreaDescription,
  Scope, ScopeCode, ScopeName, ScopeDescription
)
AS
  SELECT p.id, d.object, o.parent,
         o.entity, o.entitycode, o.entityname,
         o.class, o.classcode, o.classlabel,
         o.type, o.typecode, o.typename, o.typedescription,
         p.client, p.clientcode, p.clientname,
         p.storage, p.storagecode, p.storagename, p.storagedescription,
         p.model, p.modelcode, p.modelname, p.modeldescription,
         p.measure, p.measurecode, p.measurename, p.measuredescription,
         p.currency, p.currencycode, p.currencyname, p.currencydescription,
         p.code, o.label, p.rack, p.cell, p.price, p.sort, p.profile, p.size, p.norm, p.expire, p.balance, d.description,
         o.statetype, o.statetypecode, o.statetypename,
         o.state, o.statecode, o.statelabel, o.lastupdate,
         o.owner, o.ownercode, o.ownername, o.created,
         o.oper, o.opercode, o.opername, o.operdate,
         d.area, d.areacode, d.areaname, d.areadescription,
         d.scope, d.scopecode, d.scopename, d.scopedescription
    FROM AccessProduct p INNER JOIN Document d ON d.id = p.document
                         INNER JOIN Object   o ON o.id = p.document;

GRANT SELECT ON ObjectProduct TO administrator;

--------------------------------------------------------------------------------
-- ProductTurnover -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW ProductTurnover (Product, OrderId, Document, Label,
  Client, ClientCode, ClientName,
  Measure, MeasureCode, MeasureName, MeasureDescription,
  Debit, Credit, Balance, Timestamp, Datetime
)
AS
  SELECT t.product, t.orderid, t.document, ot.label,
         t.client, c.code, c.fullname,
         t.measure, m.code, m.name, m.description,
         t.debit, t.credit, b.amount, t.timestamp, t.datetime
    FROM db.product_turnover t INNER JOIN AccessProduct      p ON p.id = t.product
                               INNER JOIN Client             c ON c.id = t.client
                               INNER JOIN Measure            m ON m.id = t.measure
                                LEFT JOIN db.product_balance b ON b.product = t.product AND b.validFromDate <= t.timestamp AND b.validToDate > t.timestamp
                                LEFT JOIN db.object_text    ot ON ot.object = t.document and ot.locale = current_locale();

GRANT SELECT ON ProductTurnover TO administrator;
