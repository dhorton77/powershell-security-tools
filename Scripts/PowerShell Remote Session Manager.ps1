#Requires -Version 5.1

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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
$form.Text = "Remote Session Manager"
$form.Size = New-Object System.Drawing.Size(650,550)
$form.StartPosition = "CenterScreen"
$form.BackColor = "#1E1E1E"
$form.ForeColor = "White"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# =========================
# TITLE
# =========================

$title = New-Object System.Windows.Forms.Label
$title.Text = "PowerShell Remote Session Manager"
$title.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    14,
    [System.Drawing.FontStyle]::Bold
)

$title.Location = New-Object System.Drawing.Point(20,10)
$title.Size = New-Object System.Drawing.Size(500,30)

$form.Controls.Add($title)

# =========================
# MACHINE LABEL
# =========================

$lblMachine = New-Object System.Windows.Forms.Label
$lblMachine.Text = "Machine"
$lblMachine.Location = New-Object System.Drawing.Point(20,60)
$lblMachine.Size = New-Object System.Drawing.Size(100,20)

$form.Controls.Add($lblMachine)

# =========================
# MACHINE COMBOBOX
# =========================

$comboMachine = New-Object System.Windows.Forms.ComboBox
$comboMachine.Location = New-Object System.Drawing.Point(120,60)
$comboMachine.Size = New-Object System.Drawing.Size(300,25)
$comboMachine.DropDownStyle = "DropDownList"

$comboMachine.Items.Add("Windows2019server")
$comboMachine.Items.Add("Windows-11-test")
$comboMachine.Items.Add("Do Not Use")
$comboMachine.Items.Add("Do Not Use")
$comboMachine.Items.Add("Do Not Use")
$comboMachine.Items.Add("Do Not Use")

$comboMachine.SelectedIndex = 0

$form.Controls.Add($comboMachine)

# =========================
# USERNAME
# =========================

$lblUser = New-Object System.Windows.Forms.Label
$lblUser.Text = "Username"
$lblUser.Location = New-Object System.Drawing.Point(20,100)
$lblUser.Size = New-Object System.Drawing.Size(100,20)

$form.Controls.Add($lblUser)

$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Location = New-Object System.Drawing.Point(120,100)
$txtUser.Size = New-Object System.Drawing.Size(300,20)
$txtUser.Text = "Administrator"

$form.Controls.Add($txtUser)

# =========================
# PASSWORD
# =========================

$lblPass = New-Object System.Windows.Forms.Label
$lblPass.Text = "Password"
$lblPass.Location = New-Object System.Drawing.Point(20,140)
$lblPass.Size = New-Object System.Drawing.Size(100,20)

$form.Controls.Add($lblPass)

$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.Location = New-Object System.Drawing.Point(120,140)
$txtPass.Size = New-Object System.Drawing.Size(300,20)
$txtPass.PasswordChar = '*'

$form.Controls.Add($txtPass)

# =========================
# COMMAND LABEL
# =========================

$lblCommand = New-Object System.Windows.Forms.Label
$lblCommand.Text = "Command"
$lblCommand.Location = New-Object System.Drawing.Point(20,180)
$lblCommand.Size = New-Object System.Drawing.Size(100,20)

$form.Controls.Add($lblCommand)

# =========================
# COMMAND TEXTBOX
# =========================

$txtCommand = New-Object System.Windows.Forms.TextBox
$txtCommand.Location = New-Object System.Drawing.Point(120,180)
$txtCommand.Size = New-Object System.Drawing.Size(480,20)
$txtCommand.Text = "hostname"

$form.Controls.Add($txtCommand)

# =========================
# BUTTONS
# =========================

$btnConnect = New-Object System.Windows.Forms.Button
$btnConnect.Text = "Connect"
$btnConnect.Location = New-Object System.Drawing.Point(120,220)
$btnConnect.Size = New-Object System.Drawing.Size(100,35)
$btnConnect.BackColor = "#2E8B57"
$btnConnect.ForeColor = "White"

$form.Controls.Add($btnConnect)

$btnDisconnect = New-Object System.Windows.Forms.Button
$btnDisconnect.Text = "Disconnect"
$btnDisconnect.Location = New-Object System.Drawing.Point(230,220)
$btnDisconnect.Size = New-Object System.Drawing.Size(100,35)
$btnDisconnect.BackColor = "#8B0000"
$btnDisconnect.ForeColor = "White"

$form.Controls.Add($btnDisconnect)

$btnCheck = New-Object System.Windows.Forms.Button
$btnCheck.Text = "Check"
$btnCheck.Location = New-Object System.Drawing.Point(340,220)
$btnCheck.Size = New-Object System.Drawing.Size(100,35)
$btnCheck.BackColor = "#1E90FF"
$btnCheck.ForeColor = "White"

$form.Controls.Add($btnCheck)

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run"
$btnRun.Location = New-Object System.Drawing.Point(450,220)
$btnRun.Size = New-Object System.Drawing.Size(100,35)
$btnRun.BackColor = "#DAA520"
$btnRun.ForeColor = "Black"

$form.Controls.Add($btnRun)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = "Clear"
$btnClear.Location = New-Object System.Drawing.Point(560,220)
$btnClear.Size = New-Object System.Drawing.Size(60,35)

$form.Controls.Add($btnClear)

# =========================
# STATUS LABEL
# =========================

$status = New-Object System.Windows.Forms.Label
$status.Text = "Ready"
$status.Location = New-Object System.Drawing.Point(20,270)
$status.Size = New-Object System.Drawing.Size(500,20)
$status.ForeColor = "Lime"

