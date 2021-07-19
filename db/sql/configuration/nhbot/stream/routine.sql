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
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Процент');
  WHEN 'second' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Секунда');
  WHEN 'byte' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Байт');
  WHEN 'meter' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Метр');
  WHEN 'freq' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Частота, герц');
  WHEN 'temper' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Температура, градус Цельсия');
  WHEN 'degree' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Градус');
  WHEN 'decimal_degree' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Десятичный градус');
  WHEN 'meter_second' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Метр в секунду');
  WHEN 'time' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Локальное время');
  WHEN 'time_utc' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Всемирное координированное время (UTC)');
  WHEN 'time_day' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Время в секундах с начала суток');
  WHEN 'utf8' THEN
    RETURN jsonb_build_object('data_type', pType, 'data_label', 'Строка в кодировке UTF-8');
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
    RETURN jsonb_build_object('value', round(stream.GetUInt16(pValue.data) / 100, 2), 'value_type', pValue.type, 'value_name', 'Заряд батареи') || stream.GetDataTypeInfo('percent');
  WHEN 1 THEN
    RETURN jsonb_build_object('value', IEEE754_64(stream.GetUInt64(pValue.data)), 'value_type', pValue.type, 'value_name', 'Широта') || stream.GetDataTypeInfo('decimal_degree');
  WHEN 2 THEN
    RETURN jsonb_build_object('value', IEEE754_64(stream.GetUInt64(pValue.data)), 'value_type', pValue.type, 'value_name', 'Долгота') || stream.GetDataTypeInfo('decimal_degree');
  WHEN 3 THEN
    RETURN jsonb_build_object('value', stream.GetUInt16(pValue.data), 'value_type', pValue.type, 'value_name', 'Высота над уровнем моря') || stream.GetDataTypeInfo('meter');
  WHEN 4 THEN
    RETURN jsonb_build_object('value', stream.GetUInt16(pValue.data), 'value_type', pValue.type, 'value_name', 'Точность свойств latitude и longitude') || stream.GetDataTypeInfo('meter');
  WHEN 5 THEN
    RETURN jsonb_build_object('value', stream.GetUInt16(pValue.data), 'value_type', pValue.type, 'value_name', 'Точность свойства altitude') || stream.GetDataTypeInfo('meter');
  WHEN 6 THEN
    RETURN jsonb_build_object('value', stream.GetUInt16(pValue.data), 'value_type', pValue.type, 'value_name', 'В каком направлении движется устройство') || stream.GetDataTypeInfo('degree');
  WHEN 7 THEN
    RETURN jsonb_build_object('value', stream.GetUInt16(pValue.data), 'value_type', pValue.type, 'value_name', 'Скорость движения устройства') || stream.GetDataTypeInfo('meter_second');
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

  -- length – длина данных (1 или 2 байта).
  -- 1 байт: 0-6 бит – младшие биты длины, 7 бит – длина данных 2 байта).
  -- 2 байт: присутствует если установлен 7 бит первого байта, 0-7 бит – старшие биты длины.
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

  -- Команда 0x03. Архивы
  IF cmd.type = 3 THEN
    RETURN;
  END IF;

  -- Команда 0x04. Текущие значения
  IF cmd.type = 4 THEN
    -- Количество значений
    count := get_byte(cmd.data, 0);
    pos := pos + 1;
    -- Для каждого значения:
    FOR i IN 0..count - 1
    LOOP
      -- Тип значения
      cmd04.type := get_byte(cmd.data, pos);
      pos := pos + 1;
      -- Размер значения
      cmd04.size := get_byte(cmd.data, pos);
      pos := pos + 1;
      -- Текущее значение
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

  -- Текущее время счетчика. 0 – неопределенное время, 1 – ошибка времени
  IF temp > 1 THEN
    Result.date := to_timestamp(temp);
  END IF;

  Result.type := get_byte(pData, Pos);
  Pos := Pos + 1;

  Result.error := get_byte(pData, Pos);
  Pos := Pos + 1;

  -- Если есть ошибка, то поле "Данные" отсутствует
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
 * Разбор пакета.
 * @param {text} pProtocol - Протокол (формат данных)
 * @param {text} pAddress - Сетевой адрес (host:port)
 * @param {text} pBase64 - Данные в формате BASE64
 * @return {text} - Ответ в формате BASE64
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
