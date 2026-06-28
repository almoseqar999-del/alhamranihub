#requires -version 5.1
<#
AlhamraniHub UI v2
Dark package-manager style support hub inspired by modern Windows utility tools.

Run:
  Run-AlhamraniHub-UIv2.cmd
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
        [string]$Title = "AlhamraniHub UI v2",
        [string]$Icon = "Information"
    )
    [System.Windows.Forms.MessageBox]::Show($Message, $Title, "OK", $Icon) | Out-Null
}

function Confirm-Action {
    param(
        [string]$Message,
        [string]$Title = "Confirm Action"
    )
    return ([System.Windows.Forms.MessageBox]::Show($Message, $Title, "YesNo", "Warning") -eq "Yes")
}

function Start-Tool {
    param(
        [Parameter(Mandatory=$true)][string]$Command,
        [string]$Arguments = "",
        [switch]$AsAdmin
    )
    try {
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
        Show-Message "Unable to start:`n$Command $Arguments`n`n$($_.Exception.Message)" "Error" "Error"
    }
}

function Start-PowerShellCommand {
    param(
        [Parameter(Mandatory=$true)][string]$CommandText,
        [switch]$AsAdmin
    )
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($CommandText))
    Start-Tool -Command "powershell.exe" -Arguments "-NoExit -NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded" -AsAdmin:$AsAdmin
}

function Open-Target {
    param([Parameter(Mandatory=$true)][string]$Target)
    try { Start-Process $Target } catch { Show-Message "Unable to open:`n$Target" "Error" "Error" }
}

function Relaunch-AsAdmin {
    if (-not $PSCommandPath) {
        Show-Message "Save the script as a .ps1 file, then run it as Admin."
        return
    }
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
}

# ==========================================================
# Theme
# ==========================================================
$Theme = @{
    Bg        = [System.Drawing.Color]::FromArgb(29, 34, 39)
    Bg2       = [System.Drawing.Color]::FromArgb(33, 38, 44)
    Top       = [System.Drawing.Color]::FromArgb(38, 43, 49)
    Panel     = [System.Drawing.Color]::FromArgb(34, 39, 45)
    Panel2    = [System.Drawing.Color]::FromArgb(39, 45, 52)
    Card      = [System.Drawing.Color]::FromArgb(41, 47, 54)
    Border    = [System.Drawing.Color]::FromArgb(76, 95, 112)
    Border2   = [System.Drawing.Color]::FromArgb(87, 112, 136)
    Button    = [System.Drawing.Color]::FromArgb(42, 70, 95)
    Hover     = [System.Drawing.Color]::FromArgb(56, 91, 123)
    Active    = [System.Drawing.Color]::FromArgb(67, 117, 179)
    Accent    = [System.Drawing.Color]::FromArgb(95, 207, 119)
    White     = [System.Drawing.Color]::FromArgb(242, 245, 248)
    Muted     = [System.Drawing.Color]::FromArgb(180, 192, 204)
    Danger    = [System.Drawing.Color]::FromArgb(154, 75, 78)
}

$FontTitle = New-Object System.Drawing.Font("Segoe UI Semibold", 12)
$FontHead  = New-Object System.Drawing.Font("Consolas", 11)
$FontBody  = New-Object System.Drawing.Font("Segoe UI", 9)
$FontBold  = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
$FontMini  = New-Object System.Drawing.Font("Segoe UI", 8)

