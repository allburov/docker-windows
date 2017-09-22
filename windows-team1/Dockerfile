FROM docker-registry.example.com/windows-vc140:latest

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ADD "install-web" "c:\install-web"

# ------------------- Установка ПО -------------------
# .NET Core SDK (contains .NET Core 1.0 and 1.1) 
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.com/win/packages/microsoft/dotnetcore/dotnet-dev-win-x64.1.0.4.exe \
    -Filename dotnet.exe \
    -InstallArgs '/install /quiet /norestart'

# ------------ START RabbitMQ ------------
# Erlang/OTP 20.0 x64
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.com/win/packages/erlang/otp_win64_20.0.exe \
    -Filename erlang.exe \
    -InstallArgs '/S'
ENV PATH 'C:\Program Files\erl9.0\bin';$PATH
ENV ERLANG_HOME 'C:\Program Files\erl9.0'

# Установка и настройка RabbitMQ
ADD "download-and-unpack" "c:\scripts\download-and-unpack"
RUN "c:\scripts\download-and-unpack\download-and-unpack.ps1" \
    -URL https://yourstorage.example.com/win/packages/rabbitmq/rabbitmq-server-windows-3.6.10.zip \
    -UnpackTo 'C:\Program Files'

ENV RABBITMQ_NODE_IP_ADDRESS localhost
ENV RABBITMQ_NODENAME rabbitmq@localhost
ADD "rabbitmq" "c:\scripts\rabbitmq"
RUN "c:\scripts\rabbitmq\install.ps1"
# ------------ END RabbitMQ ------------

# ------------ START MongoDB ------------
# Visual C++ Redistributable for Visual Studio 2017 (64-bit)
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.com/win/packages/microsoft/redist/2017vc_redist.x64.exe \
    -Filename erlang.exe \
    -InstallArgs '/install /quiet /norestart'

RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.com/win/packages/mongodb/mongodb-win32-x86_64-2008plus-ssl-3.4.6-signed.msi \
    -Filename MongoDB.msi \
    -InstallArgs '/quiet /norestart' 
ENV PATH 'C:\Program Files\MongoDB\Server\3.4\bin';$PATH

ADD "mongo" "c:\data"
RUN "c:\data\install-mongo.ps1"
# ------------ END MongoDB ------------


# ------------ START PostgreSQL ------------
# Visual C++ Redistributable for Visual Studio 2013 (64-bit)
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.com/win/packages/microsoft/redist/vcredist_2013_x64.exe \
    -Filename redist_2013.exe \
    -InstallArgs '/install /quiet'

# Visual C++ Redistributable for Visual Studio 2013 (32-bit)
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.com/win/packages/microsoft/redist/vcredist_2013_x86.exe \
    -Filename redist_2013_86.exe \
    -InstallArgs '/install /quiet'

# postgresql-9.6.3-2-windows-x64.exe
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.com/win/packages/postgresql/postgresql-9.6.3-2-windows-x64.exe \
    -Filename postgresql.exe \
    -InstallArgs '--unattendedmodeui none --mode unattended'
# ------------ END PostgreSQL ------------

# ------------ START MSSQL Express ------------
# Microsoft® SQL Server® 2012 Express (SqlLocalDb.msi)
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.com/win/packages/microsoft/mssql/SqlLocaLDB.MSI \
    -Filename SqlLocaLDB.msi \
    -InstallArgs 'IACCEPTSQLLOCALDBLICENSETERMS=YES /quiet' 

# sqllocaldb.exe
ENV PATH 'C:\Program Files\Microsoft SQL Server\110\Tools\Binn';$PATH
# ------------ END MSSQL Express ------------

# Java 8 update 141
# https://www.java.com/ru/download/help/silent_install.xml
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.com/win/packages/jre/x86_64/jre-8u141-windows-x64.exe \
    -Filename java8.exe \
    -InstallArgs '/s'

# ------------ Мелкие изменения и настройки ------------
# Настроить PostgreSQL
ADD "postgresql" "c:\scripts\postgresql"
RUN "c:\scripts\postgresql\install.ps1"

# Резервирование портов
ADD "port-config" "c:\scripts\port-config"
RUN & cmd /c "c:\scripts\port-config\port-config.cmd"

# Nuget repo login
ADD "nuget-auth" "c:\nuget-auth"
RUN "C:\nuget-auth\nuget-auth.ps1"

# dotnet.exe to PATH
ENV PATH 'C:\Program Files\dotnet';$PATH
# java.exe to PATH
ENV PATH 'C:\ProgramData\Oracle\Java\javapath';$PATH

CMD ["cmd"]