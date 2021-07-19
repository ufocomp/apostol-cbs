--------------------------------------------------------------------------------
-- STREAM ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- VIEW streamLog --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE VIEW streamLog (Id, DateTime, UserName, Protocol,
  Address, Request, RequestLength, Response, ResponseLength, RunTime, Message)
AS
  SELECT id, datetime, username, protocol, address,
         encode(request, 'hex'), octet_length(request),
         encode(response, 'hex'), octet_length(response),
         round(extract(second from runtime)::numeric, 3),
         message
    FROM stream.log;
