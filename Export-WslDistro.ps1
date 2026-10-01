<#
.SYNOPSIS
    Exportiert (sichert) eine WSL-Distribution in eine Archivdatei.

.DESCRIPTION
    Erstellt ein vollständiges Backup einer WSL-Distribution (Dateisystem,
    installierte Pakete, Benutzer, Konfiguration) als .tar oder .tar.gz.
    Vor dem Export wird die Distribution beendet, damit ein konsistenter
    Stand gesichert wird.

.PARAMETER Distro
    Name der WSL-Distribution (siehe 'wsl --list --verbose').
    Standard: kali-linux

.PARAMETER OutputDir
    Zielordner fuer die Backup-Datei. Wird bei Bedarf erstellt.
    Standard: aktuelles Verzeichnis.

.PARAMETER Compress
    Erstellt ein komprimiertes .tar.gz statt .tar (spart Platz, braucht WSL
    mit --format Unterstuetzung).

.EXAMPLE
    .\Export-WslDistro.ps1
    Exportiert kali-linux als .tar ins aktuelle Verzeichnis.

.EXAMPLE
    .\Export-WslDistro.ps1 -Distro Ubuntu -OutputDir D:\backups -Compress
    Exportiert Ubuntu komprimiert nach D:\backups.
#>
[CmdletBinding()]
param(
    [string]$Distro = "kali-linux",
    [string]$OutputDir = ".",
    [switch]$Compress
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

# Pruefen, ob die Distro existiert
$installed = (wsl --list --quiet) -replace "`0", "" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
if ($installed -notcontains $Distro) {
    Write-Host "Distribution '$Distro' wurde nicht gefunden." -ForegroundColor Red
    Write-Host "Verfuegbare Distributionen:" -ForegroundColor Yellow
    $installed | ForEach-Object { Write-Host "  - $_" }
    exit 1
}

# Zielordner sicherstellen
if (-not (Test-Path -LiteralPath $OutputDir)) {
    Write-Step "Erstelle Zielordner: $OutputDir"
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
$OutputDir = (Resolve-Path -LiteralPath $OutputDir).Path

# Dateinamen mit Zeitstempel bauen
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
$ext = if ($Compress) { "tar.gz" } else { "tar" }
$fileName = "$Distro-backup-$timestamp.$ext"
$outPath = Join-Path $OutputDir $fileName

# Distribution beenden fuer konsistenten Stand
Write-Step "Beende Distribution '$Distro'..."
wsl --terminate $Distro 2>$null

# Export
Write-Step "Exportiere '$Distro' nach:`n    $outPath"
if ($Compress) {
    wsl --export $Distro "$outPath" --format tar.gz
} else {
    wsl --export $Distro "$outPath"
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Export fehlgeschlagen (Exit-Code $LASTEXITCODE)." -ForegroundColor Red
    exit $LASTEXITCODE
}

$sizeGB = [math]::Round((Get-Item -LiteralPath $outPath).Length / 1GB, 2)
Write-Step "Fertig. Backup-Groesse: $sizeGB GB"
Write-Host $outPath -ForegroundColor Green
