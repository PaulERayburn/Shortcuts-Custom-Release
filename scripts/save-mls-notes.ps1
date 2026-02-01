# save-mls-notes.ps1 - Reads JSON from clipboard, writes to project-specific file
$dataDir = Join-Path $PSScriptRoot "..\data"
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }
$clip = Get-Clipboard -Raw
if ($clip) {
    try {
        $json = $clip | ConvertFrom-Json
        if ($json.projectName) {
            $slug = ($json.projectName.ToLower() -replace '[^a-z0-9]+', '-' -replace '^-|-$', '')
            $outFile = Join-Path $dataDir "mls-notes-$slug.json"
            # Write active project marker
            $slug | Out-File -FilePath (Join-Path $dataDir "mls-active.txt") -Encoding utf8 -NoNewline -Force
        } else {
            $outFile = Join-Path $dataDir "mls-notes.json"
        }
    } catch {
        $outFile = Join-Path $dataDir "mls-notes.json"
    }
    $clip | Out-File -FilePath $outFile -Encoding utf8 -Force
}
