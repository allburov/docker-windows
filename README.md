Как мы собираем проекты в выделенном окружении в Windows Docker
==========================================
Полный текст статьи можно [прочитать тут](ARTICLE.md)

------

# Branch
Все изменения нужно вносить в **latest** ветку, но проверить на ОДНОМ сервере
- **latest** - последняя версия 
- **stable** - последняя ТОЧНО стабильная версия **latest**, которая была раскатана на все сервера

# File in Docker
Чтобы не захламлять диск C:\ есть договоренность подключать внешние файла (командой **ADD** или **COPY**) в следующие директории. Создаем поддерикторию в нужной папке
- **C:\install** - файлы конфигураций, мелкие exe-шники (допустимо сюда подключить и скрипты, если всё в одной папке)
- **C:\scripts** - скрипты настройки, прочее (допустимо сюда же подключать файлы конфигураций и exe, если они нужны для настройки)
Выбор не критичен, можно в любую

# Scripts
Каждый скрипт размещать в **отдельную** папку и подключать отдельным шагом

## install-web
**install-web.ps1** - скачивает из интернета **exe|msi** и запускает с нужными командами установки. Если это **zip** - то дополнительно распаковывает и запускает исполняемый файл ВНУТРИ архива
- скрипт сам скачает файл
- запустит установки в зависимости от расширения
- очистит темповые папки

### How install new software
1. Сохранить exe\msi на сервер по адресу https://yourstorage.example.ru/win/packages
2. С помощью [USSF](http://www.softpedia.com/get/System/Launchers-Shutdown-Tools/Universal-Silent-Switch-Finder.shtml) найти ключи для установки в тихом режиме (без взаимодействия пользователя
3. Добавляем строчку с помощью скрипта install-web.ps1 по аналогии с существующими 

``` bash
# EXE|MSI
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.ru/win/packages/erlang/otp_win64_20.0.exe \
    -Filename erlang.exe \ # Имя файла для сохранения
    -InstallArgs '/S'

# ZIP
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.ru/win/packages/msbuild/fullmsbuild.zip \
    -Filename setup.exe \ # имя файла ВНУТРИ архива
    -InstallArgs '/S'
```

## download-and-unpack
**download-and-unpack.ps1** - скачивает из интернета архив и просто распаковывает его. Используется для хранения больших exe|dll и прочего.

``` bash
# Установка и настройка RabbitMQ
ADD "download-and-unpack" "c:\scripts\download-and-unpack"
RUN "c:\scripts\download-and-unpack\download-and-unpack.ps1" \
    -URL https://yourstorage.example.ru/win/packages/rabbitmq/rabbitmq-server-windows-3.6.10.zip \
    -UnpackTo 'C:\Program Files'
ENV PATH 'C:\Program Files\RabbitMQ\3.4\bin';$PATH # проставлять в PATH значение нужно в отдельном шаге
```