Write-Host "Initializing zhell..."

$scoopCmd = Get-Command scoop -ErrorAction SilentlyContinue

if ($null -eq $scoopCmd) {
    Write-Host "Scoop not found. Installing Scoop..."
    irm get.scoop.sh | iex
}
else {
    Write-Host "Found Scoop."
}

function EnsureScoopBucket {
    param([string]$Name) 
    $bucketExists = scoop bucket list  | Select-String -SimpleMatch $Name
    if (-not $bucketExists) {
        Write-Host "Adding bucket: $Name"
        scoop bucket add $Name
    }
    else {
        Write-Host "Bucket already exits: $Name"
    }
}

function EnsureTool {
    param([string]$Name)
    $toolExits = scoop list | Select-String -SimpleMatch $Name
    if (-not $toolExits) {
        Write-Host "Installing tool: $Name"
        scoop install $Name
    } else {
        Write-Host "Tool exits: $Name"
    }
}