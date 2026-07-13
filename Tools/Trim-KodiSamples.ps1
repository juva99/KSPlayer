param(
    [Parameter(Mandatory)]
    [string]$OriginalSamplesDirectory,

    [Parameter(Mandatory)]
    [string]$FixtureOutputDirectory
)

$ErrorActionPreference = 'Stop'
$catalogPath = Join-Path $PSScriptRoot '..\Tests\KSPlayerTests\Resources\kodi-samples.json'

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    throw 'ffmpeg is required.'
}
if (-not (Test-Path -LiteralPath $OriginalSamplesDirectory -PathType Container)) {
    throw "Input directory does not exist: $OriginalSamplesDirectory"
}

New-Item -ItemType Directory -Force -Path $FixtureOutputDirectory | Out-Null
$samples = Get-Content -Raw -LiteralPath $catalogPath | ConvertFrom-Json

foreach ($sample in $samples) {
    if ($sample.container -in @('YouTube', 'Collection', 'Archive')) {
        continue
    }

    $inputFile = Join-Path $OriginalSamplesDirectory $sample.fileName
    if (-not (Test-Path -LiteralPath $inputFile -PathType Leaf)) {
        Write-Warning "Skipping missing source: $inputFile"
        continue
    }

    $extension = [IO.Path]::GetExtension($sample.fileName)
    $outputFile = Join-Path $FixtureOutputDirectory "$($sample.id)-3s$extension"

    # Stream-copying preserves HDR, HDR10+, Dolby Vision, and original codec metadata.
    & ffmpeg -hide_banner -loglevel warning -y -ss 00:00:00 -i $inputFile -t 3 -map 0 -c copy -avoid_negative_ts make_zero $outputFile
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed for $inputFile"
    }
}
