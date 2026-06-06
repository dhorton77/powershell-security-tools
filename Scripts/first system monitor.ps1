Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "System Health Monitor"
$form.Size = New-Object System.Drawing.Size(400,300)

# Create button
$button = New-Object System.Windows.Forms.Button
$button.Text = "Check IPs"
$button.Size = New-Object System.Drawing.Size(100,30)
$button.Location = New-Object System.Drawing.Point(140,20)

# Create listbox
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Size = New-Object System.Drawing.Size(350,180)
$listBox.Location = New-Object System.Drawing.Point(20,60)

# Add button click event
$button.Add_Click({

    $listBox.Items.Clear()

    1..50 | ForEach-Object {

        $ip = "192.168.1.$_"

        if (Test-Connection $ip -Count 1 -Quiet) {
            $listBox.Items.Add("$ip is ONLINE")
        }
        else {
            $listBox.Items.Add("$ip is OFFLINE")
        }

    }

})

# Add controls to form
$form.Controls.Add($button)
$form.Controls.Add($listBox)

# Show form
$form.ShowDialog()