# ==========================================================
# App Catalog
# display name => winget id + chocolatey id
# ==========================================================
$script:Catalog = @(
    @{ Category="Browsers"; Name="Google Chrome"; Winget="Google.Chrome"; Choco="googlechrome" },
    @{ Category="Browsers"; Name="Mozilla Firefox"; Winget="Mozilla.Firefox"; Choco="firefox" },
    @{ Category="Browsers"; Name="Brave"; Winget="Brave.Brave"; Choco="brave" },
    @{ Category="Browsers"; Name="Microsoft Edge"; Winget="Microsoft.Edge"; Choco="microsoft-edge" },
    @{ Category="Browsers"; Name="Opera"; Winget="Opera.Opera"; Choco="opera" },
    @{ Category="Browsers"; Name="Vivaldi"; Winget="Vivaldi.Vivaldi"; Choco="vivaldi" },

    @{ Category="Communications"; Name="Zoom"; Winget="Zoom.Zoom"; Choco="zoom" },
    @{ Category="Communications"; Name="Microsoft Teams"; Winget="Microsoft.Teams"; Choco="microsoft-teams" },
    @{ Category="Communications"; Name="Discord"; Winget="Discord.Discord"; Choco="discord" },
    @{ Category="Communications"; Name="Telegram"; Winget="Telegram.TelegramDesktop"; Choco="telegram" },
    @{ Category="Communications"; Name="Slack"; Winget="SlackTechnologies.Slack"; Choco="slack" },
    @{ Category="Communications"; Name="Signal"; Winget="OpenWhisperSystems.Signal"; Choco="signal" },

    @{ Category="Development"; Name="Visual Studio Code"; Winget="Microsoft.VisualStudioCode"; Choco="vscode" },
    @{ Category="Development"; Name="Git"; Winget="Git.Git"; Choco="git" },
    @{ Category="Development"; Name="GitHub Desktop"; Winget="GitHub.GitHubDesktop"; Choco="github-desktop" },
    @{ Category="Development"; Name="Postman"; Winget="Postman.Postman"; Choco="postman" },
    @{ Category="Development"; Name="Python 3.12"; Winget="Python.Python.3.12"; Choco="python" },
    @{ Category="Development"; Name="Node.js LTS"; Winget="OpenJS.NodeJS.LTS"; Choco="nodejs-lts" },
    @{ Category="Development"; Name="Docker Desktop"; Winget="Docker.DockerDesktop"; Choco="docker-desktop" },
    @{ Category="Development"; Name="PowerShell 7"; Winget="Microsoft.PowerShell"; Choco="powershell-core" },

    @{ Category="Microsoft Tools"; Name="PowerToys"; Winget="Microsoft.PowerToys"; Choco="powertoys" },
    @{ Category="Microsoft Tools"; Name="Windows Terminal"; Winget="Microsoft.WindowsTerminal"; Choco="microsoft-windows-terminal" },
    @{ Category="Microsoft Tools"; Name=".NET Desktop Runtime 8"; Winget="Microsoft.DotNet.DesktopRuntime.8"; Choco="dotnet-8.0-runtime" },
    @{ Category="Microsoft Tools"; Name=".NET Desktop Runtime 9"; Winget="Microsoft.DotNet.DesktopRuntime.9"; Choco="dotnet-9.0-runtime" },
    @{ Category="Microsoft Tools"; Name="Sysinternals"; Winget="Microsoft.Sysinternals"; Choco="sysinternals" },
    @{ Category="Microsoft Tools"; Name="Process Explorer"; Winget="Microsoft.Sysinternals.ProcessExplorer"; Choco="procexp" },

    @{ Category="Multimedia"; Name="VLC"; Winget="VideoLAN.VLC"; Choco="vlc" },
    @{ Category="Multimedia"; Name="OBS Studio"; Winget="OBSProject.OBSStudio"; Choco="obs-studio" },
    @{ Category="Multimedia"; Name="Audacity"; Winget="Audacity.Audacity"; Choco="audacity" },
    @{ Category="Multimedia"; Name="HandBrake"; Winget="HandBrake.HandBrake"; Choco="handbrake" },
    @{ Category="Multimedia"; Name="Adobe Acrobat Reader"; Winget="Adobe.Acrobat.Reader.64-bit"; Choco="adobereader" },
    @{ Category="Multimedia"; Name="GIMP"; Winget="GIMP.GIMP"; Choco="gimp" },

    @{ Category="Utilities"; Name="7-Zip"; Winget="7zip.7zip"; Choco="7zip" },
    @{ Category="Utilities"; Name="WinRAR"; Winget="RARLab.WinRAR"; Choco="winrar" },
    @{ Category="Utilities"; Name="Notepad++"; Winget="Notepad++.Notepad++"; Choco="notepadplusplus" },
    @{ Category="Utilities"; Name="Everything Search"; Winget="voidtools.Everything"; Choco="everything" },
    @{ Category="Utilities"; Name="AnyDesk"; Winget="AnyDeskSoftwareGmbH.AnyDesk"; Choco="anydesk" },
    @{ Category="Utilities"; Name="TeamViewer"; Winget="TeamViewer.TeamViewer"; Choco="teamviewer" },
    @{ Category="Utilities"; Name="RustDesk"; Winget="RustDesk.RustDesk"; Choco="rustdesk" },
    @{ Category="Utilities"; Name="CPU-Z"; Winget="CPUID.CPU-Z"; Choco="cpu-z" },

    @{ Category="Security"; Name="Malwarebytes"; Winget="Malwarebytes.Malwarebytes"; Choco="malwarebytes" },
    @{ Category="Security"; Name="OpenVPN Connect"; Winget="OpenVPNTechnologies.OpenVPNConnect"; Choco="openvpn-connect" },
    @{ Category="Security"; Name="WireGuard"; Winget="WireGuard.WireGuard"; Choco="wireguard" },
    @{ Category="Security"; Name="PuTTY"; Winget="PuTTY.PuTTY"; Choco="putty" },
    @{ Category="Security"; Name="WinSCP"; Winget="WinSCP.WinSCP"; Choco="winscp" },
    @{ Category="Security"; Name="Nmap"; Winget="Insecure.Nmap"; Choco="nmap" }
)

