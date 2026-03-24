function Ensure-Scoop {
    $scoopCmd = Get-Command scoop -ErrorAction SilentlyContinue

    if ($null -eq $scoopCmd) {
        Write-Host "Scoop not found. Installing..." -ForegroundColor Cyan
        irm get.scoop.sh | iex
    }
    else {
        Write-Host "✓ Scoop found." -ForegroundColor Green
    }
}

function Ensure-ScoopBucket {
    param([string]$Name) 
    $bucketpath = scoop bucket list  | Select-String -SimpleMatch $Name
    if (-not $bucketpath) {
        Write-Host "Adding bucket: $Name" -ForegroundColor Cyan
        if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host "  -> git required." -ForegroundColor Red
            Write-Host "Installing git..." -ForegroundColor cyan
            scoop install git
        }
        scoop bucket add $Name
    }
    else {
        Write-Host "✓ Bucket exists: $Name" -ForegroundColor Green
    }
}

function Ensure-Apps {
    param([string]$Name)
    $appsPath = Test-Path "$env:USERPROFILE\scoop\apps\$Name"
    if (-not $appsPath) {
        Write-Host "Installing tool: $Name"  -ForegroundColor Cyan
        scoop install $Name
    }
    else {
        Write-Host "✓ Tool exists: $Name" -ForegroundColor Green
    }
}

Write-Host "Initializing zhell environment..." -ForegroundColor Yellow
Ensure-Scoop

Ensure-ScoopBucket "versions"
Ensure-ScoopBucket "extras"

Ensure-Apps "yazi"