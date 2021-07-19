DROP FUNCTION CreateStorage(uuid, uuid, uuid, uuid, text, text, text);
DROP FUNCTION EditStorage(uuid, uuid, uuid, uuid, uuid, text, text, text);

DROP FUNCTION api.add_storage(uuid, uuid, uuid, uuid, text, text, text);
DROP FUNCTION api.update_storage(uuid, uuid, uuid, uuid, uuid, text, text, text);

--------------------------------------------------------------------------------

CREATE TABLE db._storage AS TABLE db.storage;

DROP TABLE db.storage CASCADE;

--------------------------------------------------------------------------------
-- db.storage ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.storage (
    id              uuid PRIMARY KEY,
    document        uuid NOT NULL REFERENCES db.document(id) ON DELETE CASCADE,
    client          uuid NOT NULL REFERENCES db.client(id),
    ship            uuid REFERENCES db.ship(id),
    address         uuid REFERENCES db.address(id),
    code		    text NOT NULL
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.storage IS 'Место хранения.';

COMMENT ON COLUMN db.storage.id IS 'Идентификатор.';
COMMENT ON COLUMN db.storage.document IS 'Документ.';
COMMENT ON COLUMN db.storage.client IS 'Идентификатор сотрудника (МОЛ).';
COMMENT ON COLUMN db.storage.ship IS 'Идентификатор судна.';
COMMENT ON COLUMN db.storage.address IS 'Идентификатор адреса.';
COMMENT ON COLUMN db.storage.code IS 'Код.';

--------------------------------------------------------------------------------

CREATE UNIQUE INDEX ON db.storage (code);

CREATE INDEX ON db.storage (document);
CREATE INDEX ON db.storage (client);
CREATE INDEX ON db.storage (ship);
CREATE INDEX ON db.storage (address);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_storage_before_insert()
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

CREATE TRIGGER t_storage_before_insert
  BEFORE INSERT ON db.storage
  FOR EACH ROW
  EXECUTE PROCEDURE ft_storage_before_insert();

--------------------------------------------------------------------------------

INSERT INTO db.storage SELECT id, document, client, null, address, code FROM db._storage;

DROP TABLE db._storage;