$script:CheckBoxes = New-Object System.Collections.ArrayList
$script:Sections = New-Object System.Collections.ArrayList

# ==========================================================
# Main Form
# ==========================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "AlhamraniHub UI v2"
$form.Size = New-Object System.Drawing.Size(1480, 860)
$form.MinimumSize = New-Object System.Drawing.Size(1200, 760)
$form.StartPosition = "CenterScreen"
$form.BackColor = $Theme.Bg
$form.Font = $FontBody
$form.KeyPreview = $true

# Top bar
$topBar = New-Object System.Windows.Forms.Panel
$topBar.Dock = "Top"
$topBar.Height = 44
$topBar.BackColor = $Theme.Top
$form.Controls.Add($topBar)

$logo = New-Object System.Windows.Forms.Label
$logo.Text = "A"
$logo.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
$logo.ForeColor = $Theme.Accent
$logo.BackColor = $Theme.Top
$logo.TextAlign = "MiddleCenter"
$logo.Size = New-Object System.Drawing.Size(38, 32)
$logo.Location = New-Object System.Drawing.Point(8, 6)
$topBar.Controls.Add($logo)

# tabs
$script:PagePanels = @{}
$script:TabButtons = @{}

function New-TabButton {
    param([string]$Text, [int]$X)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Size = New-Object System.Drawing.Size(108, 28)
    $b.Location = New-Object System.Drawing.Point($X, 7)
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderColor = $Theme.Border2
    $b.FlatAppearance.BorderSize = 1
    $b.BackColor = $Theme.Panel2
    $b.ForeColor = $Theme.White
    $b.Font = $FontBold
    $b.UseMnemonic = $false
    $b.Cursor = "Hand"
    return $b
}

$tabs = @("Install","Tools","Config","Updates","Reports")
$x=62
foreach ($tab in $tabs) {
    $b = New-TabButton -Text $tab -X $x
    $x += 114
    $topBar.Controls.Add($b)
    $script:TabButtons[$tab] = $b
}

$searchBox = New-Object System.Windows.Forms.TextBox
$searchBox.Size = New-Object System.Drawing.Size(230, 26)
$searchBox.Location = New-Object System.Drawing.Point(1115, 9)
$searchBox.Anchor = "Top,Right"
$searchBox.BackColor = $Theme.Panel
$searchBox.ForeColor = $Theme.White
$searchBox.BorderStyle = "FixedSingle"
$searchBox.Font = $FontBody
$topBar.Controls.Add($searchBox)

$searchHint = New-Object System.Windows.Forms.Label
$searchHint.Text = "Search"
$searchHint.AutoSize = $true
$searchHint.ForeColor = $Theme.Muted
$searchHint.Location = New-Object System.Drawing.Point(1360, 14)
$searchHint.Anchor = "Top,Right"
$topBar.Controls.Add($searchHint)

