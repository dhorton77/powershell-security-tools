#Requires -Version 5.1
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =========================
# ELEVATION CHECK
# =========================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# =========================
# HIDE POWERSHELL CONSOLE
# =========================
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@
$consolePtr = [Win32]::GetConsoleWindow()
[Win32]::ShowWindow($consolePtr, 0) | Out-Null

# =========================
# FORM SETUP
# =========================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Continuous Infrastructure & Security Monitor"
$form.Size = New-Object System.Drawing.Size(740, 660)
$form.StartPosition = "CenterScreen"
$form.BackColor = "#121212"
$form.ForeColor = "White"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# =========================
# UI CONTROLS & CONFIGURATION
# =========================
$title = New-Object System.Windows.Forms.Label
$title.Text = "Automated Infrastructure Monitoring Suite"
$title.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$title.Location = New-Object System.Drawing.Point(20, 15)
$title.Size = New-Object System.Drawing.Size(550, 30)
$form.Controls.Add($title)

# Target Machine
$lblMachine = New-Object System.Windows.Forms.Label
$lblMachine.Text = "Target Host:"
$lblMachine.Location = New-Object System.Drawing.Point(20, 65)
$lblMachine.Size = New-Object System.Drawing.Size(90, 20)
$form.Controls.Add($lblMachine)

$comboMachine = New-Object System.Windows.Forms.ComboBox
$comboMachine.Location = New-Object System.Drawing.Point(115, 62)
$comboMachine.Size = New-Object System.Drawing.Size(220, 25)
$comboMachine.DropDownStyle = "DropDown"
$machineList = @("Windows2019server", "Windows-11-test", "127.0.0.1")
$comboMachine.Items.AddRange($machineList)
$comboMachine.SelectedIndex = 0
$form.Controls.Add($comboMachine)

# Username
$lblUser = New-Object System.Windows.Forms.Label
$lblUser.Text = "Username:"
$lblUser.Location = New-Object System.Drawing.Point(355, 65)
$lblUser.Size = New-Object System.Drawing.Size(80, 20)
$form.Controls.Add($lblUser)

$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Location = New-Object System.Drawing.Point(440, 62)
$txtUser.Size = New-Object System.Drawing.Size(240, 20)
$txtUser.Text = "Administrator"
$form.Controls.Add($txtUser)

# Password
$lblPass = New-Object System.Windows.Forms.Label
$lblPass.Text = "Password:"
$lblPass.Location = New-Object System.Drawing.Point(355, 100)
$lblPass.Size = New-Object System.Drawing.Size(80, 20)
$form.Controls.Add($lblPass)

$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.Location = New-Object System.Drawing.Point(440, 97)
$txtPass.Size = New-Object System.Drawing.Size(240, 20)
$txtPass.PasswordChar = '*'
$form.Controls.Add($txtPass)

# =========================
# AUTOMATION CONFIG ROW
# =========================
$lblInterval = New-Object System.Windows.Forms.Label
$lblInterval.Text = "Poll Interval:"
$lblInterval.Location = New-Object System.Drawing.Point(20, 140)
$lblInterval.Size = New-Object System.Drawing.Size(90, 20)
$form.Controls.Add($lblInterval)

$comboInterval = New-Object System.Windows.Forms.ComboBox
$comboInterval.Location = New-Object System.Drawing.Point(115, 137)
$comboInterval.Size = New-Object System.Drawing.Size(100, 25)
$comboInterval.DropDownStyle = "DropDownList"
$comboInterval.Items.Add("5 Seconds")
$comboInterval.Items.Add("10 Seconds")
$comboInterval.Items.Add("30 Seconds")
$comboInterval.Items.Add("60 Seconds")
$comboInterval.SelectedIndex = 1 # 10s Default
$form.Controls.Add($comboInterval)

$btnToggleMonitor = New-Object System.Windows.Forms.Button
$btnToggleMonitor.Text = "▶ START ENGINE"
$btnToggleMonitor.Location = New-Object System.Drawing.Point(230, 132)
$btnToggleMonitor.Size = New-Object System.Drawing.Size(130, 32)
$btnToggleMonitor.BackColor = "#0F4C81"
$btnToggleMonitor.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($btnToggleMonitor)

$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = "Init WinRM"
$btnConnect.Location = New-Object System.Drawing.Point(440, 132)
$btnConnect.Size = New-Object System.Drawing.Size(115, 32)
$btnConnect.BackColor = "#1E4620"
$form.Controls.Add($btnConnect)

$btnDisconnect = New-Object System.Windows.Forms.Button
$btnDisconnect.Text = "Kill WinRM"
$btnDisconnect.Location = New-Object System.Drawing.Point(565, 132)
$btnDisconnect.Size = New-Object System.Drawing.Size(115, 32)
$btnDisconnect.BackColor = "#5C1E1E"
$form.Controls.Add($btnDisconnect)

