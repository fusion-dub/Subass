# Subass Notes Installer for Windows
# This script automates the installation of Python and REAPER extensions.

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

function Write-Host-Color {
    param($Text, $Color = "White")
    Write-Host ">> $Text" -ForegroundColor $Color
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   Subass Notes - Automated Installer (Win)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check if REAPER is running
$reaperProc = Get-Process "reaper" -ErrorAction SilentlyContinue
if ($reaperProc) {
    Write-Host-Color "ERROR: REAPER is currently running." "Red"
    Write-Host-Color "Please close REAPER and run this installer again." "Yellow"
    Pause
    exit
}

# 2. Paths
$reaperPath = "$env:APPDATA\REAPER"
$currentDir = Get-Location

# Detect portable installation
if (Test-Path (Join-Path $currentDir "reaper.ini")) {
    $reaperPath = $currentDir
    Write-Host-Color "Portable REAPER detected in installer directory." "Yellow"
}

if (-not (Test-Path $reaperPath)) {
    Write-Host-Color "ERROR: Could not find REAPER folder at $reaperPath" "Red"
    Pause
    exit
}

$userPluginsPath = Join-Path $reaperPath "UserPlugins"
$scriptsPath = Join-Path $reaperPath "Scripts\Subass"
if (-not (Test-Path $userPluginsPath)) { New-Item -ItemType Directory $userPluginsPath | Out-Null }
if (-not (Test-Path $scriptsPath)) { New-Item -ItemType Directory $scriptsPath | Out-Null }

# 3. Install Python 3 via Winget
Write-Host-Color "Checking Python 3..." "Cyan"
$pythonCheck = where.exe python 2>$null
if (-not $pythonCheck) {
    Write-Host-Color "Python not found. Attempting to install via winget..." "Yellow"
    try {
        Start-Process winget -ArgumentList "install -e --id Python.Python.3.11 --silent" -Wait
        Write-Host-Color "Python 3 installed successfully." "Green"
    } catch {
        Write-Host-Color "Failed auto-install. Please install Python 3.11 manually from https://www.python.org/" "Red"
    }
} else {
    Write-Host-Color "Python 3 is already installed." "Green"
}

# 4. Download Extensions
$extensions = @(
    @{
        Name = "ReaPack"
        Url  = "https://github.com/cfillion/reapack/releases/latest/download/reaper_reapack-x64.dll"
        File = "reaper_reapack-x64.dll"
    },
    @{
        Name = "SWS Extension"
        Url  = "https://github.com/reaper-oss/sws/releases/download/v2.14.0.7/reaper_sws-x64.dll"
        File = "reaper_sws-x64.dll"
    },
    @{
        Name = "js_ReaScriptAPI"
        Url  = "https://github.com/juliansader/ReaExtensions/raw/master/js_ReaScriptAPI/v1.310/reaper_js_ReaScriptAPI64.dll"
        File = "reaper_js_ReaScriptAPI64.dll"
    },
    @{
        Name = "ReaImGui"
        Url  = "https://github.com/cfillion/reaimgui/releases/latest/download/reaper_imgui-x64.dll"
        File = "reaper_imgui-x64.dll"
    }
)

function Download-File {
    param($Url, $TargetPath)
    try {
        if (Get-Command "curl.exe" -ErrorAction SilentlyContinue) {
            # curl is built into Windows 10/11 and is very robust
            curl.exe -L -k -s -o "$TargetPath" "$Url"
            if (Test-Path $TargetPath) { return $true }
        }
        # Fallback to PowerShell
        Invoke-WebRequest -Uri $Url -OutFile $TargetPath -UserAgent "Mozilla/5.0" -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

foreach ($ext in $extensions) {
    $target = Join-Path $userPluginsPath $ext.File
    $isInstalled = Test-Path $target
    
    # Extra check for ReaPack alternative names
    if ($ext.Name -eq "ReaPack" -and -not $isInstalled) {
        if (Test-Path (Join-Path $userPluginsPath "reaper_reapack-x64.dll")) { $isInstalled = $true }
    }

    if (-not $isInstalled) {
        Write-Host-Color "Downloading $($ext.Name)..." "Cyan"
        if (Download-File $ext.Url $target) {
            Write-Host-Color "$($ext.Name) installed." "Green"
        } else {
            Write-Host-Color "Failed to download $($ext.Name). Please install manually." "Red"
        }
    } else {
        Write-Host-Color "$($ext.Name) is already installed." "Gray"
    }
}

# 5. Copy Scripts
Write-Host-Color "Installing Subass Notes scripts..." "Cyan"
$currentDir = Get-Location
$scriptFile = "plugin\Subass_Notes.lua"
$stressFolder = "plugin\stress"
$overlayFile = "plugin\overlay\Lionzz_SubOverlay_Subass.lua"

if (Test-Path (Join-Path $currentDir $scriptFile)) {
    Copy-Item (Join-Path $currentDir $scriptFile) $scriptsPath -Force
    if (Test-Path (Join-Path $currentDir $stressFolder)) {
        Copy-Item (Join-Path $currentDir $stressFolder) $scriptsPath -Recurse -Force
    }
    if (Test-Path (Join-Path $currentDir $overlayFile)) {
        $overlayTargetDir = Join-Path $scriptsPath "overlay"
        if (-not (Test-Path $overlayTargetDir)) { New-Item -ItemType Directory $overlayTargetDir | Out-Null }
        Copy-Item (Join-Path $currentDir $overlayFile) (Join-Path $overlayTargetDir "Lionzz_SubOverlay_Subass.lua") -Force
    }
    Write-Host-Color "Scripts copied to REAPER/Scripts/Subass" "Green"
} else {
    Write-Host-Color "ERROR: Could not find $scriptFile in current directory." "Red"
}

# 6. Register Action and Menu Item
$kbFile = Join-Path $reaperPath "reaper-kb.ini"
$menuFile = Join-Path $reaperPath "reaper-menu.ini"
$actionId = "RS77777777777777777777777777777777"
$overlayActionId = "RS88888888888888888888888888888888"

Write-Host-Color "Updating REAPER configuration..." "Cyan"
Write-Host-Color "Menu File: $menuFile" "Gray"

if (Test-Path $kbFile) {
    Write-Host-Color "Updating actions in reaper-kb.ini..." "Cyan"
    $scriptRelativePath = "Subass/Subass_Notes.lua"
    $overlayRelativePath = "Subass/overlay/Lionzz_SubOverlay_Subass.lua"
    $kbContent = [System.IO.File]::ReadAllLines($kbFile)
    
    $newKb = New-Object System.Collections.Generic.List[string]
    $foundMain = $false
    $foundOverlay = $false
    
    foreach ($line in $kbContent) {
        if ($line -notmatch "Subass_Notes.lua" -and $line -notmatch "Lionzz_SubOverlay_Subass.lua") {
            $newKb.Add($line)
            continue
        }
        
        if ($line -match "Subass[/\\]+Subass_Notes.lua") {
            if (-not $foundMain) {
                if ($line -match "SCR 4 0 (RS[0-9a-fA-F]+)") { $actionId = $matches[1] }
                $newKb.Add($line)
                $foundMain = $true
            }
        } elseif ($line -match "Subass[/\\]+overlay[/\\]+Lionzz_SubOverlay_Subass.lua") {
            if (-not $foundOverlay) {
                if ($line -match "SCR 4 0 (RS[0-9a-fA-F]+)") { $overlayActionId = $matches[1] }
                $newKb.Add($line)
                $foundOverlay = $true
            }
        }
    }
    
    if (-not $foundMain) { $newKb.Add("SCR 4 0 $actionId ""Custom: Subass Notes"" ""$scriptRelativePath""") }
    if (-not $foundOverlay) { $newKb.Add("SCR 4 0 $overlayActionId ""Custom: Subass SubOverlay (Lionzz)"" ""$overlayRelativePath""") }
    
    [System.IO.File]::WriteAllLines($kbFile, $newKb)
    Write-Host-Color "Found Notes ID: $actionId" "Green"
    Write-Host-Color "Found Overlay ID: $overlayActionId" "Green"
}

# Handle missing menu file
if (-not (Test-Path $menuFile)) {
    Write-Host-Color "Extensions menu file not found. Creating new..." "Yellow"
    [System.IO.File]::WriteAllText($menuFile, "`r`n[Main Extensions]`r`n")
}

if (Test-Path $menuFile) {
    Write-Host-Color "Updating Extensions menu..." "Cyan"
    $lines = [System.IO.File]::ReadAllLines($menuFile)
    
    $contentBefore = @()
    $contentAfter = @()
    $otherItems = @()
    $state = "before"

    foreach ($line in $lines) {
        $clean = $line.Trim()
        # More flexible section matching
        if ($clean -match "^\[\s*Main Extensions\s*\]$") {
            $state = "in"
            $contentBefore += $line
            continue
        }
        if ($state -eq "in" -and $clean -match "^\[") {
            $state = "after"
        }
        
        if ($state -eq "before") {
            $contentBefore += $line
        } elseif ($state -eq "after") {
            $contentAfter += $line
        } elseif ($state -eq "in") {
            if ($line -match "^item_(\d+)=(.*)") {
                $val = $matches[2]
                # Filter out everything related to Subass to start fresh
                if ($val -notmatch "Subass" -and $val -ne "0" -and $val -ne "-1000" -and $val -ne "-1001") {
                    $otherItems += $val
                }
            }
        }
    }

    if ($state -eq "before") {
        Write-Host-Color "Section [Main Extensions] not found. Adding to end of file." "Yellow"
        if ($contentBefore.Count -gt 0 -and $contentBefore[-1] -ne "") { $contentBefore += "" }
        $contentBefore += "[Main Extensions]"
    } else {
        Write-Host-Color "Section found. Syncing items..." "Gray"
    }

    # Build the item list: Old Items + Separator + Subass 1 + Subass 2 + Separator
    $finalItems = $otherItems + @("0", "_$actionId Subass: Notes", "_$overlayActionId Subass: SubOverlay (Lionzz)", "0")
    
    $newMenu = New-Object System.Collections.Generic.List[string]
    foreach ($l in $contentBefore) { $newMenu.Add($l) }
    for ($i = 0; $i -lt $finalItems.Count; $i++) {
        $newMenu.Add("item_$i=$($finalItems[$i])")
    }

    if ($contentAfter.Count -gt 0) {
        if ($newMenu[$newMenu.Count-1] -ne "") { $newMenu.Add("") }
        foreach ($l in $contentAfter) { $newMenu.Add($l) }
    }

    # Write without BOM for maximum compatibility
    $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($menuFile, $newMenu, $utf8NoBOM)
    Write-Host-Color "Menu updated successfully." "Green"
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "   INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "   You can now open REAPER and find 'Subass Notes'"
Write-Host "   in the Actions list (Ctrl+Alt+S) or in the Extensions menu."
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Pause
