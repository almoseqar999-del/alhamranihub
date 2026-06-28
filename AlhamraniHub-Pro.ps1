#requires -version 5.1
<#
AlhamraniHub Pro
Professional Windows Support Center

Run:
  Run-AlhamraniHub-Pro.cmd

Notes:
- Built with PowerShell + Windows Forms only.
- Software installs and app updates use Microsoft Winget.
- Some actions require Administrator permissions.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ==========================================================
# Helpers
# ==========================================================

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-Message {
    param(
        [string]$Message,
        [string]$Title = "AlhamraniHub Pro",
        [string]$Icon = "Information"
    )
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, "OK", $Icon) | Out-Null
}

function Confirm-Action {
    param([string]$Message, [string]$Title = "Confirm Action")
    $result = [System.Windows.Forms.MessageBox]::Show($Message, $Title, "YesNo", "Warning")
    return ($result -eq "Yes")
}

function Start-Tool {
    param(
        [Parameter(Mandatory=$true)][string]$Command,
        [string]$Arguments = "",
        [switch]$AsAdmin,
        [string]$ConfirmMessage = ""
    )

    try {
        if ($ConfirmMessage -and -not (Confirm-Action $ConfirmMessage)) { return }

        if ($AsAdmin) {
            if ([string]::IsNullOrWhiteSpace($Arguments)) {
                Start-Process -FilePath $Command -Verb RunAs
            } else {
                Start-Process -FilePath $Command -ArgumentList $Arguments -Verb RunAs
            }
        } else {
            if ([string]::IsNullOrWhiteSpace($Arguments)) {
                Start-Process -FilePath $Command
            } else {
                Start-Process -FilePath $Command -ArgumentList $Arguments
            }
        }
    } catch {
        Show-Message "Unable to start:`n$Command $Arguments`n`n$($_.Exception.Message)" "AlhamraniHub Pro Error" "Error"
    }
}

function Start-Cmd {
    param(
        [Parameter(Mandatory=$true)][string]$CmdLine,
        [switch]$AsAdmin,
        [string]$ConfirmMessage = ""
    )
    Start-Tool -Command "cmd.exe" -Arguments "/k $CmdLine" -AsAdmin:$AsAdmin -ConfirmMessage $ConfirmMessage
}

function Start-PowerShellCommand {
    param(
        [Parameter(Mandatory=$true)][string]$CommandText,
        [switch]$AsAdmin,
        [string]$ConfirmMessage = ""
    )
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($CommandText))
    Start-Tool -Command "powershell.exe" -Arguments "-NoExit -NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded" -AsAdmin:$AsAdmin -ConfirmMessage $ConfirmMessage
}

function Open-Target {
    param([Parameter(Mandatory=$true)][string]$Target)
    try { Start-Process $Target }
    catch { Show-Message "Unable to open:`n$Target`n`n$($_.Exception.Message)" "AlhamraniHub Pro Error" "Error" }
}

function Relaunch-AsAdmin {
    if (-not $PSCommandPath) {
        Show-Message "Save this script as AlhamraniHub-Pro.ps1, then run it as Administrator." "Admin Mode"
        return
    }
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
}

function Copy-Text {
    param([string]$Text)
    [System.Windows.Forms.Clipboard]::SetText($Text)
    Show-Message "Copied to clipboard:`n$Text" "Copied"
}

function Desktop-Path {
    return [Environment]::GetFolderPath("Desktop")
}

function Run-Winget-Install {
    param([string[]]$PackageIds)
    if (-not $PackageIds -or $PackageIds.Count -eq 0) {
        Show-Message "Select at least one app first." "Apps Installer"
        return
    }

    $lines = @()
    $lines += "Write-Host 'AlhamraniHub Pro - App Installation' -ForegroundColor Cyan"
    $lines += "Write-Host '------------------------------------'"
    foreach ($id in $PackageIds) {
        $lines += "Write-Host 'Installing: $id' -ForegroundColor Yellow"
        $lines += "winget install --id $id -e --accept-source-agreements --accept-package-agreements"
        $lines += "Write-Host ''"
    }

    Start-PowerShellCommand ($lines -join "`r`n") -AsAdmin -ConfirmMessage "Install $($PackageIds.Count) selected app(s) using Winget?"
}

# ==========================================================
# Theme
# ==========================================================

$Theme = @{
    Bg          = [System.Drawing.Color]::FromArgb(8, 12, 20)
    TopBar      = [System.Drawing.Color]::FromArgb(14, 22, 36)
    Sidebar     = [System.Drawing.Color]::FromArgb(15, 23, 38)
    Sidebar2    = [System.Drawing.Color]::FromArgb(19, 29, 48)
    Surface     = [System.Drawing.Color]::FromArgb(18, 28, 46)
    Surface2    = [System.Drawing.Color]::FromArgb(25, 38, 61)
    Card        = [System.Drawing.Color]::FromArgb(28, 43, 68)
    CardHover   = [System.Drawing.Color]::FromArgb(43, 65, 101)
    Border      = [System.Drawing.Color]::FromArgb(62, 92, 139)
    Accent      = [System.Drawing.Color]::FromArgb(52, 139, 255)
    Accent2     = [System.Drawing.Color]::FromArgb(54, 211, 153)
    Text        = [System.Drawing.Color]::FromArgb(248, 250, 252)
    Muted       = [System.Drawing.Color]::FromArgb(155, 170, 193)
    Danger      = [System.Drawing.Color]::FromArgb(190, 70, 80)
    Warning     = [System.Drawing.Color]::FromArgb(210, 145, 45)
    Success     = [System.Drawing.Color]::FromArgb(47, 158, 101)
}

$FontTitle   = New-Object System.Drawing.Font("Segoe UI Semibold", 24)
$FontLogo    = New-Object System.Drawing.Font("Segoe UI Semibold", 21)
$FontSection = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
$FontCard    = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$FontRegular = New-Object System.Drawing.Font("Segoe UI", 10)
$FontSmall   = New-Object System.Drawing.Font("Segoe UI", 9)
$FontTiny    = New-Object System.Drawing.Font("Segoe UI", 8)

# ==========================================================
# Main Window
# ==========================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "AlhamraniHub Pro"
$form.Size = New-Object System.Drawing.Size(1320, 820)
$form.MinimumSize = New-Object System.Drawing.Size(1160, 720)
$form.StartPosition = "CenterScreen"
$form.BackColor = $Theme.Bg
$form.Font = $FontRegular
$form.KeyPreview = $true

