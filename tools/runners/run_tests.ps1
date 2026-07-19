$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $RepoRoot
$AnalyzerSettings = Join-Path $RepoRoot "tools/config/PSScriptAnalyzerSettings.psd1"
$QualityRunner = "./tools/runners/quality.sh"
$TestRunner = "./tools/runners/run_tests.sh"
$CoverageMetricsScript = "tools/coverage_metrics.py"

Write-Host "Building Docker Image..."
docker build -t srm-mock -f tests/Dockerfile .

Write-Host "Running PowerShell Lint (PSScriptAnalyzer)..."
Install-Module -Name PSScriptAnalyzer -RequiredVersion 1.25.0 -Scope CurrentUser -Force
Invoke-ScriptAnalyzer -Path $PSCommandPath -Settings $AnalyzerSettings -EnableExit

Write-Host "Running Repository Quality Checks..."
docker run --rm `
    -v "${PWD}:/app" `
    -w /app `
    srm-mock $QualityRunner

$qualityExitCode = $LASTEXITCODE
if ($qualityExitCode -ne 0) {
    Write-Host "Repository quality checks failed!"
    exit $qualityExitCode
}

# Create coverage directory locally
New-Item -ItemType Directory -Force -Path "coverage" | Out-Null

Write-Host "Running Tests (Unit + E2E) with Coverage..."
# We map current directory to /home/pi/coverage/.. parent so we can write to it
# The tools/runners/run_tests.sh expects COVERAGE=1 and checks env vars.
# In tools/runners/run_tests.sh: -v "$(pwd)/$COVERAGE_OUTPUT:/home/pi/coverage"
# We replicate that here.

docker run --rm `
    --security-opt seccomp=unconfined `
    --cap-add SYS_PTRACE `
    -v "${PWD}/coverage:/home/pi/coverage" `
    -e COVERAGE=1 `
    -e COVERAGE_OUTPUT=/home/pi/coverage `
    srm-mock $TestRunner $args

if ($LASTEXITCODE -eq 0) {
    Write-Host "Tests passed! Coverage report generated in ./coverage/"

    # Validate merged final coverage and update the badge from the full-suite report.
    $CoberturaPath = Get-ChildItem -Path "coverage/final" -Filter "cobertura.xml" -Recurse | Select-Object -First 1
    if ($CoberturaPath) {
        [xml]$CoverageXml = Get-Content $CoberturaPath.FullName
        $LineRate = [double]$CoverageXml.coverage.'line-rate'
        $CoveragePercent = [math]::Round($LineRate * 100, 2)

        if ($CoveragePercent -lt 90) {
            Write-Host "Coverage check failed: ${CoveragePercent}% is below the required 90%."
            exit 1
        }

        Write-Host "Updating local coverage badge..."
        python tests/transform_coverage.py $CoberturaPath.FullName

        Write-Host "Coverage and complexity summary (per-file and overall):"
        python $CoverageMetricsScript --input $CoberturaPath.FullName --format text `
            --target-per-file 15 --hard-max-per-file 35 `
            --target-avg 10 --hard-max-avg 25 `
            --enforce-complexity

        if ($LASTEXITCODE -ne 0) {
            Write-Host "Complexity policy check failed."
            exit $LASTEXITCODE
        }
    }
    else {
        Write-Host "Coverage check failed: merged final cobertura.xml was not found under coverage/final/."
        exit 1
    }
}
else {
    Write-Host "Tests failed!"
    exit 1
}
