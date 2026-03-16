Write-Host "Intializing zhell..."

$scoopCmd = Get-Command scoop -ErrorAction SilentlyContinue

if ($null -eq $scoopCmd) {
    Write-Host "Scoop not found. Installing Scoop..."
    irm get.scoop.sh | iex
} else {
    Write-Host "Found Scoop."
}