$adminBtn = New-Object System.Windows.Forms.Button
$adminBtn.Text = if (Test-IsAdmin) { "Admin Mode" } else { "Run as Admin" }
$adminBtn.Size = New-Object System.Drawing.Size(110, 28)
$adminBtn.Location = New-Object System.Drawing.Point(995, 7)
$adminBtn.Anchor = "Top,Right"
$adminBtn.FlatStyle = "Flat"
$adminBtn.FlatAppearance.BorderColor = $Theme.Border2
$adminBtn.FlatAppearance.BorderSize = 1
$adminBtn.BackColor = $Theme.Panel2
$adminBtn.ForeColor = if (Test-IsAdmin) { [System.Drawing.Color]::LightGreen } else { $Theme.White }
$adminBtn.Font = $FontMini
$adminBtn.UseMnemonic = $false
$adminBtn.Cursor = "Hand"
$adminBtn.Add_Click({ if (-not (Test-IsAdmin)) { Relaunch-AsAdmin } })
$topBar.Controls.Add($adminBtn)

# page host
$pageHost = New-Object System.Windows.Forms.Panel
$pageHost.Dock = "Fill"
$pageHost.BackColor = $Theme.Bg
$form.Controls.Add($pageHost)

function Set-ActiveTab {
    param([string]$Name)
    foreach ($k in $script:PagePanels.Keys) {
        $script:PagePanels[$k].Visible = $false
        $script:TabButtons[$k].BackColor = $Theme.Panel2
    }
    $script:PagePanels[$Name].Visible = $true
    $script:PagePanels[$Name].BringToFront()
    $script:TabButtons[$Name].BackColor = $Theme.Active
}

# ==========================================================
# INSTALL PAGE LAYOUT (main page like screenshot)
# ==========================================================
$installPage = New-Object System.Windows.Forms.Panel
$installPage.Dock = "Fill"
$installPage.BackColor = $Theme.Bg
$pageHost.Controls.Add($installPage)
$script:PagePanels["Install"] = $installPage

# Left sidebar
$left = New-Object System.Windows.Forms.Panel
$left.Dock = "Left"
$left.Width = 220
$left.BackColor = $Theme.Panel
$installPage.Controls.Add($left)

# right area
$right = New-Object System.Windows.Forms.Panel
$right.Dock = "Fill"
$right.BackColor = $Theme.Bg2
$installPage.Controls.Add($right)

# Left sections
function New-GroupLabel {
    param([string]$Text, [int]$Y)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text
    $l.ForeColor = [System.Drawing.Color]::FromArgb(110, 214, 255)
    $l.Font = $FontHead
    $l.AutoSize = $true
    $l.Location = New-Object System.Drawing.Point(16, $Y)
    $left.Controls.Add($l)
    return $l
}

function New-SideButton {
    param([string]$Text, [int]$Y, [scriptblock]$Action)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Size = New-Object System.Drawing.Size(198, 26)
    $b.Location = New-Object System.Drawing.Point(10, $Y)
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderColor = $Theme.Border2
    $b.FlatAppearance.BorderSize = 1
    $b.BackColor = $Theme.Button
    $b.ForeColor = $Theme.White
    $b.Font = $FontBody
    $b.UseMnemonic = $false
    $b.Cursor = "Hand"
    $b.Add_Click($Action)
    $left.Controls.Add($b)
    return $b
}

New-GroupLabel "Actions" 14 | Out-Null

$installBtn = New-SideButton "Install/Upgrade Applications" 45 {
    $selected = @()
    foreach ($cb in $script:CheckBoxes) { if ($cb.Checked -and $cb.Visible) { $selected += $cb.Tag } }
    if ($selected.Count -eq 0) { Show-Message "Select at least one application first."; return }

    $useWinget = $wingetRadio.Checked
    $lines = @()
    foreach ($app in $selected) {
        $pkg = if ($useWinget) { $app.Winget } else { $app.Choco }
        $name = $app.Name
        if ($useWinget) {
            $lines += "Write-Host 'Installing $name...' -ForegroundColor Yellow"
            $lines += "winget install --id $pkg -e --accept-source-agreements --accept-package-agreements"
        } else {
            $lines += "Write-Host 'Installing $name...' -ForegroundColor Yellow"
            $lines += "choco install $pkg -y"
        }
        $lines += ""
    }
    Start-PowerShellCommand ($lines -join "`r`n") -AsAdmin
}
$uninstallBtn = New-SideButton "Uninstall Applications" 74 {
    $selected = @()
    foreach ($cb in $script:CheckBoxes) { if ($cb.Checked -and $cb.Visible) { $selected += $cb.Tag } }
    if ($selected.Count -eq 0) { Show-Message "Select at least one application first."; return }
    if (-not (Confirm-Action "Uninstall selected applications?")) { return }

    $useWinget = $wingetRadio.Checked
    $lines = @()
    foreach ($app in $selected) {
        $pkg = if ($useWinget) { $app.Winget } else { $app.Choco }
        $name = $app.Name
        if ($useWinget) {
            $lines += "Write-Host 'Uninstalling $name...' -ForegroundColor Yellow"
            $lines += "winget uninstall --id $pkg -e"
        } else {
            $lines += "Write-Host 'Uninstalling $name...' -ForegroundColor Yellow"
            $lines += "choco uninstall $pkg -y"
        }
        $lines += ""
    }
    Start-PowerShellCommand ($lines -join "`r`n") -AsAdmin
}
$upgradeAllBtn = New-SideButton "Upgrade all Applications" 103 {
    if ($wingetRadio.Checked) {
        Start-PowerShellCommand "winget upgrade --all --accept-source-agreements --accept-package-agreements" -AsAdmin
    } else {
        Start-PowerShellCommand "choco upgrade all -y" -AsAdmin
    }
}

