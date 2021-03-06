--------------------------------------------------------------------------------
-- STREAM ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- stream.WriteToLog -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.WriteToLog (
  pProtocol		text,
  pAddress		text,
  pRequest		bytea default null,
  pResponse		bytea default null,
  pRunTime		interval default null,
  pMessage		text default null
) RETURNS		bigint
AS $$
DECLARE
  nId			bigint;
BEGIN
  INSERT INTO stream.log (protocol, address, request, response, runtime, message)
  VALUES (pProtocol, pAddress, pRequest, pResponse, pRunTime, pMessage)
  RETURNING id INTO nId;

  RETURN nId;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.ClearLog -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.ClearLog (
  pDateTime		timestamptz
) RETURNS		void
AS $$
BEGIN
  DELETE FROM stream.log WHERE datetime < pDateTime;
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.GetCRC16 -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.GetCRC16 (
  buffer        bytea,
  size          int
) RETURNS       int
AS $$
DECLARE
  crc           int;
BEGIN
  crc := 65535;
  for i in 0..size - 1
  loop
    crc := crc # get_byte(buffer, i);
    for j in 0..7
    loop
      if (crc & 1) = 1 then
        crc := (crc >> 1) # 40961; -- 0xA001
      else
        crc := crc >> 1;
      end if;
    end loop;
  end loop;
  return crc; --(crc & 255) << 8 | (crc >> 8);
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.GetUInt --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.GetUInt (
  pData         bytea,
  pLength		integer DEFAULT 64
) RETURNS       bigint
AS
$$
DECLARE
  B				bit varying;
BEGIN
  pLength := coalesce(pLength, octet_length(pData)) / 8;

  FOR i IN 0 .. pLength - 1
  LOOP
    IF B IS NULL THEN
      B := get_byte(pData, i)::bit(8);
	ELSE
      B := get_byte(pData, i)::bit(8) || B;
	END IF;
  END LOOP;

  CASE pLength
  WHEN 8 THEN
    RETURN CAST(B AS bit(64))::bigint;
  WHEN 6 THEN
    RETURN CAST(B AS bit(48))::bigint;
  WHEN 4 THEN
    RETURN CAST(B AS bit(32))::bigint;
  WHEN 3 THEN
    RETURN CAST(B AS bit(24))::bigint;
  WHEN 2 THEN
    RETURN CAST(B AS bit(16))::bigint;
  ELSE
    RETURN CAST(B AS bit(8))::bigint;
  END CASE;
END
$$ LANGUAGE plpgsql IMMUTABLE;