# Root layout
$root = New-Object System.Windows.Forms.TableLayoutPanel
$root.Dock = "Fill"
$root.BackColor = $Theme.Bg
$root.ColumnCount = 2
$root.RowCount = 2
$root.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 250))) | Out-Null
$root.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$root.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 92))) | Out-Null
$root.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$form.Controls.Add($root)

# Top bar spans both columns
$top = New-Object System.Windows.Forms.Panel
$top.Dock = "Fill"
$top.BackColor = $Theme.TopBar
$root.Controls.Add($top, 0, 0)
$root.SetColumnSpan($top, 2)

# Sidebar
$side = New-Object System.Windows.Forms.Panel
$side.Dock = "Fill"
$side.BackColor = $Theme.Sidebar
$root.Controls.Add($side, 0, 1)

# Main host
$mainHost = New-Object System.Windows.Forms.Panel
$mainHost.Dock = "Fill"
$mainHost.BackColor = $Theme.Bg
$root.Controls.Add($mainHost, 1, 1)

# Header branding
$logo = New-Object System.Windows.Forms.Label
$logo.Text = "G"
$logo.TextAlign = "MiddleCenter"
$logo.Size = New-Object System.Drawing.Size(56, 56)
$logo.Location = New-Object System.Drawing.Point(22, 18)
$logo.BackColor = $Theme.Accent
$logo.ForeColor = [System.Drawing.Color]::White
$logo.Font = $FontLogo
$top.Controls.Add($logo)

$title = New-Object System.Windows.Forms.Label
$title.Text = "AlhamraniHub Pro"
$title.ForeColor = $Theme.Text
$title.Font = $FontTitle
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(92, 16)
$top.Controls.Add($title)

$tagline = New-Object System.Windows.Forms.Label
$tagline.Text = "Professional Windows Support Center  •  Tools  •  Apps  •  Updates  •  Reports"
$tagline.ForeColor = $Theme.Muted
$tagline.Font = $FontSmall
$tagline.AutoSize = $true
$tagline.Location = New-Object System.Drawing.Point(96, 56)
$top.Controls.Add($tagline)

$adminLabel = New-Object System.Windows.Forms.Label
$adminLabel.Text = if (Test-IsAdmin) { "ADMIN MODE" } else { "STANDARD MODE" }
$adminLabel.ForeColor = if (Test-IsAdmin) { [System.Drawing.Color]::LightGreen } else { [System.Drawing.Color]::Orange }
$adminLabel.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$adminLabel.AutoSize = $true
$adminLabel.Anchor = "Top,Right"
$adminLabel.Location = New-Object System.Drawing.Point(1110, 20)
$top.Controls.Add($adminLabel)

$adminBtn = New-Object System.Windows.Forms.Button
$adminBtn.Text = "Run as Admin"
$adminBtn.Size = New-Object System.Drawing.Size(145, 36)
$adminBtn.Location = New-Object System.Drawing.Point(1085, 45)
$adminBtn.Anchor = "Top,Right"
$adminBtn.FlatStyle = "Flat"
$adminBtn.FlatAppearance.BorderSize = 1
$adminBtn.FlatAppearance.BorderColor = $Theme.Accent
$adminBtn.BackColor = $Theme.Surface2
$adminBtn.ForeColor = $Theme.Text
$adminBtn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$adminBtn.UseMnemonic = $false
$adminBtn.Cursor = "Hand"
$adminBtn.Add_Click({ Relaunch-AsAdmin })
$top.Controls.Add($adminBtn)

# Sidebar title
$sideTitle = New-Object System.Windows.Forms.Label
$sideTitle.Text = "Command Center"
$sideTitle.ForeColor = $Theme.Text
$sideTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
$sideTitle.AutoSize = $true
$sideTitle.Location = New-Object System.Drawing.Point(24, 22)
$side.Controls.Add($sideTitle)

$sideSub = New-Object System.Windows.Forms.Label
$sideSub.Text = "Everything users need"
$sideSub.ForeColor = $Theme.Muted
$sideSub.Font = $FontSmall
$sideSub.AutoSize = $true
$sideSub.Location = New-Object System.Drawing.Point(26, 54)
$side.Controls.Add($sideSub)

# ==========================================================
# Page System
# ==========================================================

$script:Pages = @{}
$script:NavButtons = @{}
$script:CurrentPage = ""

function New-Page {
    param(
        [string]$Key,
        [string]$PageTitle,
        [string]$Description
    )

    $page = New-Object System.Windows.Forms.TableLayoutPanel
    $page.Dock = "Fill"
    $page.BackColor = $Theme.Bg
    $page.ColumnCount = 1
    $page.RowCount = 2
    $page.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 82))) | Out-Null
    $page.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
    $page.Visible = $false

    $header = New-Object System.Windows.Forms.Panel
    $header.Dock = "Fill"
    $header.BackColor = $Theme.Bg

    $h = New-Object System.Windows.Forms.Label
    $h.Text = $PageTitle
    $h.ForeColor = $Theme.Text
    $h.Font = $FontSection
    $h.AutoSize = $true
    $h.Location = New-Object System.Drawing.Point(26, 16)
    $header.Controls.Add($h)

    $d = New-Object System.Windows.Forms.Label
    $d.Text = $Description
    $d.ForeColor = $Theme.Muted
    $d.Font = $FontSmall
    $d.AutoSize = $true
    $d.Location = New-Object System.Drawing.Point(28, 48)
    $header.Controls.Add($d)

    $searchLabel = New-Object System.Windows.Forms.Label
    $searchLabel.Text = "Search"
    $searchLabel.ForeColor = $Theme.Muted
    $searchLabel.Font = $FontSmall
    $searchLabel.AutoSize = $true
    $searchLabel.Anchor = "Top,Right"
    $searchLabel.Location = New-Object System.Drawing.Point(680, 33)
    $header.Controls.Add($searchLabel)

    $search = New-Object System.Windows.Forms.TextBox
    $search.Size = New-Object System.Drawing.Size(310, 28)
    $search.Location = New-Object System.Drawing.Point(735, 29)
    $search.Anchor = "Top,Right"
    $search.BackColor = $Theme.Surface
    $search.ForeColor = $Theme.Text
    $search.BorderStyle = "FixedSingle"
    $search.Font = $FontRegular
    $search.Tag = "SearchBox"
    $header.Controls.Add($search)

    $body = New-Object System.Windows.Forms.FlowLayoutPanel
    $body.Dock = "Fill"
    $body.AutoScroll = $true
    $body.WrapContents = $true
    $body.FlowDirection = "LeftToRight"
    $body.Padding = New-Object System.Windows.Forms.Padding(18, 10, 18, 24)
    $body.BackColor = $Theme.Bg

    $page.Controls.Add($header, 0, 0)
    $page.Controls.Add($body, 0, 1)
    $mainHost.Controls.Add($page)

    $search.Add_TextChanged({
        $q = $this.Text.Trim().ToLowerInvariant()
        foreach ($ctrl in $body.Controls) {
            if ($ctrl -is [System.Windows.Forms.Button]) {
                $hay = ($ctrl.Text + " " + [string]$ctrl.Tag).ToLowerInvariant()
                $ctrl.Visible = ([string]::IsNullOrWhiteSpace($q) -or $hay.Contains($q))
            } elseif ($ctrl -is [System.Windows.Forms.Panel]) {
                $hay = ([string]$ctrl.Tag).ToLowerInvariant()
                $ctrl.Visible = ([string]::IsNullOrWhiteSpace($q) -or $hay.Contains($q))
            }
        }
    }.GetNewClosure())

    $script:Pages[$Key] = @{
        Page = $page
        Body = $body
        Search = $search
    }

    return $script:Pages[$Key]
}

