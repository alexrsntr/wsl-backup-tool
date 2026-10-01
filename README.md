# WSL Backup Tool

PowerShell-Skripte zum **Sichern (Export)** und **Wiederherstellen/Übertragen (Import)** einer WSL-Distribution unter Windows — inklusive aller Dateien, installierten Pakete/Apps, Benutzer und Konfiguration.

Getestet für **Kali Linux (WSL2)**, funktioniert aber mit jeder WSL-Distribution (Ubuntu, Debian, …).

## Voraussetzungen

- Windows 10/11 mit WSL2
- PowerShell (als normaler Benutzer; keine Admin-Rechte nötig)
- Genug freier Speicherplatz für die Backup-Datei (ein volles Kali kann mehrere GB groß werden)

## Skripte

| Skript | Zweck |
| ------ | ----- |
| `Export-WslDistro.ps1` | Sichert eine Distribution in eine `.tar`- oder `.tar.gz`-Datei |
| `Import-WslDistro.ps1` | Stellt eine Distribution aus einer Backup-Datei wieder her |

## Verwendung

> **Hinweis:** Die Skripte in **PowerShell unter Windows** ausführen, nicht in der WSL-Shell.
> Falls die Ausführung blockiert wird:
> ```powershell
> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
> ```

### Backup erstellen

```powershell
# Standard: sichert "kali-linux" ins aktuelle Verzeichnis
.\Export-WslDistro.ps1

# Komprimiert nach D:\backups
.\Export-WslDistro.ps1 -Distro kali-linux -OutputDir D:\backups -Compress
```

Die Backup-Datei erhält automatisch einen Zeitstempel, z. B.:
`kali-linux-backup-2026-10-02_143000.tar.gz`

### Auf anderem Rechner importieren

Backup-Datei auf den Zielrechner kopieren, dann:

```powershell
# Einfachster Fall
.\Import-WslDistro.ps1 -BackupFile D:\backups\kali-linux-backup-2026-10-02_143000.tar.gz

# Mit eigenem Namen, Zielordner und Standard-Benutzer
.\Import-WslDistro.ps1 `
    -BackupFile D:\backups\kali-backup.tar `
    -Distro kali-import `
    -InstallDir D:\wsl\kali `
    -DefaultUser kali
```

## Parameter

### `Export-WslDistro.ps1`

| Parameter | Standard | Beschreibung |
| --------- | -------- | ------------ |
| `-Distro` | `kali-linux` | Name der zu sichernden Distribution (`wsl --list --verbose`) |
| `-OutputDir` | `.` (aktuell) | Zielordner für die Backup-Datei |
| `-Compress` | aus | Erstellt `.tar.gz` statt `.tar` |

### `Import-WslDistro.ps1`

| Parameter | Standard | Beschreibung |
| --------- | -------- | ------------ |
| `-BackupFile` | *(Pflicht)* | Pfad zur Backup-Datei |
| `-Distro` | `kali-linux` | Registrierungsname der Distribution |
| `-InstallDir` | `%LOCALAPPDATA%\WSL\<Distro>` | Zielordner für die virtuelle Platte (`ext4.vhdx`) |
| `-DefaultUser` | — | Linux-Benutzer, der als Standard gesetzt wird (sonst startet die Distro als `root`) |

## Hinweise

- **Konsistenz:** Das Export-Skript beendet die Distribution vorher (`wsl --terminate`). Laufende Dienste mit eigener Datenbank (z. B. PostgreSQL/Metasploit in Kali) vorher sauber stoppen:
  ```bash
  sudo service postgresql stop
  ```
- **Standard-Benutzer:** Nach einem Import startet WSL sonst als `root`. Mit `-DefaultUser` wird `/etc/wsl.conf` entsprechend gesetzt.
- **Was NICHT im Backup ist:** laufende Prozesse/Dienststatus und Dateien, die außerhalb des Linux-Dateisystems auf Windows liegen.

## Lizenz

MIT