$status.Font = New-Object System.Drawing.Font(
    "Segoe UI",
    10,
    [System.Drawing.FontStyle]::Bold
)

$form.Controls.Add($status)

# =========================
# OUTPUT WINDOW
# =========================

$output = New-Object System.Windows.Forms.TextBox
$output.Location = New-Object System.Drawing.Point(20,300)
$output.Size = New-Object System.Drawing.Size(600,190)
$output.Multiline = $true
$output.ScrollBars = "Vertical"
$output.ReadOnly = $true
$output.BackColor = "Black"
$output.ForeColor = "Lime"

$output.Font = New-Object System.Drawing.Font(
    "Consolas",
    10
)

$form.Controls.Add($output)

# =========================
# GLOBAL SESSION
# =========================

$script:session = $null

# =========================
# LOG FUNCTION
# =========================

function Write-Log {

    param([string]$Message)

    $timestamp = Get-Date -Format "HH:mm:ss"

    $output.AppendText("[$timestamp] $Message`r`n")

    $output.SelectionStart = $output.Text.Length
    $output.ScrollToCaret()
}

# =========================
# CONNECT BUTTON
# =========================

$btnConnect.Add_Click({

    try {

        $machine = $comboMachine.SelectedItem.ToString()
        $username = $txtUser.Text
        $password = $txtPass.Text

        if ([string]::IsNullOrWhiteSpace($password)) {

            [System.Windows.Forms.MessageBox]::Show(
                "Password cannot be empty"
            )

            return
        }

        # =========================
        # TRUSTED HOSTS CHECK
        # =========================

        Write-Log "Checking TrustedHosts"

        $currentTrustedHosts = (
            Get-Item WSMan:\localhost\Client\TrustedHosts
        ).Value

        if ($currentTrustedHosts -notlike "*$machine*") {

            Write-Log "$machine not found in TrustedHosts"
            Write-Log "Adding $machine to TrustedHosts"

            if ([string]::IsNullOrWhiteSpace($currentTrustedHosts)) {

                Set-Item `
                    WSMan:\localhost\Client\TrustedHosts `
                    -Value $machine `
                    -Force
            }
            else {

                Set-Item `
                    WSMan:\localhost\Client\TrustedHosts `
                    -Value "$currentTrustedHosts,$machine" `
                    -Force
            }

            Write-Log "$machine added to TrustedHosts"
        }
        else {

            Write-Log "$machine already trusted"
        }

        # =========================
        # CREATE CREDENTIAL
        # =========================

        Write-Log "Connecting to $machine"

        $status.Text = "Connecting..."
        $status.ForeColor = "Orange"

        $securePassword = ConvertTo-SecureString `
            $password `
            -AsPlainText `
            -Force

        $credential = New-Object `
            System.Management.Automation.PSCredential (
                $username,
                $securePassword
            )

        # =========================
        # CREATE SESSION
        # =========================

        $script:session = New-PSSession `
            -ComputerName $machine `
            -Credential $credential `
            -ErrorAction Stop

        Write-Log "Connected to $machine"

        $status.Text = "Connected"
        $status.ForeColor = "Lime"
    }
    catch {

        Write-Log "Connection failed: $($_.Exception.Message)"

        $status.Text = "Connection Failed"
        $status.ForeColor = "Red"
    }
})

# =========================
# DISCONNECT BUTTON
# =========================

$btnDisconnect.Add_Click({

    try {

        if ($script:session) {

            Remove-PSSession $script:session

            $script:session = $null

            Write-Log "Session disconnected"

            $status.Text = "Disconnected"
            $status.ForeColor = "Red"
        }
        else {

            Write-Log "No active session"
        }
    }
    catch {

        Write-Log "Disconnect error: $($_.Exception.Message)"
    }
})

# =========================
# CHECK BUTTON
# =========================

$btnCheck.Add_Click({

    if ($script:session) {

        try {

            $sessionState = $script:session.State

            Write-Log "Session state: $sessionState"

            $status.Text = "Session Active"
            $status.ForeColor = "Lime"
        }
        catch {

            Write-Log "Session check failed"
        }
    }
    else {

        Write-Log "No active session"

        $status.Text = "No Session"
        $status.ForeColor = "Red"
    }
})

# =========================
# RUN BUTTON
# =========================

$btnRun.Add_Click({

    if (-not $script:session) {

        Write-Log "No active session"

        return
    }

    try {

        $command = $txtCommand.Text

        if ([string]::IsNullOrWhiteSpace($command)) {

            Write-Log "Command box is empty"

            return
        }

        Write-Log "Running command: $command"

        $status.Text = "Running Command"
        $status.ForeColor = "DodgerBlue"

        $result = Invoke-Command `
            -Session $script:session `
            -ScriptBlock {

                param($cmd)

                Invoke-Expression $cmd

            } `
            -ArgumentList $command `
            -ErrorAction Stop

        Write-Log "===== OUTPUT START ====="

        foreach ($line in $result) {

            Write-Log "$line"
        }

        Write-Log "===== OUTPUT END ====="

        $status.Text = "Command Complete"
        $status.ForeColor = "Lime"
    }
    catch {

        Write-Log "Execution failed: $($_.Exception.Message)"

        $status.Text = "Execution Failed"
        $status.ForeColor = "Red"
    }
})

# =========================
# CLEAR BUTTON
# =========================

$btnClear.Add_Click({

    $output.Clear()
})

# =========================
# STARTUP MESSAGE
# =========================

Write-Log "Remote Session Manager Started"
Write-Log "Select a machine and click Connect"

# =========================
# SHOW FORM
# =========================

[void]$form.ShowDialog()