function Show-Page {
    param([string]$Key)

    foreach ($k in $script:Pages.Keys) {
        $script:Pages[$k].Page.Visible = $false
    }

    foreach ($k in $script:NavButtons.Keys) {
        $script:NavButtons[$k].BackColor = $Theme.Sidebar
        $script:NavButtons[$k].ForeColor = $Theme.Muted
    }

    $script:Pages[$Key].Page.Visible = $true
    $script:Pages[$Key].Page.BringToFront()

    if ($script:NavButtons.ContainsKey($Key)) {
        $script:NavButtons[$Key].BackColor = $Theme.Accent
        $script:NavButtons[$Key].ForeColor = [System.Drawing.Color]::White
    }

    $script:CurrentPage = $Key
}

function Add-Nav {
    param([string]$Key, [string]$Text, [int]$Top)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Size = New-Object System.Drawing.Size(205, 42)
    $btn.Location = New-Object System.Drawing.Point(22, $Top)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $Theme.Sidebar
    $btn.ForeColor = $Theme.Muted
    $btn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5)
    $btn.TextAlign = "MiddleLeft"
    $btn.Padding = New-Object System.Windows.Forms.Padding(16, 0, 0, 0)
    $btn.UseMnemonic = $false
    $btn.Cursor = "Hand"
    $btn.Add_Click({ Show-Page $Key }.GetNewClosure())
    $side.Controls.Add($btn)
    $script:NavButtons[$Key] = $btn
}

function Add-Card {
    param(
        [hashtable]$Page,
        [string]$Title,
        [string]$Sub,
        [string]$Tags,
        [scriptblock]$Action,
        [string]$Kind = "Normal"
    )

    $btn = New-Object System.Windows.Forms.Button
    $btn.Width = 222
    $btn.Height = 112
    $btn.Margin = New-Object System.Windows.Forms.Padding(8)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = $Theme.Border
    $btn.BackColor = switch ($Kind) {
        "Success" { $Theme.Success }
        "Warning" { $Theme.Warning }
        "Danger"  { $Theme.Danger }
        "Accent"  { $Theme.Accent }
        default   { $Theme.Card }
    }
    $btn.ForeColor = $Theme.Text
    $btn.Font = $FontCard
    $btn.TextAlign = "TopLeft"
    $btn.Padding = New-Object System.Windows.Forms.Padding(14, 13, 10, 10)
    $btn.Text = "$Title`r`n$Sub"
    $btn.Tag = "$Title $Sub $Tags"
    $btn.UseMnemonic = $false
    $btn.Cursor = "Hand"

    $normal = $btn.BackColor
    $btn.Add_MouseEnter({ $this.BackColor = $Theme.CardHover })
    $btn.Add_MouseLeave({ $this.BackColor = $normal }.GetNewClosure())
    $btn.Add_Click($Action)

    $Page.Body.Controls.Add($btn)
}

function Add-WidePanel {
    param(
        [hashtable]$Page,
        [string]$Title,
        [string]$Body,
        [string]$Tags = "panel",
        [int]$Width = 704,
        [int]$Height = 132
    )

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Width = $Width
    $panel.Height = $Height
    $panel.Margin = New-Object System.Windows.Forms.Padding(8)
    $panel.BackColor = $Theme.Surface
    $panel.Tag = "$Title $Body $Tags"

    $bar = New-Object System.Windows.Forms.Panel
    $bar.Width = 5
    $bar.Height = $Height
    $bar.Location = New-Object System.Drawing.Point(0, 0)
    $bar.BackColor = $Theme.Accent
    $panel.Controls.Add($bar)

    $t = New-Object System.Windows.Forms.Label
    $t.Text = $Title
    $t.ForeColor = $Theme.Text
    $t.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 12)
    $t.AutoSize = $true
    $t.Location = New-Object System.Drawing.Point(20, 16)
    $panel.Controls.Add($t)

    $b = New-Object System.Windows.Forms.Label
    $b.Text = $Body
    $b.ForeColor = $Theme.Muted
    $b.Font = $FontSmall
    $b.AutoSize = $false
    $b.Width = $Width - 42
    $b.Height = $Height - 54
    $b.Location = New-Object System.Drawing.Point(20, 50)
    $panel.Controls.Add($b)

    $Page.Body.Controls.Add($panel)
}

# ==========================================================
# Pages
# ==========================================================

$dashboard = New-Page "Dashboard" "Dashboard" "Quick actions for normal users and IT support."
$windows   = New-Page "Windows" "Windows Tools" "Classic applets, MMC consoles, settings pages, and user support shortcuts."
$network   = New-Page "Network" "Network Center" "Connectivity, adapters, DNS, Wi-Fi, proxy, and reset tools."
$repair    = New-Page "Repair" "Repair & Cleanup" "System repair, cleanup, restore, printers, and troubleshooting."
$apps      = New-Page "Apps" "Apps Installer" "Install common apps using Winget presets or custom package IDs."
$updates   = New-Page "Updates" "Updates Center" "Windows Update, Microsoft Store, Winget upgrades, and repair sources."
$security  = New-Page "Security" "Security Center" "Defender, Firewall, UAC, BitLocker, credentials, and scans."
$reports   = New-Page "Reports" "Reports & Documentation" "Generate reports for support tickets and handover documentation."
$commands  = New-Page "Commands" "Command Library" "Copy or run the most useful Windows support commands."

