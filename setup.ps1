Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$RootDir    = $PSScriptRoot
$ConfigFile = Join-Path $RootDir 'config.json'
$EnvFile    = Join-Path $RootDir '.env'

$ExistingName  = ''
$ExistingTitle = ''
$ExistingKey   = ''

if (Test-Path $ConfigFile) {
    $existing = Get-Content $ConfigFile -Raw | ConvertFrom-Json
    $ExistingName  = $existing.authorName
    $ExistingTitle = $existing.authorTitle
}
if (Test-Path $EnvFile) {
    $line = Get-Content $EnvFile | Where-Object { $_ -match '^OPENROUTER_API_KEY=' }
    if ($line) { $ExistingKey = $line -replace '^OPENROUTER_API_KEY=', '' }
}

$NavyBlack = [System.Drawing.Color]::FromArgb(22, 22, 22)
$Orange    = [System.Drawing.Color]::FromArgb(232, 105, 12)

$Form = New-Object System.Windows.Forms.Form
$Form.Text = 'Weekly Report Bot - Setup'
$Form.Size = New-Object System.Drawing.Size(480, 460)
$Form.StartPosition = 'CenterScreen'
$Form.FormBorderStyle = 'FixedDialog'
$Form.MaximizeBox = $false
$Form.MinimizeBox = $false
$Form.TopMost = $true

$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Size = New-Object System.Drawing.Size(480, 80)
$HeaderPanel.Location = New-Object System.Drawing.Point(0, 0)
$HeaderPanel.BackColor = $NavyBlack
$Form.Controls.Add($HeaderPanel)

$Title1 = New-Object System.Windows.Forms.Label
$Title1.Text = 'DBM'
$Title1.ForeColor = $Orange
$Title1.Font = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
$Title1.Location = New-Object System.Drawing.Point(20, 10)
$Title1.Size = New-Object System.Drawing.Size(200, 32)
$HeaderPanel.Controls.Add($Title1)

$Title2 = New-Object System.Windows.Forms.Label
$Title2.Text = 'Weekly Report Bot - one-time setup'
$Title2.ForeColor = [System.Drawing.Color]::White
$Title2.Font = New-Object System.Drawing.Font('Segoe UI', 10.5)
$Title2.Location = New-Object System.Drawing.Point(20, 46)
$Title2.Size = New-Object System.Drawing.Size(440, 22)
$HeaderPanel.Controls.Add($Title2)

function New-FieldLabel($text, $y) {
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $text
    $lbl.Font = New-Object System.Drawing.Font('Segoe UI', 9.5, [System.Drawing.FontStyle]::Bold)
    $lbl.Location = New-Object System.Drawing.Point(20, $y)
    $lbl.Size = New-Object System.Drawing.Size(440, 18)
    $Form.Controls.Add($lbl)
}

New-FieldLabel 'Your full name (as it should appear on the report)' 100
$NameBox = New-Object System.Windows.Forms.TextBox
$NameBox.Font = New-Object System.Drawing.Font('Segoe UI', 10.5)
$NameBox.Location = New-Object System.Drawing.Point(20, 120)
$NameBox.Size = New-Object System.Drawing.Size(440, 26)
$NameBox.Text = $ExistingName
$Form.Controls.Add($NameBox)

New-FieldLabel 'Your job title' 156
$TitleBox = New-Object System.Windows.Forms.TextBox
$TitleBox.Font = New-Object System.Drawing.Font('Segoe UI', 10.5)
$TitleBox.Location = New-Object System.Drawing.Point(20, 176)
$TitleBox.Size = New-Object System.Drawing.Size(440, 26)
$TitleBox.Text = $ExistingTitle
$Form.Controls.Add($TitleBox)

New-FieldLabel 'OpenRouter API key (used to polish your notes into report language)' 212
$KeyBox = New-Object System.Windows.Forms.TextBox
$KeyBox.Font = New-Object System.Drawing.Font('Segoe UI', 10.5)
$KeyBox.Location = New-Object System.Drawing.Point(20, 232)
$KeyBox.Size = New-Object System.Drawing.Size(440, 26)
$KeyBox.Text = $ExistingKey
$Form.Controls.Add($KeyBox)

$HintLabel = New-Object System.Windows.Forms.Label
$HintLabel.Text = "Get a free key at openrouter.ai/keys. Leave blank and the report`nwill just use your notes as typed, without AI rewriting."
$HintLabel.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
$HintLabel.Font = New-Object System.Drawing.Font('Segoe UI', 8.5, [System.Drawing.FontStyle]::Italic)
$HintLabel.Location = New-Object System.Drawing.Point(20, 262)
$HintLabel.Size = New-Object System.Drawing.Size(440, 36)
$Form.Controls.Add($HintLabel)

$RegisterCheck = New-Object System.Windows.Forms.CheckBox
$RegisterCheck.Text = 'Also set up the automatic Mon-Fri 5:00 PM prompt on this PC'
$RegisterCheck.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
$RegisterCheck.Location = New-Object System.Drawing.Point(20, 306)
$RegisterCheck.Size = New-Object System.Drawing.Size(440, 24)
$RegisterCheck.Checked = $true
$Form.Controls.Add($RegisterCheck)

$SaveButton = New-Object System.Windows.Forms.Button
$SaveButton.Text = 'Save & Finish'
$SaveButton.Size = New-Object System.Drawing.Size(150, 40)
$SaveButton.Location = New-Object System.Drawing.Point(310, 360)
$SaveButton.BackColor = $Orange
$SaveButton.ForeColor = [System.Drawing.Color]::White
$SaveButton.FlatStyle = 'Flat'
$SaveButton.FlatAppearance.BorderSize = 0
$SaveButton.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$SaveButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$Form.Controls.Add($SaveButton)
$Form.AcceptButton = $SaveButton

$Result = $Form.ShowDialog()
if ($Result -ne [System.Windows.Forms.DialogResult]::OK) { exit }

if ([string]::IsNullOrWhiteSpace($NameBox.Text) -or [string]::IsNullOrWhiteSpace($TitleBox.Text)) {
    [System.Windows.Forms.MessageBox]::Show('Name and title are required. Run setup again.', 'Weekly Report Bot') | Out-Null
    exit
}

$Config = [PSCustomObject]@{
    authorName  = $NameBox.Text.Trim()
    authorTitle = $TitleBox.Text.Trim()
}
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($ConfigFile, ($Config | ConvertTo-Json), $Utf8NoBom)

if (-not [string]::IsNullOrWhiteSpace($KeyBox.Text)) {
    [System.IO.File]::WriteAllText($EnvFile, "OPENROUTER_API_KEY=$($KeyBox.Text.Trim())`n", $Utf8NoBom)
}

if ($RegisterCheck.Checked) {
    & (Join-Path $RootDir 'setupTask.ps1')
}

[System.Windows.Forms.MessageBox]::Show(
    "All set, $($Config.authorName)! The bot will prompt you Mon-Fri at 5:00 PM and build your PDF every Friday.",
    'Weekly Report Bot',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
) | Out-Null
