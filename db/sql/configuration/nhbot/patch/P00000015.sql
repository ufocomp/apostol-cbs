DROP FUNCTION StructureTree(uuid);
DROP VIEW Structure CASCADE;

DROP FUNCTION SetOperatingTime(uuid, integer, timestamptz);
--------------------------------------------------------------------------------

CREATE TABLE db._operating_time AS TABLE db.operating_time;

--------------------------------------------------------------------------------

DROP TABLE db.operating_time CASCADE;

--------------------------------------------------------------------------------
-- db.operating_time -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE db.operating_time (
    element         uuid NOT NULL REFERENCES db.element(id) ON DELETE CASCADE,
    type            integer NOT NULL DEFAULT 0 CHECK (type BETWEEN 0 AND 6),
    value		    int NOT NULL,
    fixedDate       timestamptz DEFAULT Now() NOT NULL,
    validFromDate	timestamptz DEFAULT Now() NOT NULL,
    validToDate		timestamptz DEFAULT TO_DATE('4433-12-31', 'YYYY-MM-DD') NOT NULL,
    PRIMARY KEY (element, type, validFromDate, validToDate)
);

COMMENT ON TABLE db.operating_time IS 'Наработка в часах.';

COMMENT ON COLUMN db.operating_time.element IS 'Элемент';
COMMENT ON COLUMN db.operating_time.type IS 'Тип: 0 - от сброса (текущая); 1 - за год; 2 - за месяц; 3 - за день; 4 - на начало года; 5 - на начало месяца; 6 - на начало суток';
COMMENT ON COLUMN db.operating_time.value IS 'Значение';
COMMENT ON COLUMN db.operating_time.fixedDate IS 'Дата фиксации';
COMMENT ON COLUMN db.operating_time.validFromDate IS 'Дата начала периода действия';
COMMENT ON COLUMN db.operating_time.validToDate IS 'Дата окончания периода действия';

CREATE INDEX ON db.operating_time (element);
CREATE INDEX ON db.operating_time (type);

INSERT INTO db.operating_time SELECT element, 0, value, validFromDate, validFromDate, validToDate FROM db._operating_time;

--------------------------------------------------------------------------------

DROP TABLE db._operating_time;