Add-Nav "Dashboard" "Dashboard" 96
Add-Nav "Windows" "Windows Tools" 144
Add-Nav "Network" "Network Center" 192
Add-Nav "Repair" "Repair & Cleanup" 240
Add-Nav "Apps" "Apps Installer" 288
Add-Nav "Updates" "Updates Center" 336
Add-Nav "Security" "Security Center" 384
Add-Nav "Reports" "Reports" 432
Add-Nav "Commands" "Command Library" 480

# Sidebar bottom buttons
$about = New-Object System.Windows.Forms.Button
$about.Text = "About AlhamraniHub Pro"
$about.Size = New-Object System.Drawing.Size(205, 36)
$about.Location = New-Object System.Drawing.Point(22, 650)
$about.Anchor = "Left,Bottom"
$about.FlatStyle = "Flat"
$about.FlatAppearance.BorderSize = 1
$about.FlatAppearance.BorderColor = $Theme.Border
$about.BackColor = $Theme.Surface
$about.ForeColor = $Theme.Muted
$about.Font = $FontSmall
$about.UseMnemonic = $false
$about.Cursor = "Hand"
$about.Add_Click({
    Show-Message "AlhamraniHub Pro`nProfessional Windows Support Center`n`nBuilt with PowerShell Windows Forms.`nApps and updates use Winget.`nUse Admin Mode for repair and system changes." "About AlhamraniHub Pro"
})
$side.Controls.Add($about)

# ==========================================================
# Dashboard
# ==========================================================

