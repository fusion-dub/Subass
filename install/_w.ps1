# Subass Notes Installer for Windows
# This script automates the installation of Python and REAPER extensions.

try {

$ErrorActionPreference = "Continue"
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
$runningPath = $null

if ($reaperProc) {
    # Check if we can get the path (some users might have multi-install)
    try {
        $exePath = $reaperProc.Path
        $exeDir = Split-Path $exePath
        if (Test-Path (Join-Path $exeDir "reaper.ini")) {
            $runningPath = $exeDir
        } else {
            # Likely standard install, path would be AppData
            if (Test-Path "$env:APPDATA\REAPER\reaper.ini") {
                $runningPath = "$env:APPDATA\REAPER"
            }
        }
    } catch {}

    Write-Host-Color "ERROR: REAPER is currently running." "Red"
    if ($runningPath) {
        Write-Host-Color "Detected REAPER at: $runningPath" "Gray"
    }
    Write-Host-Color "Please close REAPER and run this installer again." "Yellow"
    Pause
    exit
}

# 2. Path Detection Logic
function Get-ReaperPath {
    param($DefaultPath)
    
    # 1. Check current directory (portable)
    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) { $scriptDir = Get-Location }
    if (Test-Path (Join-Path $scriptDir "reaper.ini")) {
        Write-Host-Color "Portable REAPER detected in installer directory." "Yellow"
        return $scriptDir
    }

    # 2. Check registry for InstallDir (Portable check)
    $regPaths = @(
        "HKCU:\Software\REAPER",
        "HKLM:\SOFTWARE\REAPER",
        "HKLM:\SOFTWARE\WOW6432Node\REAPER"
    )
    foreach ($regPath in $regPaths) {
        if (Test-Path $regPath) {
            $installDir = Get-ItemProperty -Path $regPath -Name "InstallDir" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty InstallDir -ErrorAction SilentlyContinue
            if ($installDir -and (Test-Path (Join-Path $installDir "reaper.ini"))) {
                Write-Host-Color "Portable REAPER detected via registry: $installDir" "Yellow"
                return $installDir
            }
        }
    }

    # 3. Check C:\REAPER (Common non-standard path)
    if (Test-Path "C:\REAPER\reaper.ini") {
        Write-Host-Color "REAPER detected in C:\REAPER" "Yellow"
        return "C:\REAPER"
    }

    # 4. Check default AppData (Strictly verify reaper.ini)
    if (Test-Path (Join-Path $DefaultPath "reaper.ini")) {
        return $DefaultPath
    }

    # 5. Manual Fallback
    Write-Host-Color "REAPER resource folder not found or reaper.ini missing." "Yellow"
    Write-Host ""
    Write-Host "Please specify the REAPER resource folder manually."
    Write-Host "(This folder MUST contain 'reaper.ini')"
    
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $browser = New-Object System.Windows.Forms.FolderBrowserDialog
        $browser.Description = "Select REAPER Resource Folder (containing reaper.ini)"
        $browser.ShowNewFolderButton = $false
        
        if ($browser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $selected = $browser.SelectedPath
            if (Test-Path (Join-Path $selected "reaper.ini")) {
                return $selected
            } else {
                Write-Host-Color "WARNING: reaper.ini not found in selected folder." "Red"
            }
        }
    } catch {}

    Write-Host "Enter path: " -NoNewline
    $manualPath = Read-Host
    if ($manualPath -and (Test-Path (Join-Path $manualPath "reaper.ini"))) {
        return $manualPath
    }

    return $null
}

$reaperPath = Get-ReaperPath -DefaultPath "$env:APPDATA\REAPER"

if (-not $reaperPath -or -not (Test-Path $reaperPath)) {
    Write-Host-Color "ERROR: Could not find or access REAPER folder." "Red"
    Pause
    exit
}

Write-Host-Color "Using REAPER path: $reaperPath" "Gray"

