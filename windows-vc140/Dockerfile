FROM microsoft/dotnet-framework:3.5

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ADD "install-web" "c:\install-web"

# ------------------- Установка ПО -------------------

# Python 3.4
RUN "C:\install-web\install-web.ps1"\
	-URL https://yourstorage.example.com/win/packages/python/x86_64/python-3.4.4.msi \
	-Filename python34.msi \
	-InstallArgs '/quiet /norestart' 
ENV PATH C:\\Python34;$PATH
RUN python -mpip install pip --upgrade

# Visual Studio 2013 (vc120) build tools
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.com/win/packages/microsoft/vc120/BuildTools_Full.exe \
    -Filename buildtools.exe \
    -InstallArgs '/Silent /Full'
ENV PATH 'C:\\Program Files (x86)\\MSBuild\\12.0\\Bin';$PATH

# Visual Studio 2015 (vc140) build tools
RUN "C:\install-web\install-web.ps1"\
	-URL https://yourstorage.example.com/win/packages/microsoft/vc140/visualcppbuildtools_full.exe \
	-Filename buildtools.exe \
	-InstallArgs '/Quiet /Full'
ENV PATH 'C:\\Program Files (x86)\\MSBuild\\14.0\\Bin';$PATH

# .net 4.5.1 SDK aka Windows Software Development Kit (SDK) for Windows 8.1
RUN "C:\install-web\install-web.ps1"\
	-URL https://yourstorage.example.com/win/packages/microsoft/sdksetup81.exe \
	-Filename sdksetup81.exe \
	-InstallArgs '/features OptionId.NetFxSoftwareDevelopmentKit /quiet /norestart'
	
# .net 4.5 SDK aka Windows Software Development Kit (SDK) for Windows 8
RUN "C:\install-web\install-web.ps1"\
	-URL https://yourstorage.example.com/win/packages/microsoft/sdksetup8.exe \
	-Filename sdksetup8.exe \
	-InstallArgs '/features OptionId.NetFxSoftwareDevelopmentKit /quiet /norestart'

# .net 4.0 - can not install because it's required GUI
#RUN "C:\install-web\install-web.ps1"\
#	-URL https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe \
#	-Filename dotnet40.exe \
#	-InstallArgs '/q'

# NuGet
RUN Invoke-WebRequest "https://yourstorage.example.com/win/packages/nuget/4.1.0.2450.exe" -OutFile "C:\windows\nuget.exe" -UseBasicParsing  
ENV PATH C:\\windows;$PATH

# Cmake 3.2.3
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.com/win/packages/cmake/x86/cmake-3.2.3-win32-x86.exe \
    -Filename cmake323.exe \
    -InstallArgs '/S' 
ENV PATH 'C:\\Program Files (x86)\\Cmake\\bin';$PATH

# GIT 2.13.0
RUN "C:\install-web\install-web.ps1"\
    -URL https://yourstorage.example.com/win/packages/git/Git-2.13.0-64-bit.exe \
    -Filename git.exe \
    -InstallArgs '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-' 
ENV PATH 'C:\\Program Files\\Git\\bin';$PATH

# ------------------- Быстрые изменения вроде реестра -------------------
# Add install directory
# TODO: Скачивать архивами, распаковывать
ADD "install" "c:\install"
ENV PATH 'C:\install';$PATH
ENV PATH 'C:\Windows\System32';$PATH

RUN python -mpip install -r c:/install/requirements.txt

# HACK - патчим pathlib, чтобы не было косяков с _getfinalpathname - в докере оно не обрабатывает ссылки, почему-то
# https://github.com/StefanScherer/dockerfiles-windows/tree/master/realpath 
# https://social.msdn.microsoft.com/Forums/en-US/3f111d9d-1223-42f1-a913-5caba4b773bc/getfinalpathnamebyhandlevolumenamedos-function-is-not-working-inside-container?forum=windowscontainers
RUN foreach ($python in (Get-ChildItem 'c:\python*')) { \
		$pathlib_path = $python.fullname + '\Lib\pathlib.py'; \
		Write-Host "Patch $pathlib_path"; \
		(Get-Content $pathlib_path) -replace 'return self._ext_to_normal\(_getfinalpathname\(s\)\)', 'return self._ext_to_normal(os.path.realpath(s))' | Set-Content $pathlib_path; \
	}

ENV PATH 'C:\Windows\System32\WindowsPowershell\v1.0';$PATH

# ------------------- Visual Studio 2013 HACK -------------------
# TODO: Скачивать архивом
# ADD 'C:\\Program Files (x86)\\MSBuild\\Microsoft.Cpp\\v4.0\\V120'
# ADD 'C:\\Program Files (x86)\\MSBuild\\12.0'
# ADD 'C:\\Program Files (x86)\\Microsoft Visual Studio 12.0'
# ENV VS120COMNTOOLS 'C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\Common7\\Tools\\'

# ADD "env" "c:\env"
# RUN "c:\env\env.ps1"
ENV PATH 'C:\Windows\System32';$PATH

CMD ["cmd"]