New-GroupLabel "Package Manager" 146 | Out-Null

$chocoRadio = New-Object System.Windows.Forms.RadioButton
$chocoRadio.Text = "Chocolatey"
$chocoRadio.ForeColor = $Theme.White
$chocoRadio.BackColor = $Theme.Panel
$chocoRadio.Font = $FontBody
$chocoRadio.AutoSize = $true
$chocoRadio.Location = New-Object System.Drawing.Point(28, 175)
$left.Controls.Add($chocoRadio)

$wingetRadio = New-Object System.Windows.Forms.RadioButton
$wingetRadio.Text = "WinGet"
$wingetRadio.ForeColor = $Theme.White
$wingetRadio.BackColor = $Theme.Panel
$wingetRadio.Font = $FontBody
$wingetRadio.AutoSize = $true
$wingetRadio.Location = New-Object System.Drawing.Point(28, 198)
$wingetRadio.Checked = $true
$left.Controls.Add($wingetRadio)

New-GroupLabel "Selection" 232 | Out-Null

$noteLabel = New-Object System.Windows.Forms.Label
$noteLabel.Text = "• Free and Open Source Software"
$noteLabel.AutoSize = $true
$noteLabel.ForeColor = $Theme.Accent
$noteLabel.Location = New-Object System.Drawing.Point(14, 261)
$left.Controls.Add($noteLabel)

function Update-SelectedCount {
    $count = 0
    foreach ($cb in $script:CheckBoxes) { if ($cb.Checked) { $count++ } }
    $selectedCountBtn.Text = "Selected Apps: $count"
}

$clearBtn = New-SideButton "Clear Selection" 290 {
    foreach ($cb in $script:CheckBoxes) { $cb.Checked = $false }
    Update-SelectedCount
}
$collapseBtn = New-SideButton "Collapse All Categories" 319 {
    foreach ($sec in $script:Sections) {
        $sec.Content.Visible = $false
        $sec.Panel.Height = 34
    }
}
$expandBtn = New-SideButton "Expand All Categories" 348 {
    foreach ($sec in $script:Sections) {
        $sec.Content.Visible = $true
        $sec.Panel.Height = $sec.ExpandedHeight
    }
}
$selectedCountBtn = New-SideButton "Selected Apps: 0" 377 { }
$showInstalledBtn = New-SideButton "Show Installed Apps" 406 {
    if ($wingetRadio.Checked) {
        Start-PowerShellCommand "winget list"
    } else {
        Start-PowerShellCommand "choco list --local-only"
    }
}

# Right scroll panel
$scroll = New-Object System.Windows.Forms.Panel
$scroll.Dock = "Fill"
$scroll.BackColor = $Theme.Bg2
$scroll.AutoScroll = $true
$right.Controls.Add($scroll)

$content = New-Object System.Windows.Forms.FlowLayoutPanel
$content.FlowDirection = "TopDown"
$content.WrapContents = $false
$content.AutoSize = $true
$content.AutoSizeMode = "GrowAndShrink"
$content.Location = New-Object System.Drawing.Point(8, 8)
$content.BackColor = $Theme.Bg2
$content.Padding = New-Object System.Windows.Forms.Padding(0)
$scroll.Controls.Add($content)