Add-WidePanel $dashboard "Welcome to AlhamraniHub Pro" "A clear Windows support hub for everyday users and IT teams. Use it for Control Panel shortcuts, network troubleshooting, app installation, Windows updates, security tasks, and reports." "welcome dashboard" 704 132
Add-Card $dashboard "Network Connections" "Open ncpa.cpl" "ncpa adapters ethernet wifi" { Start-Tool "ncpa.cpl" } "Accent"
Add-Card $dashboard "Control Panel" "Classic Windows tools" "control panel" { Start-Tool "control.exe" }
Add-Card $dashboard "Windows Update" "Open update settings" "windows update settings" { Open-Target "ms-settings:windowsupdate" } "Accent"
Add-Card $dashboard "Install Essentials" "Chrome, 7-Zip, VS Code..." "winget apps install essentials" {
    Run-Winget-Install @("Google.Chrome","7zip.7zip","Notepad++.Notepad++","Microsoft.VisualStudioCode","VideoLAN.VLC","Adobe.Acrobat.Reader.64-bit","Microsoft.PowerToys")
} "Success"
Add-Card $dashboard "Upgrade All Apps" "winget upgrade --all" "winget upgrade apps update" {
    Start-PowerShellCommand "winget upgrade --all --accept-source-agreements --accept-package-agreements" -AsAdmin -ConfirmMessage "Upgrade all available Winget apps?"
} "Success"
Add-Card $dashboard "Device Manager" "Drivers and devices" "devmgmt devices drivers" { Start-Tool "devmgmt.msc" }
Add-Card $dashboard "Flush DNS" "Clear DNS cache" "dns ipconfig flushdns" { Start-Cmd "ipconfig /flushdns" }
Add-Card $dashboard "DISM + SFC" "Repair Windows files" "dism sfc repair" {
    Start-PowerShellCommand "DISM /Online /Cleanup-Image /RestoreHealth; sfc /scannow" -AsAdmin -ConfirmMessage "Run DISM and SFC repair? This may take time."
} "Warning"
Add-Card $dashboard "Quick Assist" "Remote support" "remote support quick assist" { Start-Tool "quickassist.exe" }
Add-Card $dashboard "System Report" "Export to Desktop" "report documentation" {
    $out = Join-Path (Desktop-Path) "AlhamraniHub-Pro-System-Report.txt"
    $cmd = @"
`$out = "$out"
"=== AlhamraniHub Pro System Report ===" | Out-File `$out
"Generated: `$((Get-Date).ToString())" | Out-File `$out -Append
"" | Out-File `$out -Append
Get-ComputerInfo | Select-Object CsName, WindowsProductName, WindowsVersion, OsBuildNumber, CsManufacturer, CsModel, CsTotalPhysicalMemory | Format-List | Out-File `$out -Append
"" | Out-File `$out -Append
"=== Network Configuration ===" | Out-File `$out -Append
ipconfig /all | Out-File `$out -Append
notepad `$out
"@
    Start-PowerShellCommand $cmd
} "Accent"

# ==========================================================
# Windows Tools
# ==========================================================

Add-Card $windows "Control Panel" "control.exe" "control panel" { Start-Tool "control.exe" } "Accent"
Add-Card $windows "Network Connections" "ncpa.cpl" "network adapter ethernet wifi" { Start-Tool "ncpa.cpl" } "Accent"
Add-Card $windows "Programs & Features" "appwiz.cpl" "uninstall programs features" { Start-Tool "appwiz.cpl" }
Add-Card $windows "Power Options" "powercfg.cpl" "power battery sleep" { Start-Tool "powercfg.cpl" }
Add-Card $windows "Firewall" "firewall.cpl" "firewall defender" { Start-Tool "firewall.cpl" }
Add-Card $windows "Internet Options" "inetcpl.cpl" "proxy internet options" { Start-Tool "inetcpl.cpl" }
Add-Card $windows "System Properties" "sysdm.cpl" "system computer name domain" { Start-Tool "sysdm.cpl" }
Add-Card $windows "Advanced System" "Environment variables" "environment path variables" { Start-Tool "SystemPropertiesAdvanced.exe" }
Add-Card $windows "Sound" "mmsys.cpl" "audio speaker microphone" { Start-Tool "mmsys.cpl" }
Add-Card $windows "Date & Time" "timedate.cpl" "time date timezone" { Start-Tool "timedate.cpl" }
Add-Card $windows "Region" "intl.cpl" "region language locale" { Start-Tool "intl.cpl" }
Add-Card $windows "Mouse" "main.cpl" "mouse pointer settings" { Start-Tool "main.cpl" }
Add-Card $windows "Printers" "control printers" "printers scanners" { Start-Tool "control.exe" "printers" }
Add-Card $windows "Device Manager" "devmgmt.msc" "drivers devices" { Start-Tool "devmgmt.msc" }
Add-Card $windows "Services" "services.msc" "services startup" { Start-Tool "services.msc" }
Add-Card $windows "Disk Management" "diskmgmt.msc" "disk partition volume" { Start-Tool "diskmgmt.msc" }
Add-Card $windows "Computer Management" "compmgmt.msc" "computer management users disks" { Start-Tool "compmgmt.msc" }
Add-Card $windows "Event Viewer" "eventvwr.msc" "logs errors events" { Start-Tool "eventvwr.msc" }
Add-Card $windows "Task Scheduler" "taskschd.msc" "tasks scheduler" { Start-Tool "taskschd.msc" }
Add-Card $windows "Local Users" "lusrmgr.msc" "users groups local" { Start-Tool "lusrmgr.msc" }
Add-Card $windows "Group Policy" "gpedit.msc" "policy gpedit" { Start-Tool "gpedit.msc" }
Add-Card $windows "Registry Editor" "regedit.exe" "registry regedit" {
    Start-Tool "regedit.exe" -ConfirmMessage "Registry Editor can damage Windows if used incorrectly. Continue?"
} "Danger"
Add-Card $windows "MSConfig" "msconfig.exe" "startup boot services" { Start-Tool "msconfig.exe" }
Add-Card $windows "Windows Tools" "Administrative tools" "admin tools" { Start-Tool "control.exe" "admintools" }
Add-Card $windows "Task Manager" "taskmgr.exe" "task manager processes" { Start-Tool "taskmgr.exe" }
Add-Card $windows "Resource Monitor" "resmon.exe" "resource cpu disk memory network" { Start-Tool "resmon.exe" }
Add-Card $windows "Performance Monitor" "perfmon.exe" "performance monitor" { Start-Tool "perfmon.exe" }
Add-Card $windows "Reliability Monitor" "perfmon /rel" "reliability crashes errors" { Start-Tool "perfmon.exe" "/rel" }
Add-Card $windows "System Information" "msinfo32.exe" "system info hardware" { Start-Tool "msinfo32.exe" }
Add-Card $windows "Display Settings" "ms-settings:display" "display screen resolution" { Open-Target "ms-settings:display" }
Add-Card $windows "Bluetooth" "ms-settings:bluetooth" "bluetooth devices" { Open-Target "ms-settings:bluetooth" }
Add-Card $windows "Default Apps" "ms-settings:defaultapps" "default apps browser mail" { Open-Target "ms-settings:defaultapps" }

# ==========================================================
# Network
# ==========================================================

Add-Card $network "Network Connections" "ncpa.cpl" "network adapters" { Start-Tool "ncpa.cpl" } "Accent"
Add-Card $network "Network Status" "Settings page" "network status" { Open-Target "ms-settings:network-status" }
Add-Card $network "Wi-Fi Settings" "Settings page" "wifi wireless" { Open-Target "ms-settings:network-wifi" }
Add-Card $network "Proxy Settings" "Settings page" "proxy internet" { Open-Target "ms-settings:network-proxy" }
Add-Card $network "VPN Settings" "Settings page" "vpn network" { Open-Target "ms-settings:network-vpn" }
Add-Card $network "IP Config" "ipconfig /all" "ip dns gateway dhcp" { Start-Cmd "ipconfig /all" }
Add-Card $network "Flush DNS" "ipconfig /flushdns" "dns cache" { Start-Cmd "ipconfig /flushdns" } "Accent"
Add-Card $network "Ping 1.1.1.1" "Continuous test" "ping internet cloudflare" { Start-Cmd "ping 1.1.1.1 -t" }
Add-Card $network "Ping 8.8.8.8" "Continuous test" "ping google dns" { Start-Cmd "ping 8.8.8.8 -t" }
Add-Card $network "Trace Route" "tracert 8.8.8.8" "tracert route latency" { Start-Cmd "tracert 8.8.8.8" }
Add-Card $network "DNS Lookup" "nslookup google.com" "nslookup dns" { Start-Cmd "nslookup google.com" }
Add-Card $network "Wi-Fi Profiles" "Show saved profiles" "wifi wlan profiles" { Start-Cmd "netsh wlan show profiles" }
Add-Card $network "Wi-Fi Password Tip" "Show command format" "wifi password key clear" {
    Show-Message "Use this command after getting the Wi-Fi profile name:`n`nnetsh wlan show profile name=""WiFiName"" key=clear" "Wi-Fi Password Command"
}
Add-Card $network "Release/Renew IP" "Refresh DHCP" "release renew dhcp ip" {
    Start-Cmd "ipconfig /release & ipconfig /renew" -AsAdmin -ConfirmMessage "This may temporarily disconnect the network. Continue?"
} "Warning"
Add-Card $network "Winsock Reset" "Reset network stack" "winsock reset ip reset" {
    Start-Cmd "netsh winsock reset & netsh int ip reset" -AsAdmin -ConfirmMessage "This resets network stack and may require restart. Continue?"
} "Danger"
Add-Card $network "Network Adapters" "PowerShell list" "get-netadapter" {
    Start-PowerShellCommand "Get-NetAdapter | Sort-Object Status, Name | Format-Table -AutoSize"
}
Add-Card $network "Public IP" "Open browser check" "public ip" { Open-Target "https://ifconfig.me" }
Add-Card $network "Firewall" "firewall.cpl" "firewall network" { Start-Tool "firewall.cpl" }

# ==========================================================
# Repair
# ==========================================================

Add-Card $repair "Create Restore Point" "Before changes" "checkpoint restore point" {
    Start-PowerShellCommand "Checkpoint-Computer -Description 'AlhamraniHub Pro Restore Point' -RestorePointType 'MODIFY_SETTINGS'; Write-Host 'Restore point request completed.'" -AsAdmin -ConfirmMessage "Create a system restore point?"
} "Success"
Add-Card $repair "SFC Scan" "sfc /scannow" "sfc repair" {
    Start-PowerShellCommand "sfc /scannow" -AsAdmin -ConfirmMessage "Run SFC scan?"
} "Warning"
Add-Card $repair "DISM RestoreHealth" "Repair Windows image" "dism restorehealth" {
    Start-PowerShellCommand "DISM /Online /Cleanup-Image /RestoreHealth" -AsAdmin -ConfirmMessage "Run DISM RestoreHealth?"
} "Warning"
Add-Card $repair "DISM + SFC" "Full repair sequence" "dism sfc repair" {
    Start-PowerShellCommand "DISM /Online /Cleanup-Image /RestoreHealth; sfc /scannow" -AsAdmin -ConfirmMessage "Run DISM and SFC?"
} "Warning"
Add-Card $repair "Disk Cleanup" "cleanmgr.exe" "disk cleanup" { Start-Tool "cleanmgr.exe" }
Add-Card $repair "Storage Sense" "Settings page" "storage cleanup" { Open-Target "ms-settings:storagesense" }
Add-Card $repair "Clean Temp Files" "User + Windows temp" "temp cleanup" {
    $cmd = @"
Write-Host 'Cleaning user temp...'
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Cleaning Windows temp...'
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Done.'
"@
    Start-PowerShellCommand $cmd -AsAdmin -ConfirmMessage "Delete temporary files?"
} "Warning"
Add-Card $repair "Clear Print Queue" "Restart spooler" "printer spooler queue" {
    $cmd = @"
Stop-Service Spooler -Force
Remove-Item "C:\Windows\System32\spool\PRINTERS\*" -Force -ErrorAction SilentlyContinue
Start-Service Spooler
Write-Host 'Print queue cleared.'
"@
    Start-PowerShellCommand $cmd -AsAdmin -ConfirmMessage "Clear print queue and restart Print Spooler?"
} "Warning"
Add-Card $repair "Troubleshooters" "Control panel page" "troubleshooting" { Start-Tool "control.exe" "/name Microsoft.Troubleshooting" }
Add-Card $repair "System Restore" "rstrui.exe" "system restore" { Start-Tool "rstrui.exe" -AsAdmin }
Add-Card $repair "Recovery" "Advanced startup" "recovery startup repair" { Open-Target "ms-settings:recovery" }
Add-Card $repair "CHKDSK Tip" "Show command" "chkdsk disk repair" {
    Show-Message "Admin CMD command:`n`nchkdsk C: /f /r`n`nUse carefully. It may take a long time and may require reboot." "CHKDSK"
}
Add-Card $repair "Restart Explorer" "Fix taskbar/shell" "explorer restart shell" {
    Start-PowerShellCommand "Stop-Process -Name explorer -Force; Start-Process explorer.exe" -ConfirmMessage "Restart Windows Explorer?"
}

# ==========================================================
# Apps Installer custom page
# ==========================================================

# Hide default FlowLayout cards on Apps and create pro app installer UI inside body
$appBody = $apps.Body
$appBody.WrapContents = $false
$appBody.FlowDirection = "TopDown"

$appsPanel = New-Object System.Windows.Forms.Panel
$appsPanel.Width = 980
$appsPanel.Height = 610
$appsPanel.Margin = New-Object System.Windows.Forms.Padding(8)
$appsPanel.BackColor = $Theme.Bg
$appsPanel.Tag = "apps installer winget presets software install"
$appBody.Controls.Add($appsPanel)

$appList = New-Object System.Windows.Forms.CheckedListBox
$appList.Location = New-Object System.Drawing.Point(10, 10)
$appList.Size = New-Object System.Drawing.Size(390, 560)
$appList.BackColor = $Theme.Surface
$appList.ForeColor = $Theme.Text
$appList.Font = $FontRegular
$appList.BorderStyle = "FixedSingle"
$appList.CheckOnClick = $true
$appsPanel.Controls.Add($appList)

$script:AppCatalog = [ordered]@{
    "Google Chrome" = "Google.Chrome"
    "Mozilla Firefox" = "Mozilla.Firefox"
    "Brave Browser" = "Brave.Brave"
    "Opera Browser" = "Opera.Opera"
    "Microsoft Edge" = "Microsoft.Edge"
    "7-Zip" = "7zip.7zip"
    "WinRAR" = "RARLab.WinRAR"
    "Notepad++" = "Notepad++.Notepad++"
    "Visual Studio Code" = "Microsoft.VisualStudioCode"
    "Git" = "Git.Git"
    "GitHub Desktop" = "GitHub.GitHubDesktop"
    "Microsoft PowerToys" = "Microsoft.PowerToys"
    "Everything Search" = "voidtools.Everything"
    "VLC Media Player" = "VideoLAN.VLC"
    "Adobe Acrobat Reader" = "Adobe.Acrobat.Reader.64-bit"
    "Zoom" = "Zoom.Zoom"
    "Microsoft Teams" = "Microsoft.Teams"
    "AnyDesk" = "AnyDeskSoftwareGmbH.AnyDesk"
    "TeamViewer" = "TeamViewer.TeamViewer"
    "RustDesk" = "RustDesk.RustDesk"
    "OBS Studio" = "OBSProject.OBSStudio"
    "Discord" = "Discord.Discord"
    "Slack" = "SlackTechnologies.Slack"
    "Postman" = "Postman.Postman"
    "Python 3.12" = "Python.Python.3.12"
    "Node.js LTS" = "OpenJS.NodeJS.LTS"
    "Docker Desktop" = "Docker.DockerDesktop"
    "Microsoft OneDrive" = "Microsoft.OneDrive"
}

foreach ($name in $script:AppCatalog.Keys) { [void]$appList.Items.Add($name) }

function Set-AppSelection {
    param([string[]]$Names)
    for ($i = 0; $i -lt $appList.Items.Count; $i++) {
        $item = [string]$appList.Items[$i]
        $appList.SetItemChecked($i, ($Names -contains $item))
    }
}

function Install-CheckedApps {
    $ids = @()
    foreach ($item in $appList.CheckedItems) {
        $id = $script:AppCatalog[[string]$item]
        if ($id) { $ids += $id }
    }
    Run-Winget-Install $ids
}

function New-AppButton {
    param([string]$Text, [int]$X, [int]$Y, [scriptblock]$Action, [string]$Kind = "Normal")
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Size = New-Object System.Drawing.Size(220, 44)
    $b.Location = New-Object System.Drawing.Point($X, $Y)
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 1
    $b.FlatAppearance.BorderColor = $Theme.Border
    $b.BackColor = switch ($Kind) {
        "Success" { $Theme.Success }
        "Warning" { $Theme.Warning }
        "Accent"  { $Theme.Accent }
        default   { $Theme.Surface2 }
    }
    $b.ForeColor = $Theme.Text
    $b.Font = $FontCard
    $b.UseMnemonic = $false
    $b.Cursor = "Hand"
    $b.Add_Click($Action)
    $appsPanel.Controls.Add($b)
}

$appHeading = New-Object System.Windows.Forms.Label
$appHeading.Text = "Software Presets"
$appHeading.ForeColor = $Theme.Text
$appHeading.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 15)
$appHeading.AutoSize = $true
$appHeading.Location = New-Object System.Drawing.Point(430, 18)
$appsPanel.Controls.Add($appHeading)

$appText = New-Object System.Windows.Forms.Label
$appText.Text = "Choose a preset or manually select apps from the list. Installation opens in a PowerShell window so you can monitor progress."
$appText.ForeColor = $Theme.Muted
$appText.Font = $FontSmall
$appText.AutoSize = $false
$appText.Width = 500
$appText.Height = 48
$appText.Location = New-Object System.Drawing.Point(432, 52)
$appsPanel.Controls.Add($appText)

New-AppButton "Essential Pack" 430 115 {
    Set-AppSelection @("Google Chrome","7-Zip","Notepad++","Visual Studio Code","VLC Media Player","Adobe Acrobat Reader","Microsoft PowerToys","Everything Search")
} "Success"

New-AppButton "IT Support Pack" 670 115 {
    Set-AppSelection @("Google Chrome","7-Zip","Notepad++","Visual Studio Code","Git","Microsoft PowerToys","Everything Search","AnyDesk","TeamViewer","RustDesk","VLC Media Player")
} "Success"

New-AppButton "Office User Pack" 430 172 {
    Set-AppSelection @("Google Chrome","Mozilla Firefox","7-Zip","Adobe Acrobat Reader","Zoom","Microsoft Teams","VLC Media Player","Microsoft OneDrive")
} "Success"

New-AppButton "Developer Pack" 670 172 {
    Set-AppSelection @("Visual Studio Code","Git","GitHub Desktop","Postman","Python 3.12","Node.js LTS","Docker Desktop")
} "Success"

New-AppButton "Remote Support Pack" 430 229 {
    Set-AppSelection @("AnyDesk","TeamViewer","RustDesk","Zoom","Microsoft Teams")
} "Success"

New-AppButton "Clear Selection" 670 229 {
    for ($i = 0; $i -lt $appList.Items.Count; $i++) { $appList.SetItemChecked($i, $false) }
}

New-AppButton "Install Selected" 430 300 { Install-CheckedApps } "Accent"
New-AppButton "List Installed Apps" 670 300 { Start-PowerShellCommand "winget list" }
New-AppButton "Check App Updates" 430 357 { Start-PowerShellCommand "winget upgrade" }
New-AppButton "Upgrade All Apps" 670 357 {
    Start-PowerShellCommand "winget upgrade --all --accept-source-agreements --accept-package-agreements" -AsAdmin -ConfirmMessage "Upgrade all available Winget apps?"
} "Warning"
New-AppButton "Open Apps Settings" 430 414 { Open-Target "ms-settings:appsfeatures" }
New-AppButton "Default Apps" 670 414 { Open-Target "ms-settings:defaultapps" }

$customLabel = New-Object System.Windows.Forms.Label
$customLabel.Text = "Install custom Winget package ID"
$customLabel.ForeColor = $Theme.Text
$customLabel.Font = $FontCard
$customLabel.AutoSize = $true
$customLabel.Location = New-Object System.Drawing.Point(430, 496)
$appsPanel.Controls.Add($customLabel)

$customBox = New-Object System.Windows.Forms.TextBox
$customBox.Text = "Google.Chrome"
$customBox.Size = New-Object System.Drawing.Size(300, 28)
$customBox.Location = New-Object System.Drawing.Point(430, 526)
$customBox.BackColor = $Theme.Surface
$customBox.ForeColor = $Theme.Text
$customBox.BorderStyle = "FixedSingle"
$customBox.Font = $FontRegular
$appsPanel.Controls.Add($customBox)

New-AppButton "Install Custom ID" 745 521 {
    $id = $customBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($id)) {
        Show-Message "Enter a Winget package ID first." "Custom Install"
        return
    }
    Run-Winget-Install @($id)
} "Accent"

# ==========================================================
# Updates
# ==========================================================

Add-Card $updates "Windows Update" "Open settings" "windows update" { Open-Target "ms-settings:windowsupdate" } "Accent"
Add-Card $updates "Advanced Update" "Update options" "advanced update" { Open-Target "ms-settings:windowsupdate-options" }
Add-Card $updates "Update History" "View history" "update history" { Open-Target "ms-settings:windowsupdate-history" }
Add-Card $updates "Delivery Optimization" "Bandwidth settings" "delivery optimization" { Open-Target "ms-settings:delivery-optimization" }
Add-Card $updates "Check Winget Updates" "winget upgrade" "winget update apps" { Start-PowerShellCommand "winget upgrade" }
Add-Card $updates "Upgrade All Apps" "winget upgrade --all" "upgrade apps" {
    Start-PowerShellCommand "winget upgrade --all --accept-source-agreements --accept-package-agreements" -AsAdmin -ConfirmMessage "Upgrade all Winget apps?"
} "Success"
Add-Card $updates "Update Winget Sources" "source update" "winget source update" { Start-PowerShellCommand "winget source update" -AsAdmin }
Add-Card $updates "Reset Winget Sources" "Repair Winget source" "winget reset source" {
    Start-PowerShellCommand "winget source reset --force; winget source update" -AsAdmin -ConfirmMessage "Reset Winget sources?"
} "Warning"
Add-Card $updates "Microsoft Store" "Downloads & updates" "store updates" { Open-Target "ms-windows-store://downloadsandupdates" }
Add-Card $updates "Windows Version" "winver.exe" "version build" { Start-Tool "winver.exe" }

# ==========================================================
# Security
# ==========================================================

Add-Card $security "Windows Security" "Open dashboard" "defender security" { Open-Target "windowsdefender:" } "Accent"
Add-Card $security "Virus Protection" "Threat page" "virus threat defender" { Open-Target "windowsdefender://threat" }
Add-Card $security "Firewall" "firewall.cpl" "firewall" { Start-Tool "firewall.cpl" }
Add-Card $security "Advanced Firewall" "wf.msc" "firewall rules" { Start-Tool "wf.msc" }
Add-Card $security "UAC Settings" "User Account Control" "uac" { Start-Tool "UserAccountControlSettings.exe" }
Add-Card $security "BitLocker" "Drive encryption" "bitlocker encryption" { Start-Tool "control.exe" "/name Microsoft.BitLockerDriveEncryption" }
Add-Card $security "Credential Manager" "Saved credentials" "credentials password" { Start-Tool "control.exe" "/name Microsoft.CredentialManager" }
Add-Card $security "Local Security Policy" "secpol.msc" "security policy" { Start-Tool "secpol.msc" }
Add-Card $security "Defender Quick Scan" "Start-MpScan" "defender quick scan" {
    Start-PowerShellCommand "Start-MpScan -ScanType QuickScan" -AsAdmin -ConfirmMessage "Start Defender Quick Scan?"
} "Success"
Add-Card $security "Defender Full Scan" "Full system scan" "defender full scan" {
    Start-PowerShellCommand "Start-MpScan -ScanType FullScan" -AsAdmin -ConfirmMessage "Start Defender Full Scan?"
} "Warning"
Add-Card $security "Defender Update" "Update signatures" "defender signatures" { Start-PowerShellCommand "Update-MpSignature" -AsAdmin }
Add-Card $security "Hosts File" "Open as Admin" "hosts dns" {
    Start-Tool "notepad.exe" "$env:windir\System32\drivers\etc\hosts" -AsAdmin -ConfirmMessage "Open hosts file as Administrator?"
} "Warning"

# ==========================================================
# Reports
# ==========================================================

Add-Card $reports "System Report" "Computer + IP info" "system report" {
    $out = Join-Path (Desktop-Path) "AlhamraniHub-Pro-System-Report.txt"
    $cmd = @"
`$out = "$out"
"=== AlhamraniHub Pro System Report ===" | Out-File `$out
"Generated: `$((Get-Date).ToString())" | Out-File `$out -Append
"" | Out-File `$out -Append
Get-ComputerInfo | Select-Object CsName, WindowsProductName, WindowsVersion, OsBuildNumber, CsManufacturer, CsModel, CsTotalPhysicalMemory | Format-List | Out-File `$out -Append
"" | Out-File `$out -Append
"=== Network Configuration ===" | Out-File `$out -Append
ipconfig /all | Out-File `$out -Append
notepad `$out
"@
    Start-PowerShellCommand $cmd
} "Success"
Add-Card $reports "Battery Report" "HTML report" "battery report" {
    $out = Join-Path (Desktop-Path) "AlhamraniHub-Pro-Battery-Report.html"
    Start-Cmd "powercfg /batteryreport /output `"$out`" & start `"$out`""
}
Add-Card $reports "Wi-Fi Report" "wlan report" "wifi report wlan" { Start-Cmd "netsh wlan show wlanreport" }
Add-Card $reports "DxDiag Report" "Hardware diagnostics" "dxdiag hardware" {
    $out = Join-Path (Desktop-Path) "AlhamraniHub-Pro-DxDiag.txt"
    Start-Cmd "dxdiag /t `"$out`" & notepad `"$out`""
}
Add-Card $reports "Installed Apps" "winget list export" "installed apps list" {
    $out = Join-Path (Desktop-Path) "AlhamraniHub-Pro-Installed-Apps.txt"
    Start-PowerShellCommand "winget list | Out-File `"$out`"; notepad `"$out`""
}
Add-Card $reports "Recent System Errors" "Last 50 errors" "event logs errors" {
    $out = Join-Path (Desktop-Path) "AlhamraniHub-Pro-Recent-System-Errors.txt"
    $cmd = "Get-WinEvent -LogName System -MaxEvents 300 | Where-Object { `$_.LevelDisplayName -eq 'Error' } | Select-Object -First 50 TimeCreated, ProviderName, Id, Message | Format-List | Out-File `"$out`"; notepad `"$out`""
    Start-PowerShellCommand $cmd
}
Add-Card $reports "Export Drivers" "Backup drivers" "drivers export pnputil" {
    $out = Join-Path (Desktop-Path) "AlhamraniHub-Pro-Drivers"
    Start-PowerShellCommand "New-Item -ItemType Directory -Path `"$out`" -Force | Out-Null; pnputil /export-driver * `"$out`"; explorer `"$out`"" -AsAdmin -ConfirmMessage "Export installed drivers to Desktop?"
} "Success"