$userPluginsPath = Join-Path $reaperPath "UserPlugins"
$scriptsPath = Join-Path $reaperPath "Scripts\Subass"
if (-not (Test-Path $userPluginsPath)) { New-Item -ItemType Directory $userPluginsPath | Out-Null }
if (-not (Test-Path $scriptsPath)) { New-Item -ItemType Directory $scriptsPath | Out-Null }

# 3. Install Python 3 via Winget
Write-Host-Color "Checking Python 3..." "Cyan"

function Get-Python-Command {
    Write-Host-Color "Searching for Python..." "Gray"
    foreach ($cmd in "python", "python3", "py") {
        $cmdInfo = Get-Command $cmd -ErrorAction SilentlyContinue
        if ($cmdInfo) {
            try {
                $testArgs = if ($cmd -eq "py") { @("-3", "--version") } else { @("--version") }
                $versionInfo = & $cmd $testArgs 2>&1 | Out-String
                
                if ($versionInfo -match "Python 3") {
                    Write-Host-Color "Found Python via '$cmd': $($versionInfo.Trim())" "Gray"
                    if ($cmd -eq "py") {
                        return @{ exe = "py"; args = @("-3") }
                    } else {
                        return @{ exe = $cmd; args = @() }
                    }
                }
            } catch {
                # Ignore failures
            }
        }
    }
    return $null
}

$pythonCmd = Get-Python-Command

if (-not $pythonCmd) {
    Write-Host-Color "Python 3 not found or invalid. Attempting to install via winget..." "Yellow"
    try {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Start-Process winget -ArgumentList "install -e --id Python.Python.3.11 --silent" -Wait
            $pythonCmd = Get-Python-Command
        }
    } catch {
        Write-Host-Color "Auto-install attempt failed." "Gray"
    }
    
    if (-not $pythonCmd) {
        Write-Host-Color "CRITICAL: Python still not detected." "Red"
        Write-Host-Color "Please install Python 3.11+ manually from https://www.python.org/" "Yellow"
        Write-Host-Color "IMPORTANT: Check 'Add Python to PATH' during installation." "Yellow"
        Pause
        exit
    } else {
        $vStr = & $pythonCmd.exe $pythonCmd.args --version
        Write-Host-Color "Python 3 installed successfully: $vStr" "Green"
    }
} else {
    $vStr = & $pythonCmd.exe $pythonCmd.args --version
    Write-Host-Color "Detected Python: $vStr" "Green"
}

# Store the detected python command as a string
$env:SUBASS_PYTHON = if ($pythonCmd.args.Count -gt 0) { "$($pythonCmd.exe) $($pythonCmd.args -join ' ')" } else { $pythonCmd.exe }

# 3.5 Check FFmpeg via Winget
Write-Host-Color "Checking FFmpeg..." "Cyan"
$ffmpegCheck = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpegCheck) {
    Write-Host-Color "FFmpeg not found. Attempting to install via winget..." "Yellow"
    try {
        Start-Process winget -ArgumentList "install -e --id Gyan.FFmpeg --silent" -Wait
        Write-Host-Color "FFmpeg installed successfully." "Green"
    } catch {
        Write-Host-Color "Failed auto-install of FFmpeg. Please install manually from https://www.gyan.dev/ffmpeg/builds/" "Red"
    }
} else {
    Write-Host-Color "FFmpeg is already installed." "Green"
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
            curl.exe -L -k -s -o "$TargetPath" "$Url"
            if (Test-Path $TargetPath) { return $true }
        }
        Invoke-WebRequest -Uri $Url -OutFile $TargetPath -UserAgent "Mozilla/5.0" -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

