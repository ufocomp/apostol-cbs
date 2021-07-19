--------------------------------------------------------------------------------
-- STREAM ----------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- stream.log ------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE stream.log (
    id          bigserial PRIMARY KEY,
    datetime	timestamptz DEFAULT clock_timestamp() NOT NULL,
    username	text NOT NULL DEFAULT session_user,
    protocol    text NOT NULL,
    address		text NOT NULL,
    request     bytea,
    response	bytea,
    runtime     interval,
    message     text
);

COMMENT ON TABLE stream.log IS 'Лог потоковых данных.';

COMMENT ON COLUMN stream.log.id IS 'Идентификатор';
COMMENT ON COLUMN stream.log.datetime IS 'Дата и время';
COMMENT ON COLUMN stream.log.username IS 'Пользователь СУБД';
COMMENT ON COLUMN stream.log.protocol IS 'Протокол';
COMMENT ON COLUMN stream.log.address IS 'Адрес';
COMMENT ON COLUMN stream.log.request IS 'Запрос';
COMMENT ON COLUMN stream.log.response IS 'Ответ';
COMMENT ON COLUMN stream.log.runtime IS 'Время выполнения запроса';
COMMENT ON COLUMN stream.log.message IS 'Информация об ошибке';

CREATE INDEX ON stream.log (protocol);
CREATE INDEX ON stream.log (datetime);

--------------------------------------------------------------------------------
-- stream.package --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE stream.package (
    id          	uuid PRIMARY KEY DEFAULT gen_kernel_uuid('8'),
    datetime        timestamptz DEFAULT clock_timestamp() NOT NULL,
    length          int4 NOT NULL,
    version         int2 NOT NULL,
    params          bit(8) NOT NULL,
    type            int2 NOT NULL,
    serial_size		int2 NOT NULL,
    serial			text NOT NULL,
    command			int2 NOT NULL,
    package			int2 NOT NULL,
    data			bytea NOT NULL,
    crc16           int4 NOT NULL
);

COMMENT ON TABLE stream.package IS 'Общая структура пакета.';

COMMENT ON COLUMN stream.package.id IS 'Идентификатор';
COMMENT ON COLUMN stream.package.datetime IS 'Дата и время';
COMMENT ON COLUMN stream.package.length IS 'Длина всего пакета (все поля кроме поля длины) в байтах';
COMMENT ON COLUMN stream.package.version IS 'Версия протокола';
COMMENT ON COLUMN stream.package.params IS 'Параметры: 0 бит – начальный пакет команды; 1 бит – конечный пакет команды; 2 бит – пакет к счетчику; 3 бит – ответ на запрос; 4 бит – команда упакована (Zlib); 5 бит – команда зашифрована (AES 128); 6 бит – квитанция.';
COMMENT ON COLUMN stream.package.type IS 'Тип устройства';
COMMENT ON COLUMN stream.package.serial_size IS 'Размер идентификатора';
COMMENT ON COLUMN stream.package.serial IS 'Идентификатор';
COMMENT ON COLUMN stream.package.command IS 'Номер команды: Циклически от 0 до 255. При ответе на запрос подставляется из запроса';
COMMENT ON COLUMN stream.package.package IS 'Номер пакета: Номер пакета команды от 0 до 255 (для каждой команды от 0)';
COMMENT ON COLUMN stream.package.data IS 'Данные пакета (команда)';
COMMENT ON COLUMN stream.package.crc16 IS 'Контрольная сумма (CRC16)';

CREATE INDEX ON stream.package (datetime);
CREATE INDEX ON stream.package (serial);

--------------------------------------------------------------------------------
-- stream.command --------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE TABLE stream.command (
    packageId		uuid NOT NULL REFERENCES stream.package ON DELETE CASCADE,
    command			int2 NOT NULL,
    package			int2 NOT NULL,
    date            timestamp,
    type            int2,
    error			int2,
    data            bytea,
    PRIMARY KEY (packageId, command, package)
);

COMMENT ON TABLE stream.command IS 'Общая структура пакета.';

COMMENT ON COLUMN stream.command.packageId IS 'Идентификатор пакета данных';
COMMENT ON COLUMN stream.command.command IS 'Номер команды: Циклически от 0 до 255. При ответе на запрос подставляется из запроса';
COMMENT ON COLUMN stream.command.package IS 'Номер пакета: Номер пакета команды от 0 до 255 (для каждой команды от 0)';
COMMENT ON COLUMN stream.command.date IS 'Метка времени';
COMMENT ON COLUMN stream.command.type IS 'Тип команды';
COMMENT ON COLUMN stream.command.error IS 'Код ошибки';
COMMENT ON COLUMN stream.command.data IS 'Данные команды';

CREATE INDEX ON stream.command (date);
CREATE INDEX ON stream.command (type);
