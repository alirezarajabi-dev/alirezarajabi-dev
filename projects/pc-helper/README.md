# PC Helper by Alireza

<img src="img/pc-helper-robot.png" width="96" align="right" alt="PC Helper robot icon">

**A friendly Windows app that checks, cleans and speeds up a PC in one click — safely and reversibly.**
It greets you by name, shows a health score, and does the boring maintenance work that people usually
do one step at a time.

**[Download for Windows →](download/PC-Helper-by-Alireza-Setup.zip)** · Windows 10 and 11 · Free · No ads · Works offline

## Why I built it

Keeping a Windows PC healthy means visiting ten different places: temporary folders, startup apps,
storage settings, Windows Update, disk tools, repair commands. Most "optimizer" apps promise miracles,
run in the background and change things you can't undo. I wanted the opposite: one honest app that does
the useful work, explains what it did with real numbers, and never touches personal files or backups.

## What it does

- **BOOST MY PC** — one click cleans junk, runs SSD TRIM, refreshes the network cache and re-checks health,
  then shows a before-and-after report (free space, memory in use, health score)
- **Health score and tips** — free space, memory, uptime, pending updates, startup load and battery wear
- **All your drives** — C:, D:, USB sticks, external SSDs and network drives with free space bars; a USB is detected the moment it's plugged in and can be ejected safely
- **Cleaner** — temporary files, browser cache (passwords and logins stay), thumbnail and shader caches,
  error reports, old Windows Update downloads; each with its size before you clean
- **Startup apps** — on/off switches with the RAM each app is using; apps that are safe to turn off are marked
- **Memory and power** — the heaviest apps with honest advice for each (keep, safe to close, or turn off at startup), closed politely so they can offer to save, Power Mode,
  and a read-only view of virtual memory
- **USB format** — makes a USB stick FAT32 + MBR for copiers, printers, cars and TVs
- **Health check** — Defender, Firewall, BitLocker, Recovery Environment, system backup, SSD health,
  TRIM, battery health and last update, plus Windows' own DISM and SFC repair
- **Big files** — finds the largest files in your folders or on any drive (D:, USB…); it never deletes them
- **About page** — reached from the menu or by clicking the animated AR logo
- **Undo changes and history** — every setting it changes can be put back; everything it does is logged
- **Pause and Stop** for every long task, light and dark modes, eight color themes from the AR palette

## Safety first

PC Helper **never** touches Documents, Desktop, Downloads, Pictures, OneDrive, browser passwords or cookies,
the `WindowsImageBackup` folder, external drives, BitLocker, Defender, Firewall, Windows Update settings,
BCD/EFI or recovery partitions. It never turns off the page file, never defragments an SSD,
and never "cleans" Windows' memory cache (that cache makes a PC faster). A drive that holds a Windows backup
or BitLocker is locked in the USB tool and can't be formatted.

It runs only when you open it — nothing stays in the background — and it sends nothing anywhere.

## How it is built

| Area | Approach |
|---|---|
| App | PowerShell 5.1 with a WPF interface, built into every Windows 10/11 PC — no runtime to install |
| Installer | A single `.exe` written in Go with an admin manifest: one permission prompt, then the app opens |
| Cleaning | Deletes only inside a list of known cache folders; a guard rejects any other path; links are never followed |
| Startup | The same `StartupApproved` switches Task Manager uses, so every change is reversible |
| Health | CIM/WMI, Storage cmdlets, `reagentc`, `fsutil`, DISM and SFC — Windows' own tools |
| Design | Readability is calculated, not guessed: every text color is checked against WCAG 4.5:1 and adjusted for each theme |
| Privacy | Local only: no internet, no telemetry, no ads |

## Code samples

Short excerpts that show the approach.

**A safety guard on every delete.** Nothing outside a known cache location can be removed,
and personal folders are refused by name.

```powershell
$Forbidden = @('WindowsImageBackup', '\Documents', '\Desktop', '\Downloads', '\Pictures', '\OneDrive', 'Login Data', 'Cookies')
function Test-SafePath([string]$p) {
    if (-not $p.StartsWith('C:\', [StringComparison]::OrdinalIgnoreCase)) { return $false }
    foreach ($f in $Forbidden) { if ($p -like "*$f*") { return $false } }
    return $true
}
```

**Readable in every theme.** Before a theme is applied, each text color is moved toward black or white
until it reaches the WCAG contrast ratio against its background.

```powershell
function Fit-Contrast([string]$fg, [string]$bg, [string]$toward, [double]$min) {
    $c = $fg
    for ($i = 1; $i -le 20 -and (Get-Contrast $c $bg) -lt $min; $i++) { $c = Mix-Color $toward $fg ($i * 0.05) }
    return $c
}
```

## Install

1. Download **[PC-Helper-by-Alireza-Setup.zip](download/PC-Helper-by-Alireza-Setup.zip)** and open it.
2. Run **Install PC Helper by Alireza** and click **Yes** once.
3. The app opens, and its icon is on your Desktop and in the Start menu.

The installer isn't code-signed yet, so Windows may show "Windows protected your PC" the first time:
choose **More info → Run anyway**. To remove it, use **Uninstall PC Helper** in the Start menu or in Settings.

---

Made with ❤ by **Alireza Rajabi** · Questions or ideas: [support@bizkonic.com](mailto:support@bizkonic.com)
