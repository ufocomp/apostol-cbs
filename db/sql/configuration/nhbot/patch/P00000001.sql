\echo [M] call P00000001.sql

--------------------------------------------------------------------------------
-- MANUAL CONTENT --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db._manual_content AS TABLE db.manual_content;

--------------------------------------------------------------------------------

DROP TABLE db.manual_content CASCADE;

--------------------------------------------------------------------------------
-- db.manual_content -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.manual_content (
    id              uuid PRIMARY KEY DEFAULT NEXTVAL('SEQUENCE_REF'),
    manual		    uuid NOT NULL,
    locale		    uuid NOT NULL,
    hash			text,
    content         text,
    rendered        text,
    raw         	text,
    form			jsonb,
    validFromDate	timestamp DEFAULT Now() NOT NULL,
    validToDate		timestamp DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL,
    CONSTRAINT fk_manual_content_manual FOREIGN KEY (manual) REFERENCES db.manual(id),
    CONSTRAINT fk_manual_content_locale FOREIGN KEY (locale) REFERENCES db.locale(id)
);

--------------------------------------------------------------------------------

COMMENT ON TABLE db.manual_content IS 'Содержимое руководства.';

COMMENT ON COLUMN db.manual_content.id IS 'Идентификатор';
COMMENT ON COLUMN db.manual_content.manual IS 'Идентификатор руководства';
COMMENT ON COLUMN db.manual_content.locale IS 'Идентификатор локали';
COMMENT ON COLUMN db.manual_content.hash IS 'Хеш.';
COMMENT ON COLUMN db.manual_content.content IS 'Содержимое.';
COMMENT ON COLUMN db.manual_content.rendered IS 'Обработанные данные.';
COMMENT ON COLUMN db.manual_content.raw IS 'Необработанные данные.';
COMMENT ON COLUMN db.manual_content.form IS 'Форма.';
COMMENT ON COLUMN db.manual_content.validFromDate IS 'Дата начала периода действия';
COMMENT ON COLUMN db.manual_content.validToDate IS 'Дата окончания периода действия';

--------------------------------------------------------------------------------

CREATE INDEX ON db.manual_content (manual);
CREATE INDEX ON db.manual_content (locale);
CREATE INDEX ON db.manual_content (hash);

CREATE UNIQUE INDEX ON db.manual_content (manual, locale, validFromDate, validToDate);

--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION ft_manual_content_before()
RETURNS trigger AS $$
BEGIN
  IF NEW.locale IS NULL THEN
    NEW.locale := current_locale();
  END IF;

  NEW.hash := encode(digest(NEW.content, 'md5'), 'hex');

  RETURN NEW;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------

CREATE TRIGGER t_manual_content_before
  BEFORE INSERT OR UPDATE ON db.manual_content
  FOR EACH ROW
  EXECUTE PROCEDURE ft_manual_content_before();

--------------------------------------------------------------------------------

INSERT INTO db.manual_content (manual, locale, hash, content, rendered, raw, form, validFromDate, validToDate)
  SELECT * FROM db._manual_content;

--------------------------------------------------------------------------------

DROP TABLE db._manual_content;

--------------------------------------------------------------------------------

DROP FUNCTION AddManualContent(numeric, text, text, text, jsonb, numeric, timestamp without time zone);

--------------------------------------------------------------------------------

SELECT AddMethod(null, class, id, GetAction('complete')) FROM State WHERE classcode = 'task' AND typecode = 'enabled' AND code <> 'enabled';
