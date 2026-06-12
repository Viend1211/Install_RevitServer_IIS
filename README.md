# Install Revit Server IIS Prerequisites

Автоматическая установка необходимых компонентов IIS для Autodesk Revit Server на Windows Server 2022.

Скрипт:

* Устанавливает IIS и необходимые роли
* Включает ASP.NET 4.8
* Включает HTTP и TCP Activation
* Включает IIS 6 Management Compatibility
* Создает подробный лог установки
* Проверяет результат установки каждого компонента
* Выполняет автоматическую перезагрузку сервера

## Требования

* Windows Server 2022
* PowerShell 5.1+
* Права локального администратора
* Доступ в Интернет (для запуска напрямую из GitHub)

---

## Быстрый запуск

Запустите PowerShell от имени администратора и выполните:

```powershell
irm https://raw.githubusercontent.com/Viend1211/Install_RevitServer_IIS/main/Install_RevitServer_IIS.ps1 | iex
```

---

## Безопасный запуск (рекомендуется)

Скачивание и запуск локальной копии:

```powershell
$Script="$env:TEMP\Install_RevitServer_IIS.ps1"
Invoke-WebRequest `
-Uri "https://raw.githubusercontent.com/Viend1211/Install_RevitServer_IIS/main/Install_RevitServer_IIS.ps1" `
-OutFile $Script

PowerShell -ExecutionPolicy Bypass -File $Script
```

---

## Устанавливаемые компоненты

### IIS

* Web Server (IIS)
* ASP.NET 4.8
* ASP
* CGI
* Server Side Includes

### WCF Activation

* HTTP Activation
* TCP Activation

### IIS 6 Compatibility

* IIS 6 Management Compatibility
* IIS 6 Scripting Tools
* IIS 6 WMI Compatibility
* IIS Metabase Compatibility

### Management Tools

* IIS Management Console
* IIS Management Scripts and Tools

---

## Логи

После выполнения создается каталог:

```text
C:\InstallLogs
```

Пример файлов:

```text
C:\InstallLogs\Install_RevitServer_IIS_20260612.log
```

В журнале содержится:

* список установленных компонентов;
* статус каждого компонента;
* ошибки установки;
* дата и время выполнения.

---

## Перезагрузка

После успешного завершения установки сервер автоматически будет перезагружен.

---

## Проверка

После перезагрузки выполните:

```powershell
Get-WindowsFeature | Where-Object Installed
```

или

```powershell
Get-WindowsFeature Web-* | Where-Object Installed
```

---

## Автор

GitHub: https://github.com/Viend1211