function New-SectionPanel {
    param([string]$Name, [object[]]$Items)

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Width = 1190
    $panel.BackColor = $Theme.Bg2
    $panel.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 6)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = "- $Name"
    $title.ForeColor = [System.Drawing.Color]::FromArgb(110, 214, 255)
    $title.Font = $FontHead
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(8, 4)
    $panel.Controls.Add($title)

    $contentPanel = New-Object System.Windows.Forms.Panel
    $contentPanel.Location = New-Object System.Drawing.Point(0, 28)
    $contentPanel.Width = 1180
    $contentPanel.Height = 10
    $contentPanel.BackColor = $Theme.Bg2
    $panel.Controls.Add($contentPanel)

    $colWidth = 195
    $rowHeight = 24
    $cols = 5

    for ($i = 0; $i -lt $Items.Count; $i++) {
        $item = $Items[$i]
        $col = [Math]::Floor($i / 8)
        $row = $i % 8
        $x = 10 + ($col * $colWidth)
        $y = 0 + ($row * $rowHeight)

        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $item.Name
        $cb.Tag = $item
        $cb.ForeColor = $Theme.White
        $cb.BackColor = $Theme.Bg2
        $cb.FlatStyle = "Flat"
        $cb.AutoSize = $false
        $cb.Width = 175
        $cb.Height = 22
        $cb.Location = New-Object System.Drawing.Point($x, $y)
        $cb.Font = $FontBody
        $cb.Add_CheckedChanged({ Update-SelectedCount })
        $contentPanel.Controls.Add($cb)
        [void]$script:CheckBoxes.Add($cb)
    }

    $rows = [Math]::Ceiling($Items.Count / 5.0)
    if ($rows -lt 1) { $rows = 1 }
    $height = ([Math]::Min(8, $Items.Count) * $rowHeight)
    # compute max per column instead
    $maxRows = [Math]::Ceiling($Items.Count / 5.0)
    $contentPanel.Height = ($maxRows * $rowHeight)
    $panel.Height = 34 + $contentPanel.Height

    # Toggle collapse on title click
    $toggleAction = {
        if ($contentPanel.Visible) {
            $contentPanel.Visible = $false
            $panel.Height = 34
        } else {
            $contentPanel.Visible = $true
            $panel.Height = 34 + $contentPanel.Height
        }
    }.GetNewClosure()

    $title.Cursor = "Hand"
    $title.Add_Click($toggleAction)

    [void]$script:Sections.Add([pscustomobject]@{
        Panel = $panel
        Content = $contentPanel
        ExpandedHeight = 34 + $contentPanel.Height
    })

    $content.Controls.Add($panel) | Out-Null
}

$categories = $script:Catalog | Group-Object Category
foreach ($cat in $categories) {
    New-SectionPanel -Name $cat.Name -Items $cat.Group
}

# search behavior
$searchBox.Add_TextChanged({
    $q = $searchBox.Text.Trim().ToLowerInvariant()
    foreach ($cb in $script:CheckBoxes) {
        $name = ([string]$cb.Text).ToLowerInvariant()
        $cat = ([string]$cb.Tag.Category).ToLowerInvariant()
        $cb.Visible = ([string]::IsNullOrWhiteSpace($q) -or $name.Contains($q) -or $cat.Contains($q))
    }

    foreach ($sec in $script:Sections) {
        $visibleCount = 0
        foreach ($ctrl in $sec.Content.Controls) {
            if ($ctrl.Visible) { $visibleCount++ }
        }
        $sec.Panel.Visible = ($visibleCount -gt 0)
    }
})

# ==========================================================
# TOOLS PAGE
# ==========================================================
function New-SimplePage {
    param([string]$Name)
    $p = New-Object System.Windows.Forms.Panel
    $p.Dock = "Fill"
    $p.BackColor = $Theme.Bg2
    $p.Visible = $false
    $pageHost.Controls.Add($p)
    $script:PagePanels[$Name] = $p
    return $p
}

function Add-ToolCard {
    param(
        [System.Windows.Forms.Panel]$Page,
        [string]$Text,
        [int]$X,
        [int]$Y,
        [scriptblock]$Action
    )
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text
    $b.Size = New-Object System.Drawing.Size(220, 56)
    $b.Location = New-Object System.Drawing.Point($X, $Y)
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderColor = $Theme.Border2
    $b.FlatAppearance.BorderSize = 1
    $b.BackColor = $Theme.Panel2
    $b.ForeColor = $Theme.White
    $b.Font = $FontBold
    $b.UseMnemonic = $false
    $b.Cursor = "Hand"
    $b.Add_Click($Action)
    $Page.Controls.Add($b)
    return $b
}

