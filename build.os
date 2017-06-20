///////////////////////////////////////////////////////////////////
//
// Сборщик пакетов из библиотеки
//
// Что делает:
//  В безусловном порядке получает актуальную версию из облака в ветке master
//  и создает из полученных исходников .ospx в заданном выходном каталоге.
//
// Что НЕ делает:
//  Не взаимодействует с хабом, не знает про его содержимое, отозванные версии и прочее.
//  Тупо собирает актуальные ospx через opm build и кладет в некий каталог.
//
///////////////////////////////////////////////////////////////////

#Использовать cmdline
#Использовать "librarian"
#Использовать fs
#Использовать tempfiles
#Использовать logos

Перем мРабочийКаталог;
Перем Лог;
Перем КаталогСобранныхПакетов;

Функция ПолучитьПарсер()
	
	Парсер = Новый ПарсерАргументовКоманднойСтроки;
	Парсер.ДобавитьИменованныйПараметр("-d", "Рабочий каталог для сборки");
	Парсер.ДобавитьПараметр("ВыходнойКаталог", "Каталог для собранных ospx");
	Парсер.ДобавитьПараметрКоллекция("БиблиотекиДляСборки", "Имена библиотек для сборки");

	Возврат Парсер;

КонецФункции

Процедура ВыполнитьСборку()
	
	Парсер = ПолучитьПарсер();
	Параметры = Парсер.Разобрать(АргументыКоманднойСтроки);
	Если Параметры = Неопределено Тогда
		Парсер.ВывестиСправкуПоПараметрам();
	КонецЕсли;

	Если Не ЗначениеЗаполнено(Параметры["ВыходнойКаталог"]) Тогда
		Параметры["ВыходнойКаталог"] = ОбъединитьПути(ТекущийКаталог(), "build");
	КонецЕсли;

	ФС.ОбеспечитьКаталог(Параметры["ВыходнойКаталог"]);
	КаталогСобранныхПакетов = Параметры["ВыходнойКаталог"];

	Если ЗначениеЗаполнено(Параметры["-d"]) Тогда
		мРабочийКаталог = Параметры["-d"];
		ФС.ОбеспечитьКаталог(мРабочийКаталог);
	Иначе
		мРабочийКаталог = ВременныеФайлы.СоздатьКаталог();
	КонецЕсли;

	Если Не ЗначениеЗаполнено(Параметры["БиблиотекиДляСборки"]) Тогда
		ВызватьИсключение "Не задан список библиотек для сборки. Укажите '*' для всех";
	КонецЕсли;

	ИменаБиблиотек = Параметры["БиблиотекиДляСборки"];

	Если ИменаБиблиотек[0] = "*" Тогда
		ЗапуститьСборкуПоВсем();
	Иначе
		ЗапуститьСборку(Параметры["БиблиотекиДляСборки"]);
	КонецЕсли;

КонецПроцедуры

Процедура ЗапуститьСборку(Знач ИменаБиблиотек)
	
	МенеджерБиблиотек = Новый МенеджерБиблиотекиПакетов;
	МенеджерБиблиотек.УстановитьСоединение();
	Список = МенеджерБиблиотек.ПолучитьСписокРепозиториев();
	МенеджерБиблиотек.ЗакрытьСоединение();
	Для Каждого ТребуемаяБиблиотека Из ИменаБиблиотек Цикл
		СтрОписание = Список.Найти(ТребуемаяБиблиотека, "Имя");
		Если СтрОписание = Неопределено Тогда
			Лог.Ошибка("Библиотека с именем " + ТребуемаяБиблиотека + " отсутствует в организации");
			Продолжить;
		КонецЕсли;

		ОбработатьБиблиотеку(СтрОписание.РепоБиблиотеки);

	КонецЦикла;

КонецПроцедуры

Процедура ЗапуститьСборкуПоВсем()
	
	МенеджерБиблиотек = Новый МенеджерБиблиотекиПакетов;
	МенеджерБиблиотек.УстановитьСоединение();
	Список = МенеджерБиблиотек.ПолучитьСписокРепозиториев();

	Для Каждого СтрОписание Из Список Цикл
		ОбработатьБиблиотеку(СтрОписание.РепоБиблиотеки);
	КонецЦикла;

КонецПроцедуры

Процедура ОбработатьБиблиотеку(Знач Описание)

	Лог.Информация("Работаю по библиотеке " + Описание.Имя);

	КаталогПакета = ОбъединитьПути(КаталогСобранныхПакетов, Описание.ИмяРепозитория);
	КаталогРепо = ОбъединитьПути(мРабочийКаталог, "src", Описание.ИмяРепозитория);
	ФС.ОбеспечитьКаталог(КаталогРепо);
	ФС.ОбеспечитьКаталог(КаталогПакета);

	ГитРепо = Новый РепоБиблиотеки;
	ГитРепо.НастроитьПоОписанию(Описание);
	ГитРепо.УстановитьКаталогРабочейКопии(КаталогРепо);
	ГитРепо.ПолучитьАктуальныйКод("master");
	
	Сборщик = Новый СборщикПакетов;
	Сборщик.СобратьФайлыПакета(ГитРепо, КаталогПакета);

КонецПроцедуры

/////////////////////////////////////////////////////////////////////////////////
СИ = Новый СистемнаяИнформация;
СИ.УстановитьПеременнуюСреды("LOGOS_CONFIG", "logger.rootLogger=DEBUG");
Логирование.ОбновитьНастройки();

Лог = Логирование.ПолучитьЛог("oscript.infrastructure");

Попытка
	ВыполнитьСборку();
Исключение
	// add cleanup here
	ВременныеФайлы.Удалить();
	ВызватьИсключение;
КонецПопытки;
