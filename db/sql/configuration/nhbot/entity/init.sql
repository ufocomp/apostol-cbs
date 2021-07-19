--------------------------------------------------------------------------------
-- InitConfigurationEntity -----------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION InitConfigurationEntity()
RETURNS     	void
AS $$
DECLARE
  uDocument		uuid;
  uReference	uuid;
BEGIN
  -- Документ

  uDocument := GetClass('document');

	-- Счёт

	PERFORM CreateEntityAccount(uDocument);

	-- Адрес

	PERFORM CreateEntityAddress(uDocument);

	-- Клиент

	PERFORM CreateEntityClient(uDocument);

	-- Устройство

	PERFORM CreateEntityDevice(uDocument);

    -- Накладная

    PERFORM CreateEntityDelivery(uDocument);

    -- Требование

    PERFORM CreateEntityDemand(uDocument);

    -- Элемент

    PERFORM CreateEntityElement(uDocument);

    -- Аварийная папка

    PERFORM CreateEntityEmergencyFolder(uDocument);

    -- Акт обнаружения неисправности

    PERFORM CreateEntityFDA(uDocument);

    -- Техническое обслуживание

    PERFORM CreateEntityMaintenance(uDocument);

    -- Руководство

    PERFORM CreateEntityManual(uDocument);

    -- Ордер

    PERFORM CreateEntityOrder(uDocument);

    -- Продукт

    PERFORM CreateEntityProduct(uDocument);

    -- Ремонтная ведомость

    PERFORM CreateEntityRepair(uDocument);

    -- Заявка

    PERFORM CreateEntityRequest(uDocument);

    -- Сотрудник

    PERFORM CreateEntityStaff(uDocument);

    -- Место хранения

    PERFORM CreateEntityStorage(uDocument);

	-- Задача

	PERFORM CreateEntityTask(uDocument);

	-- Заведование

	PERFORM CreateEntityUndertake(uDocument);

  -- Справочник

  uReference := GetClass('reference');

	-- Мероприятие

	PERFORM CreateEntityActivity(uReference);

	-- Календарь

	PERFORM CreateEntityCalendar(uReference);

	-- Категория

	PERFORM CreateEntityCategory(uReference);

	-- Валюта

	PERFORM CreateEntityCurrency(uReference);

	-- Мера

	PERFORM CreateEntityMeasure(uReference);

	-- Модель

	PERFORM CreateEntityModel(uReference);

	-- Проект

	PERFORM CreateEntityProject(uReference);

	-- Свойство

	PERFORM CreateEntityProperty(uReference);

    -- Каталог

    PERFORM CreateEntityCatalog(uReference);

    -- Библиотека

    PERFORM CreateEntityLibrary(uReference);

    -- Должность

    PERFORM CreateEntityPosition(uReference);

    -- Судно

    PERFORM CreateEntityShip(uReference);

    -- Спецификация

    PERFORM CreateEntitySpecification(uReference);

    -- Структура

    PERFORM CreateEntityStructure(uReference);

END;
$$ LANGUAGE plpgsql
   SECURITY DEFINER
   SET search_path = kernel, pg_temp;