# Separation Rule
$line = New-Object System.Windows.Forms.Label
$line.Location = New-Object System.Drawing.Point(20, 180)
$line.Size = New-Object System.Drawing.Size(660, 2)
$line.BorderStyle = "Fixed3D"
$form.Controls.Add($line)

# =========================
# LIVE STATUS PANELS
# =========================
$lblHeartbeat = New-Object System.Windows.Forms.Label
$lblHeartbeat.Text = "● ENGINE STOPPED"
$lblHeartbeat.Location = New-Object System.Drawing.Point(20, 195)
$lblHeartbeat.Size = New-Object System.Drawing.Size(200, 20)
$lblHeartbeat.ForeColor = "Gray"
$lblHeartbeat.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblHeartbeat)

$lblLastUpdated = New-Object System.Windows.Forms.Label
$lblLastUpdated.Text = "Last Update: Never"
$lblLastUpdated.Location = New-Object System.Drawing.Point(440, 195)
$lblLastUpdated.Size = New-Object System.Drawing.Size(240, 20)
$lblLastUpdated.TextAlign = "TopRight"
$lblLastUpdated.ForeColor = "DarkGray"
$form.Controls.Add($lblLastUpdated)

# =========================
# MONITORING TERMINAL OUTPUT
# =========================
$output = New-Object System.Windows.Forms.TextBox
$output.Location = New-Object System.Drawing.Point(20, 225)
$output.Size = New-Object System.Drawing.Size(660, 340)
$output.Multiline = $true
$output.ScrollBars = "Vertical"
$output.ReadOnly = $true
$output.BackColor = "Black"
$output.ForeColor = "Lime"
$output.Font = New-Object System.Drawing.Font("Consolas", 9.5)
$form.Controls.Add($output)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = "Clear Log Screen"
$btnClear.Location = New-Object System.Drawing.Point(20, 575)
$btnClear.Size = New-Object System.Drawing.Size(140, 30)
$btnClear.BackColor = "#2D2D2D"
$form.Controls.Add($btnClear)

# =========================
# INTERNAL STATE & ENGINE TIMERS
# =========================
$script:session = $null
$script:engineTimer = New-Object System.Windows.Forms.Timer

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $output.AppendText("[$timestamp] [$Type] $Message`r`n")
    $output.SelectionStart = $output.Text.Length
    $output.ScrollToCaret()
}

# =========================
# WINRM SESSION MANAGERS
# =========================
$btnConnect.Add_Click({
    try {
        $machine = $comboMachine.Text
        $username = $txtUser.Text
        $password = $txtPass.Text

        if ([string]::IsNullOrWhiteSpace($password)) {
            [System.Windows.Forms.MessageBox]::Show("Authentication requires a valid password entry.")
            return
        }

        if ($isAdmin) {
            $currentHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction SilentlyContinue).Value
            if ($currentHosts -notlike "*$machine*") {
                $newHosts = if ([string]::IsNullOrWhiteSpace($currentHosts)) { $machine } else { "$currentHosts,$machine" }
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value $newHosts -Force
            }
        }

        Write-Log "Attempting WinRM connection handshake with $machine..." "CONN"
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

        $script:session = New-PSSession -ComputerName $machine -Credential $credential -ErrorAction Stop
        Write-Log "Remote connection successfully pinned." "SUCCESS"
    }
    catch {
        Write-Log "Connection error occurred: $($_.Exception.Message)" "ERROR"
    }
})

$btnDisconnect.Add_Click({
    if ($script:session) {
        Remove-PSSession $script:session
        $script:session = $null
        Write-Log "Remote session tracking dropped." "WARN"
    }
})

