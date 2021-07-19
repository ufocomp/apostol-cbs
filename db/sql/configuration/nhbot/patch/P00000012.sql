DROP FUNCTION IF EXISTS api.add_manual(uuid, text, uuid, text, text, text, text, text, text, jsonb, text);
DROP FUNCTION IF EXISTS api.add_manual(uuid, text, uuid, uuid, text, text, text, text, jsonb, text, text, text);
DROP FUNCTION IF EXISTS api.add_manual(uuid, text, uuid, uuid, uuid, uuid, text, text, text, text, jsonb, text, text, text);

DROP FUNCTION IF EXISTS api.update_manual(uuid, uuid, text, uuid, text, text, text, text, text, text, jsonb, text);
DROP FUNCTION IF EXISTS api.update_manual(uuid, uuid, text, uuid, uuid, text, text, text, text, jsonb, text, text, text);
DROP FUNCTION IF EXISTS api.update_manual(uuid, uuid, text, uuid, uuid, uuid, uuid, text, text, text, text, jsonb, text, text, text);

DROP FUNCTION IF EXISTS api.set_manual(uuid, uuid, text, uuid, text, text, text, text, text, text, jsonb, text);
DROP FUNCTION IF EXISTS api.set_manual(uuid, uuid, text, uuid, uuid, text, text, text, text, jsonb, text, text, text);
DROP FUNCTION IF EXISTS api.set_manual(uuid, uuid, text, uuid, uuid, uuid, uuid, text, text, text, text, jsonb, text, text, text);

DROP FUNCTION IF EXISTS CreateManual(uuid, uuid, uuid, text, text, text, text, text, text, jsonb, text);
DROP FUNCTION IF EXISTS CreateManual(uuid, uuid, uuid, uuid, text, text, text, text, jsonb, text, text, text);
DROP FUNCTION IF EXISTS CreateManual(uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, jsonb, text, text, text);

DROP FUNCTION IF EXISTS EditManual(uuid, uuid, uuid, uuid, text, text, text, text, text, text, jsonb, text);
DROP FUNCTION IF EXISTS EditManual(uuid, uuid, uuid, uuid, uuid, text, text, text, text, jsonb, text, text, text);
DROP FUNCTION IF EXISTS EditManual(uuid, uuid, uuid, uuid, uuid, uuid, uuid, text, text, text, text, jsonb, text, text, text);

DROP FUNCTION IF EXISTS DeleteManualMember(uuid, uuid);
DROP FUNCTION IF EXISTS CreateManualMemberTask(uuid);
DROP FUNCTION IF EXISTS GetManualMemberRole(uuid, uuid);
DROP FUNCTION IF EXISTS GetManualMembersJson(uuid);
DROP FUNCTION IF EXISTS GetManualMembersJsonb(uuid);
DROP FUNCTION IF EXISTS SetManualMember(uuid, uuid, bit, interval, timestamp, timestamp);

--------------------------------------------------------------------------------

CREATE TABLE db._manual_content AS
  TABLE db.manual_content;

CREATE TABLE db._manual AS
  TABLE db.manual;

DROP TABLE db.manual_content CASCADE;
DROP TABLE db.manual CASCADE;

--------------------------------------------------------------------------------
\ir '../entity/object/document/manual/create.psql'
--------------------------------------------------------------------------------

INSERT INTO db.manual SELECT * FROM db._manual;
INSERT INTO db.manual_content SELECT * FROM db._manual_content;

DROP TABLE db._manual_content;
DROP TABLE db._manual;
