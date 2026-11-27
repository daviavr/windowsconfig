# Builds (or rebuilds) a lean Delphi 10.3 IDE profile that skips packages the
# day-to-day VCL/ICS service projects never use, which roughly halves the
# package-loading part of IDE startup.
#
# The lean profile is a copy of the normal one, started with:
#     bds.exe -pDelphi -np -rBDSLean
# The normal profile (HKCU\Software\Embarcadero\BDS) is only read, never changed.
#
# Re-running this script throws the lean profile away and copies the normal one
# again, so run it after changing IDE settings in the normal profile.
# The disabled packages are only unticked: inside the lean IDE they can be
# re-enabled under Component > Install Packages.
#
# Usage:  powershell -ExecutionPolicy Bypass -File delphi-lean-profile.ps1
#         ... -Remove     deletes the lean profile again

param([switch]$Remove)

$ErrorActionPreference = 'Stop'

$BdsVersion  = '20.0'
$ProfileName = 'BDSLean'
$Bds         = 'C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\bds.exe'

$srcKey   = "HKCU\Software\Embarcadero\BDS\$BdsVersion"
$dstRoot  = "HKCU\Software\Embarcadero\$ProfileName"
$srcData  = "$env:APPDATA\Embarcadero\BDS\$BdsVersion"
$dstData  = "$env:APPDATA\Embarcadero\$ProfileName"
$shortcut = Join-Path ([Environment]::GetFolderPath('Programs')) 'Delphi 10.3 Lean.lnk'

# IDE packages (Known IDE Packages): mobile/Linux tooling, FireMonkey designer,
# GetIt, welcome page, modelling, HTML designer, translation tools and the like.
$IdePackages = @(
    'GetIt', 'getitide', 'GuidedTour', 'startpageide', 'TrackingSystem',
    'MultidevicePreview', 'LivePreview', 'MirrorHub', 'DeviceManager', 'sdkmgride',
    'ios32debugide', 'ios64debugide', 'gdbdebugcore', 'gdbdebugide',
    'profiledeployide', 'profilemgride',
    'delphifmxmobile', 'delphifmxide',
    'tgide', 'DataExplorerIDE', 'htmide', 'mlcc', 'iteidew32',
    'unittestide', 'tlbview', 'asmview'
)

# Design-time packages (Known Packages): component sets not present in any form
# of the projects (FireMonkey, FireDAC, dbExpress, DataSnap, SOAP, InterBase,
# ADO, REST, LiveBindings, TeeChart, Indy) plus Subversion/Mercurial integration.
$DesignPackages = @(
    'dclMetropolisUILiveTile', 'hgide', 'svnide',
    'dclbindcomp', 'dclbindcompfmx', 'dclbindcompvcl', 'dclbindcompdbx', 'dclBindCompFireDAC',
    'dcltethering', 'dclshare', 'dclappanalytics', 'dclmid', 'dcl31w', 'applet', 'dclmlwiz',
    'MobileWizardExpert',
    'DataExplorerService', 'DataExplorerFireDACPlugin', 'DataExplorerDBXPlugin', 'DataExplorerDBXPluginInt',
    'dclDBXDrivers', 'dclDBXDriversInt', 'dcldbx', 'dcldbxcds',
    'dclIPIndyImpl', 'dclIndyCore', 'dclIndyProtocols',
    'dclRESTBackendComponents', 'dclRESTComponents', 'dclCloudService',
    'dclFireDAC', 'dclFMXFireDAC', 'dclVclFireDAC',
    # fmxstyledesigner must stay enabled: with it disabled alongside the IDE
    # packages above, the IDE dies on close with an access violation in rtl260.bpl.
    'dclfmxstd',
    'dcldsnapxml', 'dclmcn', 'dclsoapmidas', 'dclsoap', 'dclsoapserver',
    'dclnetdb', 'dclado', 'dclib', 'ibmonitor',
    'dclFMXtee9', 'dcltee9',
    # IDE git integration (menus/history; git itself is used from the shell),
    # data-aware component designers and gesture components.
    'gitide', 'dcldb', 'dclvcldb', 'dcltouch'
)

function Remove-LeanProfile {
    if (Test-Path "Registry::$dstRoot") { Remove-Item "Registry::$dstRoot" -Recurse -Force }
    if (Test-Path $dstData) { Remove-Item $dstData -Recurse -Force }
    if (Test-Path $shortcut) { Remove-Item $shortcut -Force }
}

# Moves the listed packages from an "enabled" key to its "disabled" twin.
function Disable-Packages([string]$From, [string]$To, [string[]]$Names) {
    if (-not (Test-Path $From)) { return 0 }
    if (-not (Test-Path $To)) { New-Item $To -Force | Out-Null }
    $key = Get-Item $From
    $count = 0
    foreach ($value in $key.GetValueNames()) {
        # "$(BDS)\Bin\GetIt260.bpl" -> "GetIt"
        $base = [IO.Path]::GetFileNameWithoutExtension($value) -replace '260$', ''
        if ($Names -contains $base) {
            Set-ItemProperty -LiteralPath $To -Name $value -Value $key.GetValue($value)
            Remove-ItemProperty -LiteralPath $From -Name $value
            $count++
        }
    }
    return $count
}

if (Get-Process bds -ErrorAction SilentlyContinue |
        Where-Object { (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)").CommandLine -match "-r$ProfileName" }) {
    throw "A Delphi IDE using the $ProfileName profile is running. Close it first."
}

Remove-LeanProfile
if ($Remove) { "Lean profile removed."; return }

if (-not (Test-Path "Registry::$srcKey")) { throw "Normal profile not found: $srcKey" }

reg.exe copy $srcKey "$dstRoot\$BdsVersion" /s /f | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Copying the registry profile failed." }

New-Item -ItemType Directory -Force $dstData | Out-Null
Copy-Item $srcData (Join-Path $dstData $BdsVersion) -Recurse -Force

$root = "HKCU:\Software\Embarcadero\$ProfileName\$BdsVersion"
$ide  = Disable-Packages "$root\Known IDE Packages"        "$root\Disabled IDE Packages"        $IdePackages
$ide += Disable-Packages "$root\Known IDE Packages\Delphi" "$root\Disabled IDE Packages\Delphi" $IdePackages
$dsn  = Disable-Packages "$root\Known Packages"            "$root\Disabled Packages"            $DesignPackages

$lnk = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcut)
$lnk.TargetPath = $Bds
$lnk.Arguments = "-pDelphi -np -r$ProfileName"
$lnk.WorkingDirectory = Split-Path $Bds
$lnk.Description = 'Delphi 10.3 with unused packages disabled'
$lnk.Save()

"Lean profile '$ProfileName' built: $ide IDE packages and $dsn design packages disabled."
"Start it with: `"$Bds`" -pDelphi -np -r$ProfileName   (or the 'Delphi 10.3 Lean' Start Menu entry)"
