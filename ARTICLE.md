Как мы собираем проекты в выделенном окружении в Windows Docker
==========================================

------

  
------
# Проблемы
## Дано
- Компания по разработке ПО
- ~10 главных продуктов (которые в свою очередь состоят из компонент)
- Требуется разное сборочное окружение для команд (sdk\компиляторы\языки\etc)
- Выделенный отдел, который занимается сборочным окружением и помогает командам выстроить процессы CI
- Компания поддерживает как текущие релизы ПО, так и старые (в том числе сертифицированные по требованиям ФСТЭК и других регуляторов)

## Что было раньше
Ищутся "похожие" продукты и компоненты (например, есть много компонент, которые собираются msbuild, есть компоненты написаные на dotnet, есть на c++)

Для таких компонент выделяется 3-4 сервера, в один пул, с идентичным окружением (ПО, переменные окружения) - например, есть CPP-пул с установленными студиями и основными .NET SDK

Если команде нужно изменение сборочного окружения 
- вносим изменение на один сервер
- смотрим чтобы ничего не сломалось у других проектов
- расскатываем изменения на остальные сервера

В начале это все делалось в ручную, потом - автоматизировано через salt

Всё это делается для экономии сборочных ресурсов - сейчас только для компиляции и юнит-тестов используются 2 сервера с 256GB RAM, 16CPU Е5-2660, куча сторов с SSD разных производителей суммарным объемом ~3TB

## Нерешенные проблемы
1. **Сборочное окружение ломалось** - несовместимость ПО или кривая установка, приходилось откатывать ВМ на снепшот. При несовместимости ПО приходилось выделять для такого проекта новый "пул" серверов для сборки
2. **Командам хотелось изменять окружение самостоятельно** - но поскольку один сервер использовали несколько команд, такого позволить было нельзя
3. **Не соблюдалось требование отказоустойчивости** - иногда в "пул" серверов входил только один сервер, поскольку проект был маленьким, если этот сервер ломался, команде приходилось ждать восстановления из бэкапа
4. **Не сохранялось сборочное окружение прошлых релизов** - если приходил баг из сертифицированной версии продукта, мы должны были собрать его с фиксом из тех же исходников. А окружение на сборочных серверах давно уехало вперёд

# Решение
Linux-продукты мы >3 лет уже собираем в docker, долго ждали когда такое же реализуют в Windows. Мы ждали, ждали и [наконец дождались](https://docs.microsoft.com/en-us/virtualization/windowscontainers/about/)!

В процессе внедрения столкнулись с некоторомы проблемами, которые и разберём.

## Скрипты установки
Теперь у нас есть windows-docker, отлично, давайте на него что-нибудь поставим. Например, студию
```bash
# https://github.com/StefanScherer/dockerfiles-windows/blob/master/msbuild/Dockerfile
FROM microsoft/windowsservercore

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN (New-Object System.Net.WebClient).DownloadFile('http://download.microsoft.com/download/5/f/7/5f7acaeb-8363-451f-9425-68a90f98b238/visualcppbuildtools_full.exe', 'visualcppbuildtools_full.exe') ; \
    Start-Process .\visualcppbuildtools_full.exe -ArgumentList '/NoRestart /S' -Wait ; \
    rm visualcppbuildtools_full.exe
```
Но а где же apt-get в две строки?
```bash
FROM gcc:6.3.0

RUN apt-get update \
    && apt-get install --yes --no-install-recommends cmake
```

Если такое требовать писать от разработчиков - они откажутся это делать, и будут опять просить нас установить нужное им ПО, но уже в докер. Хочется вот так:

```bash
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
```

## Долгий билд
## Remote-registry
## Installation workflow
1. Сохранить exe\msi на сервер по адресу https://yourstorage.example.ru/win/packages
2. С помощью [USSF](http://www.softpedia.com/get/System/Launchers-Shutdown-Tools/Universal-Silent-Switch-Finder.shtml) найти ключи для установки в тихом режиме (без взаимодействия пользователя
3. Добавляем строчку с помощью скрипта install-web.ps1 (или download-and-unpack) по аналогии с существующими
## Тут еще что-нибудь
## Dockerfile

## Прочие баги
Взять из вики
