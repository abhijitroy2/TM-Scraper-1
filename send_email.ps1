# PowerShell script to send email via Outlook COM object
# Usage: .\send_email.ps1 [workflow_log_path]

param(
    [string]$WorkflowLog = ""
)

# Email configuration
$EmailTo = "abbey.roy@gmail.com"
$EmailSubject = "Property Analysis Results - $(Get-Date -Format 'yyyy-MM-dd')"

# Directories to search for result files
$AnalyserDir = "C:\Users\OEM\NZ Property Analyser"
$FlipOutputDir = Join-Path $AnalyserDir "output"
$RentalOutputDir = Join-Path $AnalyserDir "output"
$FlipOutputDirAlt = Join-Path $AnalyserDir "flip_output"
$RentalOutputDirAlt = Join-Path $AnalyserDir "rental_output"

# Initialize email body
$EmailBody = @"
Property Analysis Workflow Results

Execution Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

"@

# Collect Excel files from analysis outputs
$Attachments = @()

# Function to find Excel files in a directory
function Find-ExcelFiles {
    param([string]$Directory)
    
    if (Test-Path $Directory) {
        $files = Get-ChildItem -Path $Directory -Filter "*.xlsx" -ErrorAction SilentlyContinue
        return $files
    }
    return @()
}

# Search for flip analysis results
$EmailBody += "`nFlip Analysis Results:`n"
$flipFiles = @()
$flipFiles += Find-ExcelFiles $FlipOutputDir
$flipFiles += Find-ExcelFiles $FlipOutputDirAlt

if ($flipFiles.Count -gt 0) {
    $EmailBody += "Found $($flipFiles.Count) file(s):`n"
    foreach ($file in $flipFiles) {
        $EmailBody += "  - $($file.Name)`n"
        $Attachments += $file.FullName
    }
} else {
    $EmailBody += "  No Excel files found in flip output directories`n"
}

# Search for rental analysis results
$EmailBody += "`nRental Analysis Results:`n"
$rentalFiles = @()
$rentalFiles += Find-ExcelFiles $RentalOutputDir
$rentalFiles += Find-ExcelFiles $RentalOutputDirAlt

if ($rentalFiles.Count -gt 0) {
    $EmailBody += "Found $($rentalFiles.Count) file(s):`n"
    foreach ($file in $rentalFiles) {
        $EmailBody += "  - $($file.Name)`n"
        $Attachments += $file.FullName
    }
} else {
    $EmailBody += "  No Excel files found in rental output directories`n"
}

# Add workflow log if provided
if ($WorkflowLog -ne "" -and (Test-Path $WorkflowLog)) {
    $EmailBody += "`nWorkflow Log:`n"
    $EmailBody += "  See attached log file for detailed execution information.`n"
    $Attachments += $WorkflowLog
}

# Add summary
$EmailBody += "`n---`n"
$EmailBody += "Total attachments: $($Attachments.Count)`n"
$EmailBody += "`nThis is an automated message from the Property Analysis Workflow.`n"

# Add legal disclaimers
$EmailBody += "`n`n---`n"
$EmailBody += "LEGAL NOTICE`n"
$EmailBody += "---`n"
$EmailBody += "Copyright (c) $(Get-Date -Format 'yyyy') All rights reserved.`n"
$EmailBody += "`n"
$EmailBody += "This email and its contents are confidential and proprietary. Do not forward,`n"
$EmailBody += "distribute, copy, or disclose this email or any attachments without express`n"
$EmailBody += "written authorization from the sender.`n"
$EmailBody += "`n"
$EmailBody += "The information contained in this email is intended solely for the use of the`n"
$EmailBody += "individual or entity to which it is addressed. If you are not the intended`n"
$EmailBody += "recipient, you are hereby notified that any disclosure, copying, distribution,`n"
$EmailBody += "or use of the contents of this email is strictly prohibited.`n"
$EmailBody += "`n"
$EmailBody += "If you have received this email in error, please notify the sender immediately`n"
$EmailBody += "and delete this email and all attachments from your system.`n"

try {
    # Wait a moment to ensure Outlook is ready
    Start-Sleep -Seconds 2
    
    # Create Outlook COM object with retry
    $Outlook = $null
    $maxRetries = 3
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries -and $Outlook -eq $null) {
        try {
            Write-Host "Attempting to create Outlook COM object (attempt $($retryCount + 1)/$maxRetries)..."
            $Outlook = New-Object -ComObject Outlook.Application
            Write-Host "Outlook COM object created successfully"
        }
        catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Host "Failed to create Outlook COM object, retrying in 2 seconds..."
                Start-Sleep -Seconds 2
            } else {
                throw
            }
        }
    }
    
    if ($Outlook -eq $null) {
        throw "Failed to create Outlook COM object after $maxRetries attempts"
    }
    
    # Create mail item
    Write-Host "Creating mail item..."
    $Mail = $Outlook.CreateItem(0)  # 0 = olMailItem
    
    # Set email properties
    Write-Host "Setting email properties..."
    $Mail.To = $EmailTo
    $Mail.Subject = $EmailSubject
    $Mail.Body = $EmailBody
    $Mail.BodyFormat = 1  # 1 = olFormatPlain
    
    # Add attachments with validation
    $attachmentCount = 0
    foreach ($attachment in $Attachments) {
        if (Test-Path $attachment) {
            try {
                $Mail.Attachments.Add($attachment) | Out-Null
                Write-Host "Added attachment: $attachment"
                $attachmentCount++
            }
            catch {
                Write-Warning "Failed to add attachment: $attachment - $($_.Exception.Message)"
            }
        } else {
            Write-Warning "Attachment file not found: $attachment"
        }
    }
    
    Write-Host "Total attachments added: $attachmentCount"
    
    # Send email
    Write-Host "Sending email..."
    $Mail.Send()
    Write-Host "Email sent successfully to $EmailTo"
    Write-Host "Subject: $EmailSubject"
    Write-Host "Attachments: $attachmentCount"
    
    # Cleanup
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Mail) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Outlook) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    exit 0
}
catch {
    Write-Error "Failed to send email: $($_.Exception.Message)"
    Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Error $_.Exception.StackTrace
    exit 1
}

