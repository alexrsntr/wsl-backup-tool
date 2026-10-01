<#
.SYNOPSIS
    Importiert (stellt wieder her) eine WSL-Distribution aus einer Archivdatei.

.DESCRIPTION
    Importiert ein zuvor mit Export-WslDistro.ps1 erstelltes Backup (.tar oder
    .tar.gz) als neue WSL-Distribution. Optional wird der Standard-Benutzer
    gesetzt, damit die Distribution nicht als root startet.

.PARAMETER BackupFile
    Pfad zur Backup-Datei (.tar / .tar.gz). Pflichtangabe.

.PARAMETER Distro
    Name, unter dem die Distribution registriert wird.
    Standard: kali-linux

.PARAMETER InstallDir
    Zielordner fuer die virtuelle Festplatte (ext4.vhdx). Sollte leer sein.
    Standard: $env:LOCALAPPDATA\WSL\<Distro>

.PARAMETER DefaultUser
    Linux-Benutzername, der nach dem Import als Standard gesetzt wird
    (sonst startet die Distro als root). Optional.

.EXAMPLE
    .\Import-WslDistro.ps1 -BackupFile D:\backups\kali-backup.tar.gz
    Importiert als kali-linux in den Standardordner.

.EXAMPLE
    .\Import-WslDistro.ps1 -BackupFile D:\backups\kali-backup.tar `
        -Distro kali-import -InstallDir D:\wsl\kali -DefaultUser kali
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BackupFile,

    [string]$Distro = "kali-linux",

    [string]$InstallDir,

    [string]$DefaultUser
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# Backup-Datei pruefen
if (-not (Test-Path -LiteralPath $BackupFile)) {
    Write-Host "Backup-Datei nicht gefunden: $BackupFile" -ForegroundColor Red
    exit 1
}
$BackupFile = (Resolve-Path -LiteralPath $BackupFile).Path

# Installationsordner bestimmen
if (-not $InstallDir) {
    $InstallDir = Join-Path $env:LOCALAPPDATA "WSL\$Distro"
}

# Namenskonflikt pruefen
$installed = (wsl --list --quiet) -replace "`0", "" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
if ($installed -contains $Distro) {
    Write-Host "Eine Distribution namens '$Distro' ist bereits registriert." -ForegroundColor Red
    Write-Host "Waehle einen anderen -Distro Namen oder entferne die bestehende mit:" -ForegroundColor Yellow
    Write-Host "  wsl --unregister $Distro" -ForegroundColor Yellow
    exit 1
}

# Zielordner sicherstellen (muss existieren, sollte leer sein)
if (-not (Test-Path -LiteralPath $InstallDir)) {
    Write-Step "Erstelle Installationsordner: $InstallDir"
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
} elseif ((Get-ChildItem -LiteralPath $InstallDir -Force | Measure-Object).Count -gt 0) {
    Write-Host "Warnung: Installationsordner '$InstallDir' ist nicht leer." -ForegroundColor Yellow
}

# Import
Write-Step "Importiere '$Distro'`n    aus:  $BackupFile`n    nach: $InstallDir"
wsl --import $Distro "$InstallDir" "$BackupFile"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Import fehlgeschlagen (Exit-Code $LASTEXITCODE)." -ForegroundColor Red
    exit $LASTEXITCODE
}

# Standard-Benutzer setzen
if ($DefaultUser) {
    Write-Step "Setze Standard-Benutzer auf '$DefaultUser'..."
    $conf = "[user]`ndefault=$DefaultUser`n"
    # /etc/wsl.conf in der Distro schreiben
    $conf | wsl -d $Distro -u root -- tee /etc/wsl.conf | Out-Null
    wsl --terminate $Distro
    Write-Host "Standard-Benutzer gesetzt. Beim naechsten Start aktiv." -ForegroundColor Green
}

Write-Step "Fertig. Starten mit:"
Write-Host "  wsl -d $Distro" -ForegroundColor Green
