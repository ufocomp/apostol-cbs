--------------------------------------------------------------------------------
-- DOCUMENT --------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EventDocumentCreate ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventDocumentCreate (
  pObject	uuid DEFAULT context_object()
) RETURNS	void
AS $$
DECLARE
  r         	record;
  uParent   	uuid;
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'create', 'Документ создан.', pObject);

  SELECT parent INTO uParent FROM db.object WHERE id = pObject;

  IF uParent IS NOT NULL THEN
    SELECT * INTO r FROM Object WHERE id = uParent;
    PERFORM SetObjectDataJSON(pObject, 'parent', row_to_json(r));
  END IF;

  PERFORM UpdateMembers(pObject);
END;
$$ LANGUAGE plpgsql;

--------------------------------------------------------------------------------
-- EventDocumentEnable ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION EventDocumentEnable (
  pObject	uuid default context_object()
) RETURNS	void
AS $$
BEGIN
  PERFORM WriteToEventLog('M', 1000, 'enable', 'Документ включен.', pObject);

  UPDATE db.participant
     SET sign = null,
         completed = null
   WHERE document = pObject;

  PERFORM CreateParticipantTask(pObject);
END;
$$ LANGUAGE plpgsql;
