# WSL Backup Tool

PowerShell-Skripte zum **Sichern (Export)** und **Wiederherstellen/Übertragen (Import)** einer WSL-Distribution unter Windows — inklusive aller Dateien, installierten Pakete/Apps, Benutzer und Konfiguration.

Getestet für **Kali Linux (WSL2)**, funktioniert aber mit jeder WSL-Distribution (Ubuntu, Debian, …).

---

## Inhalt

- [Voraussetzungen](#voraussetzungen)
- [Skripte](#skripte)
- [Verwendung](#verwendung)
- [Parameter](#parameter)
- [Hinweise zum Backup](#hinweise-zum-backup)
- [How-To: WSL von A bis Z](#how-to-wsl-von-a-bis-z)
- [Lizenz](#lizenz)

---

## Voraussetzungen

- Windows 10 (ab Version 2004 / Build 19041) oder Windows 11
- WSL2
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

## Hinweise zum Backup

- **Konsistenz:** Das Export-Skript beendet die Distribution vorher (`wsl --terminate`). Laufende Dienste mit eigener Datenbank (z. B. PostgreSQL/Metasploit in Kali) vorher sauber stoppen:
  ```bash
  sudo service postgresql stop
  ```
- **Standard-Benutzer:** Nach einem Import startet WSL sonst als `root`. Mit `-DefaultUser` wird `/etc/wsl.conf` entsprechend gesetzt.
- **Was NICHT im Backup ist:** laufende Prozesse/Dienststatus und Dateien, die außerhalb des Linux-Dateisystems auf Windows liegen.

---

# How-To: WSL von A bis Z

Ein kompakter Überblick über alles, was man im Alltag mit dem **Windows Subsystem for Linux** braucht.

## Was ist WSL?

WSL (Windows Subsystem for Linux) lässt dich eine echte Linux-Umgebung direkt unter Windows laufen — ohne klassische virtuelle Maschine und ohne Dual-Boot. **WSL2** nutzt einen echten Linux-Kernel in einer leichtgewichtigen VM und bietet dadurch volle Systemcall-Kompatibilität und gute Performance.

| | WSL1 | WSL2 |
| --- | --- | --- |
| Architektur | Übersetzungsschicht | echter Linux-Kernel in leichter VM |
| Dateisystem-Performance (Linux) | langsamer | schnell |
| Zugriff auf Windows-Dateien | schnell | etwas langsamer (über `/mnt/c`) |
| Docker, systemd, volle Syscalls | eingeschränkt | ja |
| Empfehlung | Spezialfälle | **Standard** |

## Installation

In **PowerShell oder CMD als Administrator**:

```powershell
# Installiert WSL + Standard-Distribution (Ubuntu)
wsl --install
```

Danach Neustart. Für eine bestimmte Distribution:

```powershell
# Verfügbare Distributionen auflisten
wsl --list --online
# oder kurz:
wsl -l -o

# Gezielt installieren, z. B. Kali
wsl --install -d kali-linux
```

WSL2 als Standardversion festlegen:

```powershell
wsl --set-default-version 2
```

## Distributionen verwalten

```powershell
# Installierte Distributionen + Status + WSL-Version
wsl --list --verbose
wsl -l -v

# Eine bestimmte Distribution starten
wsl -d kali-linux

# Als bestimmter Benutzer starten
wsl -d kali-linux -u root

# Standard-Distribution festlegen (was "wsl" ohne -d startet)
wsl --set-default kali-linux

# WSL-Version einer Distro ändern (1 <-> 2)
wsl --set-version kali-linux 2
```

## Starten, Stoppen, Neustarten

```powershell
# Eine Distribution beenden
wsl --terminate kali-linux
wsl -t kali-linux

# ALLE Distributionen + WSL-VM komplett herunterfahren
wsl --shutdown

# Laufende Distributionen anzeigen
wsl --list --running
```

> `wsl --shutdown` ist der Allzweck-"Neustart"-Befehl, wenn WSL hängt, nach Konfig-Änderungen (`.wslconfig` / `wsl.conf`) oder bevor du ein Backup ziehst.

## Distribution entfernen

```powershell
# ACHTUNG: löscht die Distribution und ALLE ihre Daten unwiderruflich
wsl --unregister kali-linux
```

> Tipp: Vorher mit `Export-WslDistro.ps1` sichern!

## Backup & Wiederherstellung (eingebaut)

Genau das automatisieren die Skripte in diesem Repo. Manuell:

```powershell
# Export (Backup)
wsl --export kali-linux D:\backups\kali.tar
wsl --export kali-linux D:\backups\kali.tar.gz --format tar.gz   # komprimiert

# Import (Wiederherstellen / auf anderen PC übertragen)
wsl --import kali-linux D:\wsl\kali D:\backups\kali.tar
```

## Dateien & Zugriff zwischen Windows und Linux

- **Windows-Laufwerke in Linux:** gemountet unter `/mnt/c`, `/mnt/d`, …
  ```bash
  cd /mnt/c/Users/DeinName/Desktop
  ```
- **Linux-Dateien in Windows:** im Explorer über die Netzwerkadresse
  ```
  \\wsl$\kali-linux\home\
  \\wsl.localhost\kali-linux\home\     (neuere Windows-Versionen)
  ```
- **Aktuellen Ordner im Explorer öffnen** (aus der Linux-Shell):
  ```bash
  explorer.exe .
  ```
- **VS Code aus WSL starten:**
  ```bash
  code .
  ```

> **Performance-Tipp:** Arbeite an deinen Projekten im Linux-Dateisystem (`~/projekt`), nicht unter `/mnt/c/...` — das ist bei WSL2 deutlich schneller.

## Benutzer & Rechte

```bash
# Aktueller Benutzer
whoami

# Paket als Administrator ausführen
sudo <befehl>

# Passwort des Linux-Benutzers ändern
passwd
```

Standard-Benutzer dauerhaft festlegen — in `/etc/wsl.conf` innerhalb der Distro:

```ini
[user]
default=kali
```

Danach `wsl --terminate <distro>`, beim nächsten Start aktiv.

## Pakete aktuell halten

**Debian/Ubuntu/Kali (apt):**

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt autoremove -y
```

**Kali-Tools nachinstallieren:**

```bash
# Große Tool-Sammlung
sudo apt install -y kali-linux-large
# Oder Standard-Set
sudo apt install -y kali-linux-default
```

## Netzwerk

- WSL2 bekommt eine eigene virtuelle IP. Von Linux aus:
  ```bash
  ip addr        # eigene WSL-IP
  ```
- Dienste, die in WSL auf `localhost` lauschen, sind meist auch unter Windows-`localhost` erreichbar (localhost-Forwarding).
- Die Windows-Host-IP aus Linux erreichen:
  ```bash
  cat /etc/resolv.conf   # nameserver = Host-IP (bei Standard-Networking)
  ```

## Konfiguration

**Pro Distribution:** `/etc/wsl.conf` (innerhalb der Linux-Distro):

```ini
[boot]
systemd=true          # systemd aktivieren (moderne Dienste)

[user]
default=kali          # Standard-Benutzer

[automount]
enabled=true
options=metadata      # korrekte Datei-Rechte auf /mnt/c
```

**Global (alle WSL2-Distros):** `C:\Users\<DeinName>\.wslconfig` (unter Windows):

```ini
[wsl2]
memory=8GB            # max. RAM für die WSL2-VM
processors=4          # CPU-Kerne
swap=2GB
localhostForwarding=true
```

> Nach Änderungen an `.wslconfig` oder `wsl.conf`: `wsl --shutdown` ausführen, damit sie greifen.

## systemd aktivieren

Viele Dienste (z. B. `systemctl`) brauchen systemd. In `/etc/wsl.conf`:

```ini
[boot]
systemd=true
```

Dann `wsl --shutdown` in Windows. Prüfen:

```bash
systemctl list-units --type=service
```

## WSL selbst aktualisieren

```powershell
# WSL-Kernel / -Komponenten aktualisieren
wsl --update

# Installierte WSL-Version anzeigen
wsl --version

# Status / Standardkonfiguration
wsl --status
```

## Häufige Probleme & Lösungen

| Problem | Lösung |
| ------- | ------ |
| WSL reagiert nicht / hängt | `wsl --shutdown`, dann neu starten |
| Distro startet als `root` (nach Import) | `/etc/wsl.conf` `[user] default=...` setzen |
| `.ps1` lässt sich nicht ausführen | `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` |
| Falsche Dateirechte auf `/mnt/c` | `[automount] options=metadata` in `/etc/wsl.conf` |
| Konfig-Änderung wirkt nicht | `wsl --shutdown` nicht vergessen |
| Zu viel RAM-Verbrauch | Limit in `.wslconfig` setzen (`memory=…`) |
| `code .` findet VS Code nicht | VS Code + "WSL"-Extension unter Windows installieren |

## Nützliche Befehle — Spickzettel

```powershell
wsl --install -d <distro>        # Distro installieren
wsl -l -v                        # Distros + Status + Version
wsl -d <distro>                  # Distro starten
wsl -d <distro> -u root          # als root starten
wsl --set-default <distro>       # Standard-Distro
wsl --terminate <distro>         # Distro beenden
wsl --shutdown                   # alles herunterfahren
wsl --export <distro> <datei>    # Backup
wsl --import <distro> <ordner> <datei>   # wiederherstellen
wsl --unregister <distro>        # löschen (!)
wsl --update                     # WSL aktualisieren
wsl --version                    # WSL-Version
```

---

## Lizenz

MIT
