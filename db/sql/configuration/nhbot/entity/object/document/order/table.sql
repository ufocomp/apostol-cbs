--------------------------------------------------------------------------------
-- ORDER -----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- db.order --------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.order (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    storage         uuid NOT NULL REFERENCES db.storage(id),
    client          uuid NOT NULL REFERENCES db.client(id),
    insurance       uuid REFERENCES db.client(id),
    account         uuid REFERENCES db.account(id),
    code            text NOT NULL,
    amount          numeric(12,2) NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.order IS 'Ордер.';

COMMENT ON COLUMN db.order.id IS 'Идентификатор';
COMMENT ON COLUMN db.order.document IS 'Документ';
COMMENT ON COLUMN db.order.storage IS 'Место хранения (склад)';
COMMENT ON COLUMN db.order.client IS 'Поставщик';
COMMENT ON COLUMN db.order.insurance IS 'Страховая компания';
COMMENT ON COLUMN db.order.account IS 'Корреспондирующий счет';
COMMENT ON COLUMN db.order.code IS 'Код';
COMMENT ON COLUMN db.order.amount IS 'Сумма';

--------------------------------------------------------------------------------

CREATE INDEX ON db.order (document);
CREATE INDEX ON db.order (storage);
CREATE INDEX ON db.order (client);
CREATE INDEX ON db.order (insurance);
CREATE INDEX ON db.order (account);

CREATE UNIQUE INDEX ON db.order (code);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_order_insert()
RETURNS trigger AS $$
DECLARE
  uUserId	uuid;
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := encode(gen_random_bytes(12), 'hex');
  END IF;

  IF NEW.client IS NOT NULL THEN
    uUserId := GetClientUserId(NEW.client);
    IF uUserId IS NOT NULL THEN
      UPDATE db.aou SET allow = allow | B'100' WHERE object = NEW.document AND userid = uUserId;
      IF NOT FOUND THEN
        INSERT INTO db.aou SELECT NEW.document, uUserId, B'000', B'100';
      END IF;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_order_insert
  BEFORE INSERT ON db.order
  FOR EACH ROW
  EXECUTE PROCEDURE ft_order_insert();

--------------------------------------------------------------------------------
-- db.order_item ---------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.order_item (
    document        uuid NOT NULL REFERENCES db.order(id) ON DELETE CASCADE,
    itemId          integer NOT NULL,
    model           uuid NOT NULL REFERENCES db.model(id),
    measure         uuid NOT NULL REFERENCES db.measure(id),
    currency        uuid NOT NULL REFERENCES db.currency(id),
    price           numeric(12,2) NOT NULL,
    volume          numeric NOT NULL,
    amount          numeric(12,2) GENERATED ALWAYS AS (price * volume) STORED,
    vat             numeric,
    PRIMARY KEY (document, itemId)
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.order_item IS 'Номенклатура ордера.';

COMMENT ON COLUMN db.order_item.document IS 'Ссылка на документ (ордер)';
COMMENT ON COLUMN db.order_item.itemId IS 'Номер по порядку (номенклатурный номер)';
COMMENT ON COLUMN db.order_item.model IS 'Модель';
COMMENT ON COLUMN db.order_item.measure IS 'Мера';
COMMENT ON COLUMN db.order_item.currency IS 'Валюта.';
COMMENT ON COLUMN db.order_item.price IS 'Цена';
COMMENT ON COLUMN db.order_item.volume IS 'Объём';
COMMENT ON COLUMN db.order_item.amount IS 'Сумма';
COMMENT ON COLUMN db.order_item.vat IS 'Ставка НДС';

--------------------------------------------------------------------------------

CREATE INDEX ON db.order_item (document);
CREATE INDEX ON db.order_item (model);
CREATE INDEX ON db.order_item (measure);
CREATE INDEX ON db.order_item (currency);
