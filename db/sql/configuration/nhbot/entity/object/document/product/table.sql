--------------------------------------------------------------------------------
-- db.product ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.product (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    client          uuid NOT NULL REFERENCES db.client(id) ON DELETE RESTRICT,
    storage         uuid NOT NULL REFERENCES db.storage(id),
    model           uuid NOT NULL REFERENCES db.model(id),
    measure         uuid NOT NULL REFERENCES db.measure(id),
    currency        uuid NOT NULL REFERENCES db.currency(id),
    code            text NOT NULL,
    price           numeric(12,2) NOT NULL,
    rack            text,
    cell            text,
    sort            text,
    profile         text,
    size            text,
    norm            numeric,
    expire          timestamptz
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.product IS 'Продукт. Товарно-материальная ценность (ТМЦ).';

COMMENT ON COLUMN db.product.id IS 'Идентификатор.';
COMMENT ON COLUMN db.product.document IS 'Документ.';
COMMENT ON COLUMN db.product.client IS 'Идентификатор сотрудника (МОЛ).';
COMMENT ON COLUMN db.product.storage IS 'Идентификатор места хранения.';
COMMENT ON COLUMN db.product.model IS 'Идентификатор модели.';
COMMENT ON COLUMN db.product.measure IS 'Идентификатор меры.';
COMMENT ON COLUMN db.product.currency IS 'Идентификатор валюты.';
COMMENT ON COLUMN db.product.code IS 'Номенклатурный номер.';
COMMENT ON COLUMN db.product.price IS 'Цена.';
COMMENT ON COLUMN db.product.rack IS 'Стеллаж.';
COMMENT ON COLUMN db.product.cell IS 'Ячейка.';
COMMENT ON COLUMN db.product.sort IS 'Сорт.';
COMMENT ON COLUMN db.product.profile IS 'Профиль.';
COMMENT ON COLUMN db.product.size IS 'Размер.';
COMMENT ON COLUMN db.product.norm IS 'Норма запаса.';
COMMENT ON COLUMN db.product.expire IS 'Срок годности.';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.product (code);

CREATE INDEX ON db.product (document);
CREATE INDEX ON db.product (client);
CREATE INDEX ON db.product (storage);
CREATE INDEX ON db.product (model);
CREATE INDEX ON db.product (measure);
CREATE INDEX ON db.product (currency);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_product_before_insert()
RETURNS trigger AS $$
DECLARE
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.code, '') IS NULL THEN
    NEW.code := encode(gen_random_bytes(12), 'hex');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_product_before_insert
  BEFORE INSERT ON db.product
  FOR EACH ROW
  EXECUTE PROCEDURE ft_product_before_insert();

--------------------------------------------------------------------------------
-- product_balance -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.product_balance (
    id              uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    product         uuid NOT NULL REFERENCES db.product(id) ON DELETE RESTRICT,
    amount          numeric NOT NULL,
    validFromDate   timestamptz DEFAULT Now() NOT NULL,
    validToDate     timestamptz DEFAULT MAXDATE() NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.product_balance IS 'Баланс. Остаток ТМЦ на складе.';

COMMENT ON COLUMN db.product_balance.id IS 'Идентификатор';
COMMENT ON COLUMN db.product_balance.product IS 'Продукт (ТМЦ)';
COMMENT ON COLUMN db.product_balance.amount IS 'Сумма';
COMMENT ON COLUMN db.product_balance.validFromDate IS 'Дата начала периода действия';
COMMENT ON COLUMN db.product_balance.validToDate IS 'Дата окончания периода действия';

--------------------------------------------------------------------------------

CREATE INDEX ON db.product_balance (product);

CREATE UNIQUE INDEX ON db.product_balance (product, validFromDate, validToDate);

--------------------------------------------------------------------------------
-- product_turnover ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.product_turnover (
    product         uuid NOT NULL REFERENCES db.product(id) ON DELETE RESTRICT,
    orderId         integer NOT NULL,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE RESTRICT,
    client          uuid NOT NULL REFERENCES db.client(id) ON DELETE RESTRICT,
    measure         uuid NOT NULL REFERENCES db.measure(id) ON DELETE RESTRICT,
    debit           numeric NOT NULL,
    credit          numeric NOT NULL,
    timestamp       timestamptz NOT NULL,
    datetime        timestamptz NOT NULL DEFAULT Now(),
    PRIMARY KEY (product, orderId)
);

COMMENT ON TABLE db.product_turnover IS 'Оборотная ведомость продукта (ТМЦ).';

COMMENT ON COLUMN db.product_turnover.product IS 'Продукт (ТМЦ)';
COMMENT ON COLUMN db.product_turnover.orderId IS 'Номер по порядку (номенклатурный номер)';
COMMENT ON COLUMN db.product_turnover.document IS 'Документ';
COMMENT ON COLUMN db.product_turnover.client IS 'От кого получено или кому отпущено';
COMMENT ON COLUMN db.product_turnover.measure IS 'Идентификатор меры.';
COMMENT ON COLUMN db.product_turnover.debit IS 'Сумма обота по дебету';
COMMENT ON COLUMN db.product_turnover.credit IS 'Сумма обота по кредиту';
COMMENT ON COLUMN db.product_turnover.timestamp IS 'Логическое время оборота';
COMMENT ON COLUMN db.product_turnover.datetime IS 'Физическое время оборота';

CREATE INDEX ON db.product_turnover (product);
CREATE INDEX ON db.product_turnover (document);
CREATE INDEX ON db.product_turnover (client);
CREATE INDEX ON db.product_turnover (measure);
