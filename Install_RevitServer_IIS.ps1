<#
    Install_RevitServer_IIS.ps1
    Включение IIS и компонентов для Revit Server на Windows Server 2022.
    Запускать от имени администратора.

    Что делает скрипт:
    1. Проверяет права администратора.
    2. Включает необходимые роли и компоненты Windows Server.
    3. Формирует подробный отчет: что было до установки, что стало после.
    4. Сохраняет отчет в C:\InstallLogs\RevitServer_IIS_Report_YYYY-MM-DD_HH-mm-ss.txt
    5. Перезапускает IIS.
    6. Перезагружает сервер через 60 секунд.
#>

$ErrorActionPreference = "Stop"

# --- Настройки ---
$LogDir = "C:\InstallLogs"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportPath = Join-Path $LogDir "RevitServer_IIS_Report_$Timestamp.txt"
$RebootDelaySeconds = 60

# --- Список компонентов ---
$Features = @(
    # IIS
    "Web-Server",

    # ASP.NET / .NET / WCF
    "NET-Framework-45-Features",
    "Web-Asp-Net45",
    "NET-WCF-HTTP-Activation45",
    "NET-WCF-TCP-Activation45",

    # IIS Application Development
    "Web-ASP",
    "Web-CGI",
    "Web-Includes",

    # IIS 6 Management Compatibility
    "Web-Mgmt-Compat",
    "Web-Metabase",
    "Web-Lgcy-Scripting",
    "Web-WMI"
)

function Write-ReportLine {
    param([string]$Text = "")
    $Text | Tee-Object -FilePath $ReportPath -Append
}

function Test-IsAdministrator {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# --- Подготовка лога ---
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

Write-ReportLine "============================================================"
Write-ReportLine "ОТЧЕТ УСТАНОВКИ IIS ДЛЯ REVIT SERVER"
Write-ReportLine "============================================================"
Write-ReportLine "Дата и время запуска: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-ReportLine "Сервер: $env:COMPUTERNAME"
Write-ReportLine "Пользователь: $env:USERDOMAIN\$env:USERNAME"
Write-ReportLine "Файл отчета: $ReportPath"
Write-ReportLine ""

if (-not (Test-IsAdministrator)) {
    Write-ReportLine "ОШИБКА: Скрипт должен быть запущен от имени администратора."
    Write-ReportLine "Установка остановлена."
    exit 1
}

Write-ReportLine "Проверка прав администратора: OK"
Write-ReportLine ""

Import-Module ServerManager

Write-ReportLine "Компоненты, которые будут проверены и включены:"
foreach ($Feature in $Features) {
    Write-ReportLine " - $Feature"
}
Write-ReportLine ""

Write-ReportLine "Состояние компонентов ДО установки:"
Write-ReportLine "------------------------------------------------------------"
$Before = Get-WindowsFeature -Name $Features | Select-Object Name, DisplayName, InstallState
foreach ($Item in $Before) {
    Write-ReportLine ("{0,-35} {1}" -f $Item.Name, $Item.InstallState)
}
Write-ReportLine ""

try {
    Write-ReportLine "Запуск установки компонентов..."
    Write-ReportLine "------------------------------------------------------------"

    $InstallResult = Install-WindowsFeature -Name $Features -IncludeManagementTools -Verbose 4>&1
    $InstallResult | ForEach-Object { Write-ReportLine $_.ToString() }

    Write-ReportLine ""
    Write-ReportLine "Установка завершена без критической ошибки."
}
catch {
    Write-ReportLine ""
    Write-ReportLine "ОШИБКА УСТАНОВКИ:"
    Write-ReportLine $_.Exception.Message
    Write-ReportLine ""
    Write-ReportLine "Сервер НЕ будет перезагружен автоматически из-за ошибки."
    exit 1
}

Write-ReportLine ""
Write-ReportLine "Состояние компонентов ПОСЛЕ установки:"
Write-ReportLine "------------------------------------------------------------"
$After = Get-WindowsFeature -Name $Features | Select-Object Name, DisplayName, InstallState
foreach ($Item in $After) {
    $StatusText = if ($Item.InstallState -eq "Installed") { "ВКЛЮЧЕНО" } else { "НЕ ВКЛЮЧЕНО" }
    Write-ReportLine ("{0,-35} {1}" -f $Item.Name, $StatusText)
}

$NotInstalled = $After | Where-Object { $_.InstallState -ne "Installed" }

Write-ReportLine ""
Write-ReportLine "Итоговая проверка:"
Write-ReportLine "------------------------------------------------------------"

if ($NotInstalled.Count -eq 0) {
    Write-ReportLine "OK: Все требуемые компоненты включены."
}
else {
    Write-ReportLine "ВНИМАНИЕ: Не все компоненты включены:"
    foreach ($Item in $NotInstalled) {
        Write-ReportLine " - $($Item.Name) / $($Item.DisplayName) / $($Item.InstallState)"
    }
    Write-ReportLine ""
    Write-ReportLine "Сервер НЕ будет перезагружен автоматически, так как есть невключенные компоненты."
    exit 2
}

Write-ReportLine ""
Write-ReportLine "Перезапуск IIS..."
Write-ReportLine "------------------------------------------------------------"
try {
    iisreset | ForEach-Object { Write-ReportLine $_ }
    Write-ReportLine "IIS успешно перезапущен."
}
catch {
    Write-ReportLine "ВНИМАНИЕ: IIS не удалось перезапустить через iisreset."
    Write-ReportLine $_.Exception.Message
}

Write-ReportLine ""
Write-ReportLine "Сервер будет перезагружен через $RebootDelaySeconds секунд."
Write-ReportLine "Отчет сохранен здесь: $ReportPath"
Write-ReportLine "Дата и время завершения: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-ReportLine "============================================================"

shutdown.exe /r /t $RebootDelaySeconds /c "IIS-компоненты для Revit Server установлены. Отчет: $ReportPath"
