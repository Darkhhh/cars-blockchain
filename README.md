# My Selling Car Whitepaper

## Введение

My selling car это децентрализованная система регистрации, учёта и продажи автомобилей на основе блокчейна, которая призвана упростить отслеживание состояния автомобилей для владельцев, производителей, сервисов обслуживания и государства. Основная цель данной системы - вести учет изменений, связанных с автомобилем, чтобы его история и состояние оставались прозрачными, что является особенно важным на вторичном рынке. При разработке данной системы основополагающим принципом был следующий: право собственности и интересы в отношении всех данных должны принадлежать поставщику данных, в большинстве случаев владельцу автомобиля. Ожидается, что блокчейн и его децентрализованный характер станут идеальным решением для решения поставленных задач.

## Действующие лица и проблемы

В первую очередь необходимо обозначить основных заинтересованных лиц и показать какие проблемы могут быть либо решены, либо упрощены. Выделить можно следующие лица:

1. Владелец (нынешний и потенциальный);
2. Производитель
3. Государство
4. Сервисные центры

Текущий владелец может использовать систему в качестве сервисной книжки, в которой хранятся все изменения, связанные с автомобилем. Обычно у каждого сервисного центра своя база данных, в которой хранится вся информация об автомобилях и произведенных с ними операциях, начиная от подкачки шин, заканчивая полным перебором двигателя. В связи с этим, каждый центр может иметь свою структуру данных для представления этих операций, что затрудняет аккумулирование и обработку всех изменений, связанных с автомобилем. Второй проблемой является то, что сбор этих данных затруднен, так как нигде нет учета о посещенных сервисных центрах, кроме, возможно, сервисной книжки автомобиля, которая, как правило, заполняется только у официальных дилеров марки. В случае же закрытия сервисного центра, информация скорее всего будет утеряна безвозвратно.

Потенциальный владелец (сейчас речь идет о покупателе на вторичном рынке) может использовать систему для изучения автомобиля перед покупкой. Полная история изменений не позволит скрыть какие-либо дефекты, которые могут оказаться критичными для функционирования автомобиля, или недочеты, которые могут быть важны для покупателя. Также учет позволяет защититься от мошенничества, в частности от продажи автомобиля не его владельцем или намеренное искажение характеристик автомобиля, как частный пример, скрутка пробега.

Для производителя система может решить проблемы юридического и финансового характера. Например, фиксация установленных деталей и их оригинальность может помочь регулировать юридические вопросы ответственности в случае, если авто не функционально или имеет дефект производства. При покупке будущий владелец может удостовериться, что все данные об авто внесены, что также может внести ясность при судебном разбирательстве, так как вся информация имеет временные метки. Помимо юридических проблем, система может помочь повысить эффективность продаж оригинальных деталей. Владелец может быть заинтересован в гарантии, которая распространяется на детали и автомобиль, вне зависимости от места приобретения деталей.

Органы государственной власти с помощью данной системы могут вести учет автомобилей и их владельцев, а также состояния автомобилей. Например, для каждого автомобиля, в зависимости от его мощности, устанавливается своя ставка налогообложения. Если владелец решит модифицировать транспорт так, что мощность его в итоге увеличиться, государство сможет сразу же изменить ставку в большую сторону. Помимо состояния, система учитывает продажи всех экземпляров автомобилей, что упрощает учет налогов при продаже или перепродаже автомобиля.

На первый взгляд, сервисные центры в данной системе ничего не выигрывают, а лишь получают для себя дополнительную нагрузку. Однако можно привести некоторые положительные стороны внедрения у них такой системы. Во-первых, поддерживая работу системы сервисный центр однозначно выходит из серой экономической зоны, что позволяет избежать санкций со стороны государства. Во-вторых, учет производимых операций также может упростить регулирование юридических споров, так как можно отследить какой сервис, когда и с какими частями автомобиля работал, что позволяет однозначно определить сервисы, которые могут быть виноваты в неисправности авто. Помимо этого, государство может стимулировать сервисные центры к участию в этой системе раличными льготами или меньшими налогами.

## Архитектура системы

### Общие концепции

Общая идея заключается в том, что существует один контракт `CarRegistry`, которым владеет государство. В нем хранится информация об автомобилях и с помощью него можно производить над ними операции.

Все изменения состояния автомобиля хранятся в записях событий, текущее состояние можно получить из контракта, а характеристики выделены в отдельные файлы во внешнем хранилище.

