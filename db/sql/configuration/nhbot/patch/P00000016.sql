DROP FUNCTION api.add_element(uuid, uuid, uuid, uuid, uuid, text, boolean, jsonb, text, text);
DROP FUNCTION api.update_element(uuid, uuid, uuid, uuid, uuid, uuid, text, boolean, jsonb, text, text);
DROP FUNCTION api.set_element(uuid, uuid, uuid, uuid, uuid, uuid, text, boolean, jsonb, text, text);

DROP FUNCTION CreateElement(uuid, uuid, uuid, uuid, uuid, text, boolean, jsonb, text, text);
DROP FUNCTION EditElement(uuid, uuid, uuid, uuid, uuid, uuid, text, boolean, jsonb, text, text);

--------------------------------------------------------------------------------

CREATE TABLE db._element AS TABLE db.element;

--------------------------------------------------------------------------------

DROP TABLE db.element CASCADE;

--------------------------------------------------------------------------------
-- db.element ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.element (
    id				uuid PRIMARY KEY,
    document		uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    specification	uuid NOT NULL REFERENCES db.specification(id),
    project			uuid NOT NULL REFERENCES db.project(id),
    ship			uuid NOT NULL REFERENCES db.ship(id),
    model			uuid NOT NULL REFERENCES db.model(id),
    identity		text NOT NULL,
    critical		boolean NOT NULL DEFAULT false,
    operating       boolean NOT NULL DEFAULT false,
    info			jsonb
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.element IS 'Элемент.';

COMMENT ON COLUMN db.element.id IS 'Идентификатор.';
COMMENT ON COLUMN db.element.document IS 'Документ.';
COMMENT ON COLUMN db.element.specification IS 'Идентификатор спецификации.';
COMMENT ON COLUMN db.element.project IS 'Идентификатор проекта.';
COMMENT ON COLUMN db.element.ship IS 'Идентификатор судна.';
COMMENT ON COLUMN db.element.model IS 'Идентификатор модели.';
COMMENT ON COLUMN db.element.identity IS 'Идентификационный номер.';
COMMENT ON COLUMN db.element.critical IS 'Критическое оборудование.';
COMMENT ON COLUMN db.element.operating IS 'Учитывать наработку.';
COMMENT ON COLUMN db.element.info IS 'Дополнительная информация.';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.element (project, identity);

CREATE INDEX ON db.element (document);
CREATE INDEX ON db.element (specification);
CREATE INDEX ON db.element (project);
CREATE INDEX ON db.element (ship);
CREATE INDEX ON db.element (model);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_element_before_insert()
RETURNS trigger AS $$
DECLARE
BEGIN
  IF NEW.id IS NULL THEN
    SELECT NEW.document INTO NEW.id;
  END IF;

  IF NULLIF(NEW.identity, '') IS NULL THEN
    NEW.identity := encode(gen_random_bytes(12), 'hex');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_element_before_insert
  BEFORE INSERT ON db.element
  FOR EACH ROW
  EXECUTE PROCEDURE ft_element_before_insert();

--------------------------------------------------------------------------------

INSERT INTO db.element SELECT id, document, specification, project, ship, model, identity, critical, false, info FROM db._element;

--------------------------------------------------------------------------------

DROP TABLE db._element;