--------------------------------------------------------------------------------
-- stream.GetUInt64 ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.GetUInt64 (
  pData         bytea
) RETURNS       bigint
AS $$
BEGIN
  RETURN stream.GetUInt(pData, 64);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.GetUInt48 ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.GetUInt48 (
  pData         bytea
) RETURNS       bigint
AS $$
BEGIN
  RETURN stream.GetUInt(pData, 48);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.GetUInt32 ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.GetUInt32 (
  pData         bytea
) RETURNS       bigint
AS $$
BEGIN
  RETURN stream.GetUInt(pData, 32);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.GetUInt24 ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.GetUInt24 (
  pData         bytea
) RETURNS       bigint
AS $$
BEGIN
  RETURN stream.GetUInt(pData, 24);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.GetUInt16 ------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.GetUInt16 (
  pData         bytea
) RETURNS       bigint
AS $$
BEGIN
  RETURN stream.GetUInt(pData, 16);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.GetUInt8 -------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.GetUInt8 (
  pData         bytea
) RETURNS       bigint
AS $$
BEGIN
  RETURN get_byte(pData, 0);
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.GetDataTypeInfo ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.GetDataTypeInfo (
  pType         text
) RETURNS       jsonb
AS $$
BEGIN
  CASE pType
  WHEN 'percent' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '??????????????');
  WHEN 'second' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '??????????????');
  WHEN 'byte' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '????????');
  WHEN 'meter' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '????????');
  WHEN 'freq' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '??????????????, ????????');
  WHEN 'temper' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '??????????????????????, ???????????? ??????????????');
  WHEN 'degree' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '????????????');
  WHEN 'decimal_degree' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '???????????????????? ????????????');
  WHEN 'meter_second' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '???????? ?? ??????????????');
  WHEN 'time' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '?????????????????? ??????????');
  WHEN 'time_utc' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '?????????????????? ???????????????????????????????? ?????????? (UTC)');
  WHEN 'time_day' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '?????????? ?? ???????????????? ?? ???????????? ??????????');
  WHEN 'utf8' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', '???????????? ?? ?????????????????? UTF-8');
  END CASE;

  RETURN jsonb_build_object();
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.GetCurrentValue ------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.GetCurrentValue (
  pValue        stream.t_cmd_current_value
) RETURNS       jsonb
AS $$
BEGIN
  CASE pValue.type
  WHEN 0 THEN
    RETURN jsonb_build_object('value', round(stream.GetUInt16(pValue.data) / 100, 2), 'value_type', pValue.type, 'value_name', '?????????? ??????????????') || stream.GetDataTypeInfo('percent');
  WHEN 1 THEN
    RETURN jsonb_build_object('value', IEEE754_64(stream.GetUInt64(pValue.data)), 'value_type', pValue.type, 'value_name', '????????????') || stream.GetDataTypeInfo('decimal_degree');
  WHEN 2 THEN
    RETURN jsonb_build_object('value', IEEE754_64(stream.GetUInt64(pValue.data)), 'value_type', pValue.type, 'value_name', '??????????????') || stream.GetDataTypeInfo('decimal_degree');
  WHEN 3 THEN
    RETURN jsonb_build_object('value', stream.GetUInt16(pValue.data), 'value_type', pValue.type, 'value_name', '???????????? ?????? ?????????????? ????????') || stream.GetDataTypeInfo('meter');
  WHEN 4 THEN
    RETURN jsonb_build_object('value', stream.GetUInt16(pValue.data), 'value_type', pValue.type, 'value_name', '???????????????? ?????????????? latitude ?? longitude') || stream.GetDataTypeInfo('meter');
  WHEN 5 THEN
    RETURN jsonb_build_object('value', stream.GetUInt16(pValue.data), 'value_type', pValue.type, 'value_name', '???????????????? ???????????????? altitude') || stream.GetDataTypeInfo('meter');
  WHEN 6 THEN
    RETURN jsonb_build_object('value', stream.GetUInt16(pValue.data), 'value_type', pValue.type, 'value_name', '?? ?????????? ?????????????????????? ???????????????? ????????????????????') || stream.GetDataTypeInfo('degree');
  WHEN 7 THEN
    RETURN jsonb_build_object('value', stream.GetUInt16(pValue.data), 'value_type', pValue.type, 'value_name', '???????????????? ???????????????? ????????????????????') || stream.GetDataTypeInfo('meter_second');
  ELSE
    RETURN jsonb_build_object();
  END CASE;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.ParsePackage ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.ParsePackage (
  pData         bytea
) RETURNS       stream.t_package
AS $$
DECLARE
  Pos           int;
  Size          int;
  crc16         int;
  CRC           bytea;
  Result        stream.t_package;
BEGIN
  Pos := 0;
  Size := octet_length(pData);
  CRC := substr(pData, Size - 1);

  crc16 := stream.GetCRC16(pData, Size - 2);
  Result.crc16 := get_byte(CRC, 1) << 8 | get_byte(CRC, 0);

  IF (crc16 <> Result.crc16) THEN
    RAISE EXCEPTION 'ERR-40000: Invalid CRC';
  END IF;

  Result.length := get_byte(pData, Pos);
  Pos := Pos + 1;

  -- length ??? ?????????? ???????????? (1 ?????? 2 ??????????).
  -- 1 ????????: 0-6 ?????? ??? ?????????????? ???????? ??????????, 7 ?????? ??? ?????????? ???????????? 2 ??????????).
  -- 2 ????????: ???????????????????????? ???????? ???????????????????? 7 ?????? ?????????????? ??????????, 0-7 ?????? ??? ?????????????? ???????? ??????????.
  IF Result.length & 128 = 128 THEN
    Result.length = set_bit(Result.length::bit(8), 0, 0)::int;
    Result.length = get_byte(pData, Pos) << 8 | Result.length;
    Pos := Pos + 1;
  END IF;

  Result.version := get_byte(pData, Pos);
  Pos := Pos + 1;

  Result.params := get_byte(pData, Pos)::bit(8);
  Pos := Pos + 1;

  Result.type := get_byte(pData, Pos);
  Pos := Pos + 1;

  Result.serial_size := get_byte(pData, Pos);
  Pos := Pos + 1;

  Result.serial := encode(substr(pData, Pos + 1, Result.serial_size), 'escape');
  Pos := Pos + Result.serial_size;

  Result.command := get_byte(pData, Pos);
  Pos := Pos + 1;

  Result.package := get_byte(pData, Pos);
  Pos := Pos + 1;

  Result.data := substr(pData, Pos + 1, Size - Pos - 2);

  RETURN Result;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.ParseCommandData -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.ParseCommandData (
  pId           uuid,
  pCommand      int2,
  pPackage      int2
) RETURNS       void
AS $$
DECLARE
  pak           stream.package%rowtype;
  cmd           stream.command%rowtype;

  uClient       uuid;
  uDevice       uuid;
  uModel        uuid;
  uMethod		uuid;

  vIdentity     text;

  nLatitude		numeric;
  nLongitude	numeric;
  nAccuracy		numeric;
  nBattery		numeric;

  data			jsonb;
  value			jsonb;

  cmd04         stream.t_cmd_current_value;

  pos           int DEFAULT 0;
  count         int2;