$toolsPage = New-SimplePage "Tools"
$toolsTitle = New-Object System.Windows.Forms.Label
$toolsTitle.Text = "Quick Windows Tools"
$toolsTitle.ForeColor = $Theme.White
$toolsTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
$toolsTitle.AutoSize = $true
$toolsTitle.Location = New-Object System.Drawing.Point(20, 18)
$toolsPage.Controls.Add($toolsTitle)

$toolY = 70
$toolX = 20
$toolGap = 235
$toolList = @(
    @("Control Panel", { Start-Tool "control.exe" }),
    @("Network Connections", { Start-Tool "ncpa.cpl" }),
    @("Programs & Features", { Start-Tool "appwiz.cpl" }),
    @("Device Manager", { Start-Tool "devmgmt.msc" }),
    @("Services", { Start-Tool "services.msc" }),
    @("Disk Management", { Start-Tool "diskmgmt.msc" }),
    @("Event Viewer", { Start-Tool "eventvwr.msc" }),
    @("Task Manager", { Start-Tool "taskmgr.exe" }),
    @("Windows Update", { Open-Target "ms-settings:windowsupdate" }),
    @("PowerShell", { Start-Tool "powershell.exe" }),
    @("PowerShell Admin", { Start-Tool "powershell.exe" -AsAdmin }),
    @("Quick Assist", { Start-Tool "quickassist.exe" }),
    @("System Information", { Start-Tool "msinfo32.exe" }),
    @("Sound", { Start-Tool "mmsys.cpl" }),
    @("Firewall", { Start-Tool "firewall.cpl" })
)
for ($i=0; $i -lt $toolList.Count; $i++) {
    $col = $i % 4
    $row = [Math]::Floor($i / 4)
    Add-ToolCard -Page $toolsPage -Text $toolList[$i][0] -X ($toolX + ($col * $toolGap)) -Y ($toolY + ($row * 68)) -Action $toolList[$i][1] | Out-Null
}

# ==========================================================
# CONFIG PAGE
# ==========================================================
$configPage = New-SimplePage "Config"
$configTitle = New-Object System.Windows.Forms.Label
$configTitle.Text = "Configuration"
$configTitle.ForeColor = $Theme.White
$configTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
$configTitle.AutoSize = $true
$configTitle.Location = New-Object System.Drawing.Point(20, 18)
$configPage.Controls.Add($configTitle)

$configText = New-Object System.Windows.Forms.Label
$configText.Text = "Use this page for common support configuration actions."
$configText.ForeColor = $Theme.Muted
$configText.AutoSize = $true
$configText.Location = New-Object System.Drawing.Point(22, 50)
$configPage.Controls.Add($configText)

$configButtons = @(
    @("Environment Variables", { Start-Tool "SystemPropertiesAdvanced.exe" }),
    @("Default Apps", { Open-Target "ms-settings:defaultapps" }),
    @("Display Settings", { Open-Target "ms-settings:display" }),
    @("Bluetooth Settings", { Open-Target "ms-settings:bluetooth" }),
    @("Proxy Settings", { Open-Target "ms-settings:network-proxy" }),
    @("VPN Settings", { Open-Target "ms-settings:network-vpn" }),
    @("Printers", { Open-Target "ms-settings:printers" }),
    @("Remote Desktop", { Open-Target "ms-settings:remotedesktop" })
)
for ($i=0; $i -lt $configButtons.Count; $i++) {
    $col = $i % 4
    $row = [Math]::Floor($i / 4)
    Add-ToolCard -Page $configPage -Text $configButtons[$i][0] -X ($toolX + ($col * $toolGap)) -Y (95 + ($row * 68)) -Action $configButtons[$i][1] | Out-Null
}

# ==========================================================
# UPDATES PAGE
# ==========================================================
$updatesPage = New-SimplePage "Updates"
$updatesTitle = New-Object System.Windows.Forms.Label
$updatesTitle.Text = "Updates Center"
$updatesTitle.ForeColor = $Theme.White
$updatesTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
$updatesTitle.AutoSize = $true
$updatesTitle.Location = New-Object System.Drawing.Point(20, 18)
$updatesPage.Controls.Add($updatesTitle)