# ==========================================================
# Commands
# ==========================================================

Add-Card $commands "Copy ncpa.cpl" "Network Connections" "copy command" { Copy-Text "ncpa.cpl" }
Add-Card $commands "Copy appwiz.cpl" "Programs & Features" "copy command" { Copy-Text "appwiz.cpl" }
Add-Card $commands "Copy devmgmt.msc" "Device Manager" "copy command" { Copy-Text "devmgmt.msc" }
Add-Card $commands "Copy services.msc" "Services" "copy command" { Copy-Text "services.msc" }
Add-Card $commands "Copy diskmgmt.msc" "Disk Management" "copy command" { Copy-Text "diskmgmt.msc" }
Add-Card $commands "Copy eventvwr.msc" "Event Viewer" "copy command" { Copy-Text "eventvwr.msc" }
Add-Card $commands "Copy gpedit.msc" "Group Policy" "copy command" { Copy-Text "gpedit.msc" }
Add-Card $commands "Copy sysdm.cpl" "System Properties" "copy command" { Copy-Text "sysdm.cpl" }
Add-Card $commands "Copy Flush DNS" "ipconfig /flushdns" "copy command" { Copy-Text "ipconfig /flushdns" }
Add-Card $commands "Copy DISM" "RestoreHealth" "copy command" { Copy-Text "DISM /Online /Cleanup-Image /RestoreHealth" }
Add-Card $commands "Copy SFC" "sfc /scannow" "copy command" { Copy-Text "sfc /scannow" }
Add-Card $commands "Copy Winget Update" "Upgrade all apps" "copy command" { Copy-Text "winget upgrade --all --accept-source-agreements --accept-package-agreements" }
Add-Card $commands "Open CMD" "Command Prompt" "cmd terminal" { Start-Tool "cmd.exe" }
Add-Card $commands "Open PowerShell" "PowerShell" "powershell terminal" { Start-Tool "powershell.exe" }
Add-Card $commands "PowerShell Admin" "Elevated shell" "admin powershell" { Start-Tool "powershell.exe" -AsAdmin } "Accent"

# ==========================================================
# Keyboard Shortcuts
# ==========================================================

$form.Add_KeyDown({
    if ($_.Control -and $_.KeyCode -eq "F") {
        if ($script:CurrentPage -and $script:Pages.ContainsKey($script:CurrentPage)) {
            $script:Pages[$script:CurrentPage].Search.Focus()
            $script:Pages[$script:CurrentPage].Search.SelectAll()
        }
    }

    if ($_.KeyCode -eq "Escape") {
        if ($script:CurrentPage -and $script:Pages.ContainsKey($script:CurrentPage)) {
            $script:Pages[$script:CurrentPage].Search.Text = ""
        }
    }
})

Show-Page "Dashboard"
[void]$form.ShowDialog()