BEGIN
  SELECT * INTO cmd
    FROM stream.command
   WHERE packageId = pId
     AND command = pCommand
     AND package = pPackage;

  IF not FOUND THEN
    RETURN;
  END IF;

  IF cmd.error <> 0 THEN
    RETURN;
  END IF;

  SELECT * INTO pak
    FROM stream.package
   WHERE id = cmd.packageId;

  CASE pak.type
  WHEN 161 THEN -- 0xA1
	uModel := GetModel('android.model');
	vIdentity := 'ANDROID-' || pak.serial;
  WHEN 162 THEN -- 0xA2
	uModel := GetModel('ios.model');
	vIdentity := 'IOS-' || pak.serial;
  ELSE
	uModel := GetModel('unknown.model');
	vIdentity := 'UNKNOWN-' || pak.serial;
  END CASE;

  SELECT id INTO uDevice FROM db.device WHERE serial = pak.serial;

  IF NOT FOUND THEN
    uDevice := CreateDevice(null, GetType('mobile.device'), uModel, null, vIdentity, null, pak.serial);
  END IF;

  PERFORM AddDeviceNotification(uDevice, 0, cmd.type::text, cmd.error::text, encode(cmd.data, 'hex'), pak.type::text, cmd.date);

  -- ?????????????? 0x03. ????????????
  IF cmd.type = 3 THEN
    RETURN;
  END IF;

  -- ?????????????? 0x04. ?????????????? ????????????????
  IF cmd.type = 4 THEN
    -- ???????????????????? ????????????????
    count := get_byte(cmd.data, 0);
    pos := pos + 1;
    -- ?????? ?????????????? ????????????????:
    FOR i IN 0..count - 1
    LOOP
      -- ?????? ????????????????
      cmd04.type := get_byte(cmd.data, pos);
      pos := pos + 1;
      -- ???????????? ????????????????
      cmd04.size := get_byte(cmd.data, pos);
      pos := pos + 1;
      -- ?????????????? ????????????????
      cmd04.data := substr(cmd.data, pos + 1, cmd04.size);
      pos := pos + cmd04.size;

      value := stream.GetCurrentValue(cmd04);
      PERFORM AddDeviceValue(uDevice, cmd04.type, value, cmd.date);

      IF cmd04.type = 0 THEN
        nBattery := to_number(value->>'value', '990.99');
      ELSIF cmd04.type = 1 THEN
        nLatitude := to_number(value->>'value', '990.9999999999999');
	  ELSIF cmd04.type = 2 THEN
        nLongitude := to_number(value->>'value', '990.9999999999999');
	  ELSIF cmd04.type = 3 THEN
        nAccuracy := to_number(value->>'value', '999999990');
	  END IF;
    END LOOP;

    IF nLatitude IS NOT NULL AND nLongitude IS NOT NULL THEN
      data := jsonb_build_object('device', jsonb_build_object('id', uDevice, 'identity', vIdentity, 'serial', pak.serial, 'battery', nBattery));
      PERFORM NewObjectCoordinates(uDevice, 'default', nLatitude, nLongitude, coalesce(nAccuracy, 0), vIdentity, null, data);
      PERFORM SetObjectDataJSON(uDevice, 'geo', GetObjectCoordinatesJson(uDevice, 'default'));

      SELECT client INTO uClient FROM db.device WHERE id = uDevice;
      IF uClient IS NOT NULL THEN
        PERFORM NewObjectCoordinates(uClient, 'default', nLatitude, nLongitude, coalesce(nAccuracy, 0), vIdentity, null, data);
        PERFORM SetObjectDataJSON(uClient, 'geo', GetObjectCoordinatesJson(uClient, 'default'));
        uMethod := GetObjectMethod(uClient, GetAction('submit'));
        IF uMethod IS NOT NULL THEN
          PERFORM ExecuteMethod(uClient, uMethod);
        END IF;
      END IF;
    END IF;

    RETURN;
  END IF;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.ParseCommand ---------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.ParseCommand (
  pData         bytea
) RETURNS       stream.t_command
AS $$
DECLARE
  Pos           int;
  Size          int;
  temp          double precision;
  Result        stream.t_command;
