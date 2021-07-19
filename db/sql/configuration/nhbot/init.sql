--------------------------------------------------------------------------------
-- InitConfiguration -----------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitConfiguration()
RETURNS     	void
AS $$
DECLARE
  vLocaleCode	text;
BEGIN
  SELECT SubStr(setting, 1, 2) INTO vLocaleCode FROM pg_settings WHERE name = 'lc_messages';
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\System', 'LocaleCode', vLocaleCode);

  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Name', 'NiceHash Bot');
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Host', 'https://nicehash-bot.com');
  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\CurrentProject', 'Domain', 'nicehash-bot.com');

  PERFORM RegSetValueString('CURRENT_CONFIG', 'CONFIG\Firebase', 'ProjectId', 'nicehash-bot');

  PERFORM InitConfigurationEntity();
END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;

--------------------------------------------------------------------------------
-- FillDataBase ----------------------------------------------------------------
--------------------------------------------------------------------------------
/*
 * Заполнить базу данных тестовыми данными.
 * @return {void}
*/
CREATE OR REPLACE FUNCTION FillDataBase (
) RETURNS 	void
AS $$
DECLARE
  r			record;
BEGIN
  PERFORM SetSessionLocale('ru');

  PERFORM SetArea(GetArea(current_database()));

  PERFORM InitMeasure();

  FOR r IN SELECT id FROM AreaTree(GetArea('all'))
  LOOP
	PERFORM DoCreateArea(r.id);
  END LOOP;

  PERFORM FillCalendar(CreateCalendar(null, GetType('workday.calendar'), 'default.calendar', 'Календарь рабочих дней', 5, ARRAY[6,7], ARRAY[[1,1], [1,7], [2,23], [3,8], [5,1], [5,9], [6,12], [11,4]], '9 hour', '8 hour', '13 hour', '1 hour', 'Календарь рабочих дней.'), date(date_trunc('year', Now())), date((date_trunc('year', Now()) + interval '1 year') - interval '1 day'));

  PERFORM CreateCurrency(null, GetType('iso.currency'), 'USD', 'Доллар США', 'Доллар США.', 840);
  PERFORM CreateCurrency(null, GetType('iso.currency'), 'EUR', 'Евро', 'Евро.', 978);
  PERFORM CreateCurrency(null, GetType('iso.currency'), 'RUB', 'Рубль', 'Российский рубль.', 643);

  PERFORM CreateVendor(null, GetType('device.vendor'), 'unknown.vendor', 'Неизвестный', 'Неизвестный производитель устройств.');

  PERFORM CreateModel(null, GetType('device.model'), GetVendor('unknown.vendor'), null, 'unknown.model', 'Unknown', 'Неизвестная модель устройства.');
  PERFORM CreateModel(null, GetType('device.model'), GetVendor('unknown.vendor'), null, 'android.model', 'Android', 'Неизвестная модель устройства на ОС Android.');
  PERFORM CreateModel(null, GetType('device.model'), GetVendor('unknown.vendor'), null, 'ios.model', 'iOS', 'Неизвестная модель устройства на ОС iOS.');

  PERFORM SetArea(GetArea(current_database()));
END
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