$updateButtons = @(
    @("Windows Update", { Open-Target "ms-settings:windowsupdate" }),
    @("Update History", { Open-Target "ms-settings:windowsupdate-history" }),
    @("Check Winget Updates", { Start-PowerShellCommand "winget upgrade" }),
    @("Upgrade All Winget Apps", { Start-PowerShellCommand "winget upgrade --all --accept-source-agreements --accept-package-agreements" -AsAdmin }),
    @("Update Winget Sources", { Start-PowerShellCommand "winget source update" -AsAdmin }),
    @("Reset Winget Sources", { Start-PowerShellCommand "winget source reset --force; winget source update" -AsAdmin }),
    @("Microsoft Store Updates", { Open-Target "ms-windows-store://downloadsandupdates" }),
    @("Check Chocolatey Outdated", { Start-PowerShellCommand "choco outdated" -AsAdmin })
)
for ($i=0; $i -lt $updateButtons.Count; $i++) {
    $col = $i % 4
    $row = [Math]::Floor($i / 4)
    Add-ToolCard -Page $updatesPage -Text $updateButtons[$i][0] -X ($toolX + ($col * $toolGap)) -Y (95 + ($row * 68)) -Action $updateButtons[$i][1] | Out-Null
}

# ==========================================================
# REPORTS PAGE
# ==========================================================
$reportsPage = New-SimplePage "Reports"
$reportsTitle = New-Object System.Windows.Forms.Label
$reportsTitle.Text = "Reports & Diagnostics"
$reportsTitle.ForeColor = $Theme.White
$reportsTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 16)
$reportsTitle.AutoSize = $true
$reportsTitle.Location = New-Object System.Drawing.Point(20, 18)
$reportsPage.Controls.Add($reportsTitle)

$reportButtons = @(
    @("System Report", {
        $out = Join-Path ([Environment]::GetFolderPath("Desktop")) "AlhamraniHub-System-Report.txt"
        $cmd = "Get-ComputerInfo | Out-File `"$out`"; ipconfig /all | Out-File `"$out`" -Append; notepad `"$out`""
        Start-PowerShellCommand $cmd
    }),
    @("Battery Report", {
        $out = Join-Path ([Environment]::GetFolderPath("Desktop")) "AlhamraniHub-Battery-Report.html"
        Start-PowerShellCommand "powercfg /batteryreport /output `"$out`"; start `"$out`""
    }),
    @("Wi-Fi Report", { Start-PowerShellCommand "netsh wlan show wlanreport" }),
    @("Installed Apps", { Start-PowerShellCommand "winget list" }),
    @("Recent System Errors", {
        $out = Join-Path ([Environment]::GetFolderPath("Desktop")) "AlhamraniHub-Errors.txt"
        $cmd = "Get-WinEvent -LogName System -MaxEvents 300 | Where-Object { `$_.LevelDisplayName -eq 'Error' } | Select-Object -First 50 TimeCreated,ProviderName,Id,Message | Format-List | Out-File `"$out`"; notepad `"$out`""
        Start-PowerShellCommand $cmd
    }),
    @("DxDiag Report", {
        $out = Join-Path ([Environment]::GetFolderPath("Desktop")) "AlhamraniHub-DxDiag.txt"
        Start-PowerShellCommand "dxdiag /t `"$out`"; notepad `"$out`""
    })
)
for ($i=0; $i -lt $reportButtons.Count; $i++) {
    $col = $i % 3
    $row = [Math]::Floor($i / 3)
    Add-ToolCard -Page $reportsPage -Text $reportButtons[$i][0] -X ($toolX + ($col * 245)) -Y (95 + ($row * 68)) -Action $reportButtons[$i][1] | Out-Null
}

# Tab wiring
foreach ($tab in $tabs) {
    $name = $tab
    $script:TabButtons[$name].Add_Click({ Set-ActiveTab $name }.GetNewClosure())
}

# keyboard shortcuts
$form.Add_KeyDown({
    if ($_.Control -and $_.KeyCode -eq "F") {
        $searchBox.Focus()
        $searchBox.SelectAll()
    }
    if ($_.KeyCode -eq "Escape") {
        $searchBox.Text = ""
    }
})

Set-ActiveTab "Install"
[void]$form.ShowDialog()
