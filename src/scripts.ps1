function Ensure-Scoop {
    $scoopCmd = Get-Command scoop -ErrorAction SilentlyContinue

    if ($null -eq $scoopCmd) {
        Write-Host "Scoop not found. Installing Scoop..."
        irm get.scoop.sh | iex
    }
    else {
        Write-Host "Found Scoop."
    }
}

function Ensure-ScoopBucket {
    param([string]$Name) 
    $bucketpath = scoop bucket list  | Select-String -SimpleMatch $Name
    if (-not $bucketpath) {
        Write-Host "Adding bucket: $Name"
        if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host "  -> git required. Installing git..."
            scoop install git
        }
        scoop bucket add $Name
    }
    else {
        Write-Host "Bucket already exists: $Name"
    }
}

function Ensure-Apps {
    param([string]$Name)
    $appsPath = Test-Path "$env:USERPROFILE\scoop\apps\$Name"
    if (-not $appsPath) {
        Write-Host "Installing tool: $Name"
        scoop install $Name
    }
    else {
        Write-Host "Tool exists: $Name"
    }
}

Write-Host "Initializing zhell..."
Ensure-Scoop

Ensure-Apps "yazi"