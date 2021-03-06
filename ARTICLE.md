Как мы собираем проекты в выделенном окружении в Windows Docker
===============================================================

Содержание
==========

1.  Расскажем как было раньше. Какие проблемы были, собственно зачем нам надо
    было что-то менять

2.  Как применили Windows Docker для сборки проектов

3.  Какие улучшения сделали и поделились с сообществом

4.  Какие проблемы встретили, как решили или чего ждём

5.  Экономическая выгода от внедрения Windows Docker

Про текущие процессы
====================

ЧТо имеем
---------

-   Компания по разработке ПО

-   Увеличивающееся количество продуктов (которые в состоят от 10 до 100
    компонент)

-   Требуется разное сборочное окружение для компонентов (sdk, компиляторы,
    языки, etc)

-   Выделенный отдел, который помогает командам выстроить процессы CI и
    занимается сборочным окружением (группа поддержки процессов Continuous
    Integration)

-   Мы поддерживаем как текущие релизы ПО, так и старые. Минимум текущий + 1
    прошлый и сертифицированные по требованиям ФСТЭК и других регуляторов

Как было раньше
---------------

-   Ищутся "похожие" продукты и компоненты (например, много компонент, которые
    собираются msbuild; компоненты написаные на dotnet, есть на c++)

-   Для таких “схожих” компонент выделяется 3-4 сервера, в один пул, с
    идентичным окружением (ПО, переменные окружения) - например, cpp-пул
    (сборочные сервера для c++\\c\# проектов) с установленными студиями и .NET
    SDK

-   Если команде нужно изменение сборочного окружения - вносим изменение на один
    сервер - смотрим чтобы ничего не сломалось у других проектов - расскатываем
    изменения на остальные сервера

-   В начале это делалось вручную, потом - автоматизировано через salt

Делается для экономии сборочных ресурсов (об этом будет еще сказано дальше) -
только для компиляции и юнит-тестов используются 2 сервера с 256GB RAM,
16CPUх2,2GHZ Е5-2660, куча сторов с SSD суммарным объемом \~2TB

Проблема - как поддержать зоопарк окружения
-------------------------------------------

1.  **Сборочное окружение ломалось** - несовместимость ПО или кривая установка,
    приходилось откатывать ВМ на снепшот. При несовместимости ПО приходилось
    выделять для такого проекта новый "пул" серверов для сборки

2.  **Командам хотелось изменять окружение самостоятельно** - но поскольку один
    сервер использовали несколько команд, такого позволить было нельзя (проблема
    общих инструментов - нужно следить за контрактами остальных команд)

3.  **Не соблюдалось требование отказоустойчивости** - иногда в "пул" серверов
    входил один сервер, поскольку проект маленький, если этот сервер ломался,
    команде приходилось ждать восстановления из бэкапа

4.  **Не сохранялось сборочное окружение прошлых релизов** - если приходил баг
    из сертифицированной версии продукта, нужно собрать его с фиксом из тех же
    исходников. Окружение на сборочных серверах давно уехало вперёд

5.  **Неполная утилизация ресурсов виртуальных машин** - VM может быть много, но
    они могут простаивать, но даже простаивающая VM есть ресурсы - CPU\\RAM\\SSD

Решение
=======

Долгожданный
------------

Linux-продукты мы \>4 лет уже собираем в docker, долго ждали когда такое же
реализуют в Windows.

Мы ждали, ждали и [наконец
дождались](https://docs.microsoft.com/en-us/virtualization/windowscontainers/about/)!

-   Windows Docker анонсирован в сентябре 2016 года

-   Docker показал себя эффективным инструментом для решения озвученных проблем

-   Опыт работы в системе сборки с Docker Linux \> 4 лет

-   Своя инфраструктура Docker Registry

В процессе внедрения столкнулись с проблемами, которые и разберём.

Сложность установки ПО: но это же Windows
-----------------------------------------

Есть windows-docker, отлично, давайте на него что-нибудь поставим. Например,
студию

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ bash
# https://github.com/StefanScherer/dockerfiles-windows/blob/master/msbuild/Dockerfile
FROM microsoft/windowsservercore

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN (New-Object System.Net.WebClient).DownloadFile('http://download.microsoft.com/download/5/f/7/5f7acaeb-8363-451f-9425-68a90f98b238/visualcppbuildtools_full.exe', 'visualcppbuildtools_full.exe') ; \
    Start-Process .\visualcppbuildtools_full.exe -ArgumentList '/NoRestart /S' -Wait ; \
    rm visualcppbuildtools_full.exe
# На самом деле тут еще нужно бы почистить temp-папки
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Но а где же apt-get в две строки как это было в Linux?

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ bash
FROM gcc:6.3.0

RUN apt-get update \
    && apt-get install --yes --no-install-recommends cmake
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Если такое требовать писать от разработчиков - они откажутся это делать, и будут
опять просить нас установить нужное им ПО, но уже в докер.

Сложность установки ПО: облегчаем жизнь
---------------------------------------

Хочется вот так (и реализовано) - код есть в репозитории

1.  Скрипт определяем какой тип файла перед нами (и запускает с нужными
    параметрами установки или сразу exe или msiexec для msi-пакетов)

2.  Удаляет скачанный файл и очищаем временные папки

3.  Он читаемый!

4.  Скрипты установки - `install-web` и скрипты скачки архива
    \`download-and-unpack\`

В них нет ничего rocket science, но они помогают разработчикам проще
устанавливать нужные им программы и позволяет всё делать в едином стиле, не
мусоря.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ bash
# EXE|MSI
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.ru/win/packages/erlang/otp_win64_20.0.exe \
    -Filename erlang.exe \ 
    -InstallArgs '/S'

# ZIP
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.ru/win/packages/msbuild/fullmsbuild.zip \
    -Filename setup.exe \ # имя файла ВНУТРИ архива
    -InstallArgs '/S'
    
# Установка и настройка RabbitMQ
ADD "download-and-unpack" "c:\scripts\download-and-unpack"
RUN "c:\scripts\download-and-unpack\download-and-unpack.ps1" \
    -URL https://yourstorage.example.ru/win/packages/rabbitmq/rabbitmq-server-windows-3.6.10.zip \
    -UnpackTo 'C:\Program Files'
ENV PATH 'C:\Program Files\RabbitMQ\3.4\bin';$PATH # проставлять в PATH значение нужно в отдельном шаге
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Размер ПО: делаем как в Linux 1
-------------------------------

-   У каждой команды свой docker образ (и не один) - группа развития CI только
    консультирует как лучше создавать докер-оббразы, как разместить слои, как
    почистить tmp.

-   У каждой компоненты может быть свой docker обра

-   Допускается создание фича-веток docker образов и пуш их в регистри -
    некоторые фича-ветки компонент можно собирать с измененным докером, и
    вливать docker в `latest` после влития кода компоненты в `master`

-   На сборочных серверах вычищаются все docker образы по ночам - чтобы вдруг не
    было старых неиспользуемых образов и были только самые часто используемые

Размер ПО: делаем как в Linux 2
-------------------------------

Попробовали применить процесс на Windows Docker так же как в Linux и получили
следующее

-   Размер образа с основным набором ПО для компиляции

    -   Linux \<5GB, Windows \<45Gb

-   Среднее время сборки образа с нуля (при внесении изменений в первые слои, к
    примеру)

    -   Linux \~ 20 min, Windows \~ 70 min

-   Среднее время pull с нуля

    -   Linux \~ 3 min, Windows \~ 50 min

Что из этого следует?

1.  При внесении изменений в Windows Docker в первые слои у нас встаёт почти вся
    инфраструктура сборки \~ 1 час (сборки + pull на все сервера)

2.  Мы не можем давать право каждой команде использовать свои образа - просто не
    хватит места на дисках

3.  Так же не можем постоянно пересобирать `latest`, нужно ждать нескольких
    изменений (если одно из них где-то в начале `Dockerfile`)

Размер ПО: делаем по своему 1
-----------------------------

1.  Есть базовые образы, с предустановленным часто используемым ПО

    1.  Python

    2.  Visual Studio Build Tools

    3.  SDKs

2.  У каждой команды есть свой образ, где они могут добавлять ПО

3.  Тестирование новых образов (фича-веток) происходит строго на одном сервере

4.  Docker образы очищаются редко, практически вручную

Размер ПО: делаем по своему 2
-----------------------------

Примерно так выглядит схема

1.  Базовые образы с разными студиями, SDK

2.  Команды явно указывают `FROM: vc140:latest` в своих `Dockerfile`

3.  При появлении нового Studio (точнее, build-tools), команде нужно просто
    заменить на `FROM: vc160:latest`

Процесс внесения изменений: установка ПО
----------------------------------------

1.  Сохранить exe\msi на сервер по адресу
    https://yourstorage.example.ru/win/packages - храним установщики, чтобы
    меньше зависить от интернета (не всегда получается, как например со
    msbuild-tools)

2.  С помощью
    [USSF](http://www.softpedia.com/get/System/Launchers-Shutdown-Tools/Universal-Silent-Switch-Finder.shtml)
    найти ключи для установки в тихом режиме (без взаимодействия пользователя)

3.  Добавляем строчку с помощью скрипта install-web.ps1 (или
    download-and-unpack) по аналогии с существующими

4.  Делаем мердж-реквест в `latest`

Примеры Dockerfile доступны в github:
[github.com/](https://github.com/allburov/docker-windows)[allburov](https://github.com/allburov/docker-windows)[/](https://github.com/allburov/docker-windows)[docker](https://github.com/allburov/docker-windows)[-windows​](https://github.com/allburov/docker-windows)

Демо
----

Давайте попробуем установить Erlang новой версии в дополнении к vc140

1.  Скачать Erlang с сайта (найти в гугле). Зачем качать? Чтобы не ждать каждый
    раз при пересборке полного Dockerfile по 5 минут на скачивание одного exe :)

2.  Сохранить Erlang в хранилке (мы используем Артифакторий). Показать как мы
    храним packages в Windows - есть ссылка в блокноте. Скопировать ссылку в
    блокноте на exe-шник

3.  Создать папку `windows-devopsdays`

4.  Скачать zip-архив с github\\allburov\\docker-windows, перенести оттуда папки
    `install-web` + `download-and-unpack` , из папки windows-team1 скопировать
    Dockerfile.

5.  Сделать новый Dockerfile, унаследоваться от windows-vc140

6.  Проверить с помощью USSF ключи тихой установки erlang

7.  Собрать Docker-образ

8.  Запустить Docker-образ

    1.  hostname

    2.  проверить версию erlang.exe

9.  Поменять на `FROM vc150`

Windows Docker Bug (not Bounty)
===============================

### Symlink, GetFinalPathNameByHandle

Функция
[GetFinalPathNameByHandle](https://msdn.microsoft.com/ru-ru/library/windows/desktop/aa364962%28v=vs.85%29.aspx?f=255&MSPPError=-2147217396)
неправильно отображает подключенные пути. Функция отображает относительные и
прочие пути в полный путь используя \*\*\\?\*\* синтаксис

Подробнее -
[MSDN](https://social.msdn.microsoft.com/Forums/en-US/3f111d9d-1223-42f1-a913-5caba4b773bc/getfinalpathnamebyhandlevolumenamedos-function-is-not-working-inside-container?forum=windowscontainers)
-
[realpath](https://github.com/StefanScherer/dockerfiles-windows/tree/master/realpath)

На нас это повлияло в python-скриптах, сборке c++ библиотек, в общем неплохо
заблокировало нам внедрение Windows Docker

В случае, если директория используется как Docker Volume,
**GetFinalPathNameByHandle** неправильно отображает её - должен отображать в
путь с \\?, а отображает как есть

**Хак** для python (доступен в [Dockerfile](windows-vc140/Dockerfile)): патчить
**pathlib.py**, заменяя используемые функции.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ python
mkdir c:\test
docker run -v c:\test:c:\test -it python:3.6-windowsservercore powershell
python

from nt import _getfinalpathname

_getfinalpathname('c:\\') # OK
_getfinalpathname('c:\\test')

>>> _getfinalpathname('c:\\test')
Traceback (most recent call last):
 File "<stdin>", line 1, in <module>
FileNotFoundError: [WinError 2] The system cannot find the file specified: 'c:\\test'
>>>
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### 260 символов хватит всем

Многие сталкивались с прекрасным ограничением в Win32 API MAX_PATH=260 символов
(когда файл нельзя назвать длинее 260 символов)

В Windows-docker проблема появляется - если к запускаемому докеру подключать
директорию, то она подключается как symlink - Безобидный **c:**\build***\*
превращается в**
\\?\ContainerMappedDirectories\\30FA5B39-9158-4785-A3A9-0435BFF32D2B\*\* - Даже
если в хостовой системе путь допустимый и меньше 260 символов, то в docker он
превращается в более длинный путь

У этой баги возможно есть фикс - обещали в локальных политиках дать возможность
отключить ограничение на количество символов в имени. Но это не точно

### У каждого слоя - свой hostname

Проблема установки служб - у каждого слоя свой hostname, получается следующее:

1.  Устанавливается в слое rabbitmq

2.  В следующем - запускается

3.  Проходят еще шаги

4.  Запускается контейнер - но у него уже hostname другой

5.  получается что rabbitmq ругается

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Hostname mismatch: node "rabbit@202fd51f02fd" believes its host is different. Please ensure that hostnames resolve the same way locally and on "rabbit@202fd51f02fd"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Silent install & GUI

Два примера: 1. gvim (vim для Windows) - ранее не поддерживал silent-установку,
пришлось править инсталлятор (уже замерджено, возможно и инсталлятор
исправленный выпустили) 2. .NET SDK 4.0 - устанавливается только в GUI-режиме

Надеюсь, со временем создатели ПО под Windows будут ориентировать на console
mode, чтобы и установка и работа с приложениями была доступна из консоли

Экономическая выгода от внедрения Windows Docker
------------------------------------------------

Сколько экономим ресурсов при перехода на Windows Docker 1
----------------------------------------------------------

При обосновании затрат на внедрение новой технологии нас спросили “А зачем?”.
Интуитивно понятно что это приносит выгоду в процессах разработки, но
человеческие ресурсы сложнее оценить. Мы попробовали оценить сколько мы экономим
на железных ресурсах при переходе на Windows Docker, после того как получили
цифру в год, человеческие затраты даже не считали, хотя в них выигрышь точно
есть :)

В расчет брали:

-   Сколько текущих ресурсов мы используем при настройке разного окружения
    командам (1 окружение несовместимое с другими - минимум 1 новая VM)

-   Сколько планируется разворачивать VM (процесс перехода на windows docker
    завершен \~40%)

-   Сколько экономия (освободится ресурсов)

Итого экономим: 42vCPU, 100GB RAM, \~400GB SSD

 

Сколько экономим ресурсов при перехода на Windows Docker 2
----------------------------------------------------------

Как оценить то что у нас есть правильно? Если просто считать стоимость новых
серверов с текущими характеристиками, то не будут учтены затраты на
обслуживание, ремонт, установку и прочее.

Т.к. некоторые команды для целей тестирования и разворачивания продакшн
используют хостинги, решили пойти этим же путём.

Вбили характеристики железа, получили следующие цифры.

-   В месяц стоит 94 тысячи рублей

-   В год выходит 1 128 000 рублей.

-   Даже если учитывать со очень большой скидкой, допустим 40% 600 000 тысяч
    рублей\\год

Говорят там есть еще скидка, но я в них не верю :)

Дальнейшее развитие
-------------------

В дальнейшем, планируем использовать Windows Docker в следующих сценариях:

1.  Версионирование docker образов

    1.  Нужно для сохранения окружения при релизах продуктов

2.  Устанавливать продукты в docker и гонять интеграционные тесты

3.  Поставлять dev-окружение контейнерами

4.  Поставлять production docker-образы

Итоги 1
=======

1.  Как было раньше

    1.  только группа Continuous Integration имеет доступ к серверам

2.  Проблемы

    1.  долго

    2.  ломалось и нет версионирования

    3.  неэкономно

3.  Решение

    1.  упрощение установки — скрипты, фиксированный процесс

    2.  своя схема для Windows

4.  С чем столкнулись

    1.  Symbolic Links

    2.  Silent install mode

Итоги 2
=======

Попробуйте использовать:
[github.com/](https://github.com/allburov/docker-windows)[allburov](https://github.com/allburov/docker-windows)[/](https://github.com/allburov/docker-windows)[docker](https://github.com/allburov/docker-windows)[-windows](https://github.com/allburov/docker-windows)

1.  Копируем структуру: Dockerfile + скрипты powershell

2.  Собираем: `docker build . –t name`

3.  Используем: `docker run –it name powershell.exe –v c:\build`