# =========================
# CORE TELEMETRY ENGINE LOOP
# =========================
$ExecuteTelemetryCycle = {
    $machine = $comboMachine.Text
    $lblHeartbeat.ForeColor = "Orange"
    $lblHeartbeat.Text = "● PROCESSING METRICS..."
    
    # Let the UI draw changes immediately
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()

    Write-Log "--- START AUTOMATED DISCOVERY CYCLE ---" "ENGINE"

    # TASK 1: Ping / Route Integrity Check (Deck 1)
    if (Test-Connection -ComputerName $machine -Count 1 -Quiet) {
        Write-Log "Network State: Connected to target host successfully." "NET"
    } else {
        Write-Log "Network State Check: Connection timed out!" "CRITICAL"
        $lblHeartbeat.ForeColor = "Red"
        $lblHeartbeat.Text = "● HOST UNREACHABLE"
        return
    }

    # Session Guard Clause
    if (-not $script:session -or $script:session.State -ne "Opened") {
        Write-Log "Telemetry skip: Active WinRM communication pipe is down." "WARN"
        $lblHeartbeat.ForeColor = "Yellow"
        $lblHeartbeat.Text = "● WINRM OFFLINE"
        return
    }

    try {
        # TASK 2: Port Status & Process Load Analysis (Deck 2)
        $procData = Invoke-Command -Session $script:session -ScriptBlock {
            $topProc = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 1
            $svcCount = (Get-Service | Where-Object { $_.Status -eq "Running" }).Count
            return @{ ProcName = $topProc.Name; Mem = [math]::Round($topProc.WorkingSet / 1MB, 1); SvcCount = $svcCount }
        } -ErrorAction Stop
        Write-Log "Process Monitor: Highest Consumer -> $($procData.ProcName) ($($procData.Mem) MB)" "PROCESS"
        Write-Log "Active Systems: $({$procData.SvcCount}) services currently reporting status code 'Running'" "SERVICE"

        # TASK 3: Common Information Model (CIM) Operating System Telemetry (Deck 3)
        $osData = Invoke-Command -Session $script:session -ScriptBlock {
            $os = Get-CimInstance Win32_OperatingSystem
            return @{ FreeMem = [math]::Round($os.FreePhysicalMemory / 1GB, 2); TotalMem = [math]::Round($os.TotalVisibleMemorySize / 1GB, 2) }
        } -ErrorAction Stop
        Write-Log "CIM OS Resource Stack: $($osData.FreeMem) GB free out of $($osData.TotalMem) GB total architecture storage" "CIM"

        # TASK 4: Auditing Security Event Logs & Access Violations (Decks 4 & 5)
        $securityAudit = Invoke-Command -Session $script:session -ScriptBlock {
            $lookbackTime = (Get-Date).AddSeconds(-($args[0]))
            $failures = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$lookbackTime} -ErrorAction SilentlyContinue
            $newProcesses = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4688; StartTime=$lookbackTime} -ErrorAction SilentlyContinue
            return @{ FailCount = if ($failures) { $failures.Count } else { 0 }; ProcCount = if ($newProcesses) { $newProcesses.Count } else { 0 } }
        } -ArgumentList ($script:engineTimer.Interval / 1000) -ErrorAction Stop

        if ($securityAudit.FailCount -gt 0) {
            Write-Log "ALERT: $($securityAudit.FailCount) Invalid auth attempts identified since last scan tick!" "SECURITY-ANOMALY"
        } else {
            Write-Log "Security Streams: Zero validation failures mapped within this check boundary." "SECURITY"
        }
        Write-Log "Activity Scan: $($securityAudit.ProcCount) total new process execution states spawned in time window." "SECURITY"

    } catch {
        Write-Log "Telemetry exception pipeline fault: $($_.Exception.Message)" "ERROR"
    }

    # Reset Live Heartbeat Status
    $lblLastUpdated.Text = "Last Update: $(Get-Date -Format 'HH:mm:ss')"
    $lblHeartbeat.ForeColor = "Lime"
    $lblHeartbeat.Text = "● ENGINE ACTIVE (POLLING)"
}

# Assign the method directly to the Timer Tick Event Handler
$script:engineTimer.Add_Tick($ExecuteTelemetryCycle)

# =========================
# AUTOMATION SWITCH TRIGGER
# =========================
$btnToggleMonitor.Add_Click({
    if ($script:engineTimer.Enabled) {
        # STOP RUNNING
        $script:engineTimer.Stop()
        $btnToggleMonitor.Text = "▶ START ENGINE"
        $btnToggleMonitor.BackColor = "#0F4C81"
        $lblHeartbeat.ForeColor = "Gray"
        $lblHeartbeat.Text = "● ENGINE STOPPED"
        $comboInterval.Enabled = $true
        Write-Log "Automated background thread processing loop has broken." "ENGINE"
    } else {
        # START RUNNING
        $intervalSeconds = switch($comboInterval.SelectedItem.ToString()) {
            "5 Seconds"  { 5 }
            "10 Seconds" { 10 }
            "30 Seconds" { 30 }
            "60 Seconds" { 60 }
            Default      { 10 }
        }
        
        $script:engineTimer.Interval = $intervalSeconds * 1000
        $comboInterval.Enabled = $false
        $btnToggleMonitor.Text = "■ STOP ENGINE"
        $btnToggleMonitor.BackColor = "#891A1A"
        
        Write-Log "Continuous loop active. Refresh profile window locked to target interval of $intervalSeconds seconds." "ENGINE"
        $script:engineTimer.Start()
        
        # Fire initial sweep instantly without stalling UI setup
        & $ExecuteTelemetryCycle
    }
})

$btnClear.Add_Click({ $output.Clear() })

# =========================
# APPLICATION BOOTSTAGE
# =========================
if (-not $isAdmin) {
    Write-Log "WARNING: System constraints detected. Run session instance with local Administrator privileges to inspect System Security Logs." "WARN"
}
Write-Log "Monitoring workspace initialization complete. Awaiting structural engine commands." "INFO"

[void]$form.ShowDialog()

# Destructor Block
if ($script:engineTimer.Enabled) { $script:engineTimer.Stop() }
if ($script:session) { Remove-PSSession $script:session -ErrorAction SilentlyContinue }
$form.Dispose()