foreach ($ext in $extensions) {
    $target = Join-Path $userPluginsPath $ext.File
    $isInstalled = Test-Path $target
    
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

$scriptBase = $PSScriptRoot
if (-not $scriptBase) { $scriptBase = Get-Location }
$projectRoot = Split-Path $scriptBase -Parent

$scriptSource = Join-Path $projectRoot "plugin\Subass_Notes.lua"
$stressSource = Join-Path $projectRoot "plugin\stress"
$overlaySource = Join-Path $projectRoot "plugin\overlay\Lionzz_SubOverlay_Subass.lua"
$autoupdateSource = Join-Path $projectRoot "plugin\subass_autoupdate.py"
$dictionarySource = Join-Path $projectRoot "plugin\dictionary"
$ttsSource = Join-Path $projectRoot "plugin\tts"
$statsSource = Join-Path $projectRoot "plugin\stats"

if (Test-Path $scriptSource) {
    Copy-Item $scriptSource $scriptsPath -Force
    if (Test-Path $stressSource) {
        $stressTarget = Join-Path $scriptsPath "stress"
        # Preserve stanza_resources folder during update
        if (Test-Path $stressTarget) {
            # Update existing stress folder, excluding stanza_resources
            Get-ChildItem $stressSource | Where-Object { 
                $_.Name -ne "stanza_resources" -and $_.Name -ne "stress_debug.log" 
            } | ForEach-Object {
                Copy-Item $_.FullName $stressTarget -Recurse -Force
            }
        } else {
            # First install - copy everything
            Copy-Item $stressSource $scriptsPath -Recurse -Force
        }
    }
    if (Test-Path $overlaySource) {
        $overlayTargetDir = Join-Path $scriptsPath "overlay"
        if (-not (Test-Path $overlayTargetDir)) { New-Item -ItemType Directory $overlayTargetDir | Out-Null }
        Copy-Item $overlaySource (Join-Path $overlayTargetDir "Lionzz_SubOverlay_Subass.lua") -Force
    }
    if (Test-Path $autoupdateSource) {
        Copy-Item $autoupdateSource $scriptsPath -Force
    }
    if (Test-Path $dictionarySource) {
        Copy-Item $dictionarySource $scriptsPath -Recurse -Force
    }
    if (Test-Path $statsSource) {
        $statsTarget = Join-Path $scriptsPath "stats"
        if (-not (Test-Path $statsTarget)) { New-Item -ItemType Directory $statsTarget | Out-Null }
        
        Get-ChildItem $statsSource | ForEach-Object {
            $destFile = Join-Path $statsTarget $_.Name
            if ($_.Extension -eq ".json") {
                # Only copy if doesn't exist (don't overwrite user data)
                if (-not (Test-Path $destFile)) {
                    Copy-Item $_.FullName $destFile
                }
            } else {
                # Update code files (.py, etc)
                Copy-Item $_.FullName $destFile -Force
            }
        }
    }

    if (Test-Path $ttsSource) {
        $ttsTarget = Join-Path $scriptsPath "tts"
        # Preserve history folder during update
        if (Test-Path $ttsTarget) {
            # Update existing tts folder, excluding history
            Get-ChildItem $ttsSource | Where-Object { 
                $_.Name -ne "history" 
            } | ForEach-Object {
                    Copy-Item $_.FullName $ttsTarget -Recurse -Force
            }
        } else {
            # First install - copy everything
            Copy-Item $ttsSource $scriptsPath -Recurse -Force
        }
    }
    Write-Host-Color "Scripts copied to REAPER/Scripts/Subass" "Green"
} else {
    Write-Host-Color "ERROR: Could not find plugin in $projectRoot\plugin" "Red"
}
    
# 5.5 Verify Stress Tool Dependencies
Write-Host-Color "Verifying Ukrainian Stress Tool..." "Cyan"
$stressTool = Join-Path $scriptsPath "stress\ukrainian_stress_tool.py"
if (Test-Path $stressTool) {
    Write-Host "Running stress tool self-check..."
    try {
        $pyCmdRaw = "python"
        if ($env:SUBASS_PYTHON) { $pyCmdRaw = $env:SUBASS_PYTHON }
        $pyCmdArray = $pyCmdRaw -split " "
        $exe = $pyCmdArray[0]
        $extraArgs = @()
        if ($pyCmdArray.Count -gt 1) { $extraArgs = $pyCmdArray[1..($pyCmdArray.Count-1)] }
        
        $argList = $extraArgs + "`"$stressTool`"" + "`"Привіт`""
        $process = Start-Process $exe -ArgumentList $argList -PassThru -NoNewWindow -Wait
        if ($process.ExitCode -eq 0) {
            Write-Host-Color "Stress tool verification successful." "Green"
        } else {
            Write-Host-Color "WARNING: Stress tool verification failed (Exit Code: $($process.ExitCode))." "Yellow"
        }
    } catch {
         Write-Host-Color "WARNING: Failed to run stress tool verification: $($_.Exception.Message)" "Yellow"
    }
}

# 6. Register Action and Menu Item
$kbFile = Join-Path $reaperPath "reaper-kb.ini"
$menuFile = Join-Path $reaperPath "reaper-menu.ini"
$actionId = "RS77777777777777777777777777777777"
$overlayActionId = "RS88888888888888888888888888888888"
$dictActionId = "RS99999999999999999999999999999999"

Write-Host-Color "Updating REAPER configuration..." "Cyan"

if (Test-Path $kbFile) {
    Write-Host-Color "Updating actions in reaper-kb.ini..." "Cyan"
    $scriptRelativePath = "Subass/Subass_Notes.lua"
    $overlayRelativePath = "Subass/overlay/Lionzz_SubOverlay_Subass.lua"
    $dictRelativePath = "Subass/dictionary/Subass_Dictionary.lua"
    $kbContent = [System.IO.File]::ReadAllLines($kbFile)
    
    $newKb = New-Object System.Collections.Generic.List[string]
    $foundMain = $false
    $foundOverlay = $false
    $foundDict = $false
    
    foreach ($line in $kbContent) {
        if ($line -notmatch "Subass_Notes.lua" -and $line -notmatch "Lionzz_SubOverlay_Subass.lua" -and $line -notmatch "Subass_Dictionary.lua") {
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
        } elseif ($line -match "Subass[/\\]+dictionary[/\\]+Subass_Dictionary.lua") {
            if (-not $foundDict) {
                if ($line -match "SCR 4 0 (RS[0-9a-fA-F]+)") { $dictActionId = $matches[1] }
                $newKb.Add($line)
                $foundDict = $true
            }
        }
    }
    
    if (-not $foundMain) { $newKb.Add("SCR 4 0 $actionId ""Custom: Subass Notes"" ""$scriptRelativePath""") }
    if (-not $foundOverlay) { $newKb.Add("SCR 4 0 $overlayActionId ""Custom: Subass SubOverlay (Lionzz)"" ""$overlayRelativePath""") }
    if (-not $foundDict) { $newKb.Add("SCR 4 0 $dictActionId ""Custom: Subass Dictionary"" ""$dictRelativePath""") }
    
    [System.IO.File]::WriteAllLines($kbFile, $newKb)
}

if (-not (Test-Path $menuFile)) {
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
                if ($val -notmatch "Subass" -and $val -ne "0" -and $val -ne "-1000" -and $val -ne "-1001") {
                    $otherItems += $val
                }
            }
        }
    }

    if ($state -eq "before") {
        if ($contentBefore.Count -gt 0 -and $contentBefore[-1] -ne "") { $contentBefore += "" }
        $contentBefore += "[Main Extensions]"
    }

    $finalItems = $otherItems + @("0", "_$actionId Subass: Notes", "_$overlayActionId Subass: SubOverlay (Lionzz)", "_$dictActionId Subass: Dictionary", "0")
    
    $newMenu = New-Object System.Collections.Generic.List[string]
    foreach ($l in $contentBefore) { $newMenu.Add($l) }
    for ($i = 0; $i -lt $finalItems.Count; $i++) {
        $newMenu.Add("item_$i=$($finalItems[$i])")
    }

    if ($contentAfter.Count -gt 0) {
        if ($newMenu[$newMenu.Count-1] -ne "") { $newMenu.Add("") }
        foreach ($l in $contentAfter) { $newMenu.Add($l) }
    }

    $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($menuFile, [string[]]$newMenu, $utf8NoBOM)
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "   INSTALLATION COMPLETE!" -ForegroundColor Green
Write-Host "   You can now open REAPER and find 'Subass Notes'"
Write-Host "   in the Actions list (Ctrl+Alt+S) or in the Extensions menu."
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Pause

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    Pause
}