BEGIN
  Pos := 0;
  Size := octet_length(pData);

  temp := stream.GetUInt32(pData);
  Pos := Pos + 4;

  -- ?????????????? ?????????? ????????????????. 0 ??? ???????????????????????????? ??????????, 1 ??? ???????????? ??????????????
  IF temp > 1 THEN
    Result.date := to_timestamp(temp);
  END IF;

  Result.type := get_byte(pData, Pos);
  Pos := Pos + 1;

  Result.error := get_byte(pData, Pos);
  Pos := Pos + 1;

  -- ???????? ???????? ????????????, ???? ???????? "????????????" ??????????????????????
  IF Result.error = 0 THEN
    Result.data := substr(pData, Pos + 1, Size - Pos);
  END IF;

  RETURN Result;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.ParseLPWAN -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION stream.ParseLPWAN (
  pData         bytea
) RETURNS       bytea
AS $$
DECLARE
  nId           uuid;
  nCommand      int2;
  nPackage      int2;
  bData			bytea;
BEGIN
  INSERT INTO stream.package SELECT gen_kernel_uuid('8'), Now(), p.* FROM stream.ParsePackage(pData) AS p
  RETURNING id, command, package, data INTO nId, nCommand, nPackage, bData;

  INSERT INTO stream.command SELECT nId, nCommand, nPackage, c.* FROM stream.ParseCommand(bData) AS c;

  PERFORM stream.ParseCommandData(nId, nCommand, nPackage);

  RETURN null;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- stream.Parse ----------------------------------------------------------------
--------------------------------------------------------------------------------
/**
 * ???????????? ????????????.
 * @param {text} pProtocol - ???????????????? (???????????? ????????????)
 * @param {text} pAddress - ?????????????? ?????????? (host:port)
 * @param {text} pBase64 - ???????????? ?? ?????????????? BASE64
 * @return {text} - ?????????? ?? ?????????????? BASE64
 */
CREATE OR REPLACE FUNCTION stream.Parse (
  pProtocol     text,
  pAddress		text,
  pBase64       text
) RETURNS       text
AS $$
DECLARE
  tsBegin       timestamp;

  vMessage      text;
  vContext      text;

  bRequest      bytea;
  bResponse     bytea;
BEGIN
  tsBegin := clock_timestamp();

  bRequest = decode(pBase64, 'base64');

  CASE pProtocol
  WHEN 'LPWAN' THEN

    bResponse := stream.ParseLPWAN(bRequest);

  ELSE
    PERFORM UnknownProtocol(pProtocol);
  END CASE;

  PERFORM stream.WriteTolog(pProtocol, coalesce(pAddress, 'null'), bRequest, bResponse, age(clock_timestamp(), tsBegin));

  RETURN encode(bResponse, 'base64');
EXCEPTION
WHEN others THEN
  GET STACKED DIAGNOSTICS vMessage = MESSAGE_TEXT, vContext = PG_EXCEPTION_CONTEXT;

  PERFORM SetErrorMessage(vMessage);

  bRequest = decode(pBase64, 'base64');

  PERFORM stream.WriteTolog(pProtocol, coalesce(pAddress, 'null'), bRequest, null, age(clock_timestamp(), tsBegin), vMessage);
  PERFORM stream.WriteTolog(pProtocol, coalesce(pAddress, 'null'), bRequest, null, age(clock_timestamp(), tsBegin), vContext);

  RETURN null;
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
