# load-mls-notes.ps1 - Reads project JSON and puts it on the clipboard
param(
    [string]$File = ""
)
$dataDir = Join-Path $PSScriptRoot "..\data"

if ($File -and (Test-Path $File)) {
    $dataFile = $File
} else {
    # Check for active project marker
    $markerFile = Join-Path $dataDir "mls-active.txt"
    if (Test-Path $markerFile) {
        $slug = (Get-Content -Path $markerFile -Raw -Encoding utf8).Trim()
        $dataFile = Join-Path $dataDir "mls-notes-$slug.json"
    } else {
        $dataFile = Join-Path $dataDir "mls-notes.json"
    }
}

if (Test-Path $dataFile) {
    $content = Get-Content -Path $dataFile -Raw -Encoding utf8
    Set-Clipboard -Value $content
}
