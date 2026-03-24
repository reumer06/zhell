Write-Host "Initializing zhell..."

$scoopCmd = Get-Command scoop -ErrorAction SilentlyContinue

if ($null -eq $scoopCmd) {
    Write-Host "Scoop not found. Installing Scoop..."
    irm get.scoop.sh | iex
    Write-Host "Installed Scoop successfully.`nAdding Extras..."
    scoop bucket add versions
    scoop bucket add extras
} else {
    Write-Host "Found Scoop."
}