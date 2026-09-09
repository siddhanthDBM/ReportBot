Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$RootDir  = $PSScriptRoot
$DataDir  = Join-Path $RootDir 'data'
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null

$Today   = Get-Date
$DowNum  = [int]$Today.DayOfWeek                       # Sunday=0 .. Saturday=6
$ToMonday = if ($DowNum -eq 0) { -6 } else { 1 - $DowNum }
$Monday  = $Today.Date.AddDays($ToMonday)
$Friday  = $Monday.AddDays(4)
$DayName = $Today.DayOfWeek.ToString()

$WeekStartStr = $Monday.ToString('yyyy-MM-dd')
$WeekEndStr   = $Friday.ToString('yyyy-MM-dd')
$DataFile     = Join-Path $DataDir "Week of $WeekStartStr.json"

# ---------- Build the dialog ----------
$Form = New-Object System.Windows.Forms.Form
$Form.Text = 'Weekly Report Bot'
$Form.Size = New-Object System.Drawing.Size(480, 400)
$Form.StartPosition = 'CenterScreen'
$Form.FormBorderStyle = 'FixedDialog'
$Form.MaximizeBox = $false
$Form.MinimizeBox = $false
$Form.BackColor = [System.Drawing.Color]::White
$Form.TopMost = $true

$NavyColor = [System.Drawing.Color]::FromArgb(31, 58, 95)
$GoldColor = [System.Drawing.Color]::FromArgb(227, 160, 8)

$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Size = New-Object System.Drawing.Size(480, 78)
$HeaderPanel.Location = New-Object System.Drawing.Point(0, 0)
$HeaderPanel.BackColor = $NavyColor
$Form.Controls.Add($HeaderPanel)

$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = 'What did you do today?'
$TitleLabel.ForeColor = [System.Drawing.Color]::White
$TitleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$TitleLabel.Location = New-Object System.Drawing.Point(20, 14)
$TitleLabel.Size = New-Object System.Drawing.Size(440, 28)
$HeaderPanel.Controls.Add($TitleLabel)

$SubLabel = New-Object System.Windows.Forms.Label
$SubLabel.Text = "$DayName, $($Today.ToString('MMMM d, yyyy'))"
$SubLabel.ForeColor = [System.Drawing.Color]::FromArgb(201, 216, 239)
$SubLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
$SubLabel.Location = New-Object System.Drawing.Point(20, 46)
$SubLabel.Size = New-Object System.Drawing.Size(440, 20)
$HeaderPanel.Controls.Add($SubLabel)

$HintLabel = New-Object System.Windows.Forms.Label
$HintLabel.Text = 'Tip: put one task per line for a cleaner report.'
$HintLabel.ForeColor = [System.Drawing.Color]::FromArgb(107, 114, 128)
$HintLabel.Font = New-Object System.Drawing.Font('Segoe UI', 8.5, [System.Drawing.FontStyle]::Italic)
$HintLabel.Location = New-Object System.Drawing.Point(20, 90)
$HintLabel.Size = New-Object System.Drawing.Size(440, 18)
$Form.Controls.Add($HintLabel)

$TextBox = New-Object System.Windows.Forms.TextBox
$TextBox.Multiline = $true
$TextBox.ScrollBars = 'Vertical'
$TextBox.Font = New-Object System.Drawing.Font('Segoe UI', 10.5)
$TextBox.Location = New-Object System.Drawing.Point(20, 114)
$TextBox.Size = New-Object System.Drawing.Size(440, 180)
$TextBox.BorderStyle = 'FixedSingle'
$Form.Controls.Add($TextBox)

$SaveButton = New-Object System.Windows.Forms.Button
$SaveButton.Text = 'Save'
$SaveButton.Size = New-Object System.Drawing.Size(120, 38)
$SaveButton.Location = New-Object System.Drawing.Point(340, 310)
$SaveButton.BackColor = $GoldColor
$SaveButton.ForeColor = [System.Drawing.Color]::White
$SaveButton.FlatStyle = 'Flat'
$SaveButton.FlatAppearance.BorderSize = 0
$SaveButton.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$SaveButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$Form.Controls.Add($SaveButton)
$Form.AcceptButton = $SaveButton

$RemindButton = New-Object System.Windows.Forms.Button
$RemindButton.Text = 'Remind me in 15 min'
$RemindButton.Size = New-Object System.Drawing.Size(160, 38)
$RemindButton.Location = New-Object System.Drawing.Point(20, 310)
$RemindButton.FlatStyle = 'Flat'
$RemindButton.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$RemindButton.DialogResult = [System.Windows.Forms.DialogResult]::Retry
$Form.Controls.Add($RemindButton)

$Result = $Form.ShowDialog()

if ($Result -eq [System.Windows.Forms.DialogResult]::Retry) {
    Start-Sleep -Seconds 900
    & $PSCommandPath
    exit
}

if ($Result -ne [System.Windows.Forms.DialogResult]::OK -or [string]::IsNullOrWhiteSpace($TextBox.Text)) {
    exit
}

$Lines = $TextBox.Text -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

# ---------- Load / create this week's data file ----------
if (Test-Path $DataFile) {
    $Json = Get-Content $DataFile -Raw | ConvertFrom-Json
} else {
    $Json = [PSCustomObject]@{
        weekStart = $WeekStartStr
        weekEnd   = $WeekEndStr
        days      = [PSCustomObject]@{}
    }
}

$Json.days | Add-Member -NotePropertyName $DayName -NotePropertyValue $Lines -Force

$Json | ConvertTo-Json -Depth 6 | Set-Content -Path $DataFile -Encoding UTF8

# ---------- Friday: generate the PDF ----------
if ($DayName -eq 'Friday') {
    $NodeCmd = Get-Command node -ErrorAction SilentlyContinue
    $NodeExe = if ($NodeCmd) { $NodeCmd.Source } else { 'C:\nodejs\node.exe' }
    & $NodeExe (Join-Path $RootDir 'generateReport.js') $DataFile
}
