# ==============================================================================
# 1. EXECUTION POLICY CONFIGURATION
# ==============================================================================
Write-Host "Setting Execution Policy..." -ForegroundColor Cyan
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# ==============================================================================
# 2. DEFINE VARIABLES & OUTPUT PATHS
# ==============================================================================
$computername = $env:COMPUTERNAME
$datapath = "C:\TriageData\$computername"
$logs = "C:\Windows\System32\winevt\Logs"

# Define where you saved your downloaded tools
$toolPath = "C:\ForensicsTools" 

# Create Output Directory
If (!(Test-Path $datapath)) {
    New-Item -ItemType Directory -Force -Path $datapath | Out-Null
}

# ==============================================================================
# 3. NATIVE POWERSHELL COMMANDS (SYSTEM INFORMATION)
# ==============================================================================
Write-Host "Collecting Native System Information..." -ForegroundColor Cyan

Get-LocalUser | Out-File -FilePath "$datapath\LocalUsers.log"
Get-LocalGroup | Out-File -FilePath "$datapath\LocalGroups.log"
Get-CimInstance Win32_OperatingSystem | Out-File -FilePath "$datapath\Win32_OperatingSystem.log"
Get-CimInstance Win32_Processor | Out-File -FilePath "$datapath\Win32_Processor.log"
Get-CimInstance Win32_BIOS | Out-File -FilePath "$datapath\Win32_BIOS.log"
Get-CimInstance Win32_ComputerSystem | Out-File -FilePath "$datapath\Win32_ComputerSystem.log"
Get-NetIPAddress | Out-File -FilePath "$datapath\NetIPAddress.log"
Get-DnsClientCache | Out-File -FilePath "$datapath\DnsClientCache.log"
Get-CimInstance Win32_StartupCommand | Out-File -FilePath "$datapath\Win32_StartupCommand.log"

# ==============================================================================
# 4. SUPPORTING TOOLS (SYSINTERNALS & EXTERNAL BINARIES)
# ==============================================================================
Write-Host "Executing Supporting Tools..." -ForegroundColor Cyan

# Memory Dump Check
if (Test-Path "$toolPath\winpmem_mini_x64_rc2.exe") {
    & "$toolPath\winpmem_mini_x64_rc2.exe" "$datapath\$computername-mem.dmp"
} else {
    Write-Warning "WinPmem not found in $toolPath. Skipping memory dump."
}

# Autoruns Check (Corrected Syntax)
if (Test-Path "$toolPath\autorunsc.exe") {
    & "$toolPath\autorunsc.exe" -a * -m -c -accepteula | ConvertFrom-Csv | Select-Object "Entry", "Description", "Image Path", "Enabled" | Export-Csv -Path "$datapath\AutoRuns.csv" -NoTypeInformation
} else {
    Write-Warning "autorunsc.exe not found in $toolPath. Skipping."
}

# TCPVCon Check
if (Test-Path "$toolPath\tcpvcon64.exe") {
    & "$toolPath\tcpvcon64.exe" -a -c -accepteula | Out-File -FilePath "$datapath\PortInformation.log"
} else {
    Write-Warning "tcpvcon64.exe not found in $toolPath. Skipping."
}

# Handle Check
if (Test-Path "$toolPath\handle.exe") {
    & "$toolPath\handle.exe" -v -accepteula | Out-File -FilePath "$datapath\OpenProcesses.log"
} else {
    Write-Warning "handle.exe not found in $toolPath. Skipping."
}

# Event Log List (Replaced deprecated wmic with native PowerShell)
Get-WinEvent -ListLog * | Select-Object LogName, RecordCount | Out-File -FilePath "$datapath\EventLogList.log"

# ==============================================================================
# 5. ARTIFACT PRESERVATION
# ==============================================================================
Write-Host "Collecting Event Logs (This may take a moment)..." -ForegroundColor Cyan
Copy-Item -Recurse -Path $logs -Destination "$datapath\EventLogs" -ErrorAction SilentlyContinue

# ==============================================================================
# 6. DISK FORENSICS (POWERFORENSICS - MANUAL LOAD)
# ==============================================================================
Write-Host "Performing Disk Analysis..." -ForegroundColor Cyan

# Define the updated path using PowerForensicsv2
$modulePath = "$toolPath\PowerForensicsv2\PowerForensics.psd1"

Write-Host "Importing PowerForensics from local folder..." -ForegroundColor Yellow

if (Test-Path $modulePath) {
    Import-Module $modulePath -Force

    try {
        # Export the master file table (MFT)
        $mft = Get-ForensicFileRecord -VolumeName C: -Index 0
        $mft.CopyFile("$datapath\Export.mft")

        # Get Amcache
        Get-ForensicAmcache -VolumeName C: | Out-File -FilePath "$datapath\Amcache.log"
        
        # Create Forensic Timeline for executables
        Get-ForensicTimeline -VolumeName C: | Where-Object { $_.FileName -like '*.exe' } | Out-File -FilePath "$datapath\ForensicTimeline_EXEs.log"
        
        Write-Host "Disk Analysis Complete!" -ForegroundColor Green
    } catch {
        Write-Warning "A forensic extraction error occurred. Ensure you are running PowerShell as Administrator."
        Write-Warning $_.Exception.Message
    }
} else {
    Write-Warning "PowerForensics module file not found at $modulePath. Please check the folder name."
}

# ==============================================================================
# 7. COMPLETION
# ==============================================================================
Write-Host "All Triage and Forensic Collection Complete. Data saved to $datapath" -ForegroundColor Green