На рисунке 1 представлена общая архитектура системы:

![Architecture](docs/src/pics/arch.png)

Если автомобиль подлежит продаже, то контракт автоматически создает новый контракт `TaxedPurchase`, таким образом фиксируется разделение зон ответственности контрактов.

На рисунках 2 и 3 представлены специальные диаграммы, описывающие возможные действия и последовательности действий акторов системы:

![Actors](docs/src/pics/actors.png)

Диаграмма последовательности:

![Sequence Diagram](docs/src/pics/seqDiag.png)

### Роли

Основных ролей всего три (не включая государство):

1. Владелец (`CarOwner`).
2. Сервисный центр (`ServiceCenter`).
3. Производитель (`Manufacturer`).

Государство/registry - только одно, владелец контракта. Может назначать другие роли и устанавливать уровень налогов.

Производители - создают автомобили (указывают им начальные регистрационные номера и характеристики), а потом могут их продать.

Сервисные центры - могут получить авто во временное пользование и менять у нее все характеристики, в общем без ограничений, а еще добавлять операции в логи. Пользование временное и сервисный центр не может автомобиль продать за владельца. Владелец может в любой момент ее себе забрать обратно.

Остальные (владельцы, физические лица) - права по умолчанию, могут только оперировать своими собственными автомобилями, и все что могут это увеличить ей пробег, отдать в сервисный центр (и забрать обратно), или кому-нибудь продать. Также могут добавлять операции в логи к своим автомобилям.

### Структуры данных

Система построена на смарт контрактах платформы Ethereum.

Основная структура данных, представляющая автомобиль, содержит:

- Код регистрации,
- Характеристики,
- Пробег,
- Текущий владелец,
- Сервисный центр (если она на обслуживании),
- Предыдущий владелец,
- Предыдущая цена.

Пример структуры данных в виде программного кода (Рисунок 4):

![Solidity CarInfo](docs/src/pics/carInfo.png)

Также в контракте содержится следующая информация (Рисунок 5):

1. Идентификатор следующего автомобиля (счетчик),
2. Map для всех автомобилей по их идентификаторам,
3. Map, с помощью которого можно определить все автомобили у конкретного владельца (вспомогательная функция),
4. Map, с помощью которого можно определить, существует ли запрос на продажу конкретного автомобиля в данный момент,
5. Map, с помощью которого можно определить тип налогообложения у владельца автомобиля (по умолчанию считается физическим лицом, с подоходным налогом в 13%).

![Solidity Additional Structures](docs/src/pics/addStructures.png)

Кроме структур данных в контракте описаны различные события (Рисунок 6), которые сохраняются в логах.

![Solidity Events](docs/src/pics/events.png)

События тоже записываются в блокчейн. В результате можно, например, просмотреть все события, которые касаются конкретного интересующего автомобиля.

#### Характеристики

Ввиду того, что характеристик у автомобиля много и для разных автомобилей их множество может отличаться, все они выносятся в отдельный файл. Файл представляется в JSON формате и имеет строгую структуру, что позволяет унифицировать алгоритмы обработки этих файлов.

В структуре данных хранится только хэш файла, который в свою очередь является его же названием в отдельном хранилище типа S3. При записи в файл считается его хэш, который берется в качестве ключа в базе данных. Этот хэш и записывается в блокчейне. Это гарантирует, что любой может легко идентифицировать факт, что файл был отредактирован, потому что хэши не будут совпадать (также легко написать программу, которая будет это проверять в автоматическом режиме). Такое решение было принято ввиду того, что полный файл хранить в блокчейне финансово затратно, в то же время хэша достаточно для проверки целостности.

### Налогообложение

Для этого выделен отдельный контракт (Рисунок 7): `TaxedPurchase`.

![Solidity TaxedPurchase](docs/src/pics/taxedPurchase.png)

В нем хранятся данные о продаже конкретного автомобиля, а именно:

- Стоимость (цена),
- Налог при продаже,
- Залог (при продаже обе стороны должны положить в контракт определенную сумму для того, чтобы у них был стимул продажу завершить),
- Продавец,
- Покупатель,
- Лицо, взимающее налог (государство),
- Флаг, показывающий тип платежа (может быть внутренним - полностью оплачиваться валютой платформы, или внешним - через какой-то другой канал),
- Текущее состояние продажи.
