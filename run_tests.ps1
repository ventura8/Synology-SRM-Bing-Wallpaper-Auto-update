$ErrorActionPreference = "Stop"

Write-Host "Building Docker Image..."
docker build -t srm-mock -f tests/Dockerfile .

# Create coverage directory locally
New-Item -ItemType Directory -Force -Path "coverage" | Out-Null

Write-Host "Running Lint Checks (ShellCheck)..."
docker run --rm srm-mock sh -c "shellcheck *.sh"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Lint checks failed! See output above."
    exit 1
}

Write-Host "Running Tests (Unit + E2E) with Coverage..."
# We map current directory to /home/pi/coverage/.. parent so we can write to it
# The run_tests.sh expects COVERAGE=1 and checks env vars.
# In run_tests.sh: -v "$(pwd)/$COVERAGE_OUTPUT:/home/pi/coverage"
# We replicate that here.

docker run --rm `
    --security-opt seccomp=unconfined `
    --cap-add SYS_PTRACE `
    -v "${PWD}/coverage:/home/pi/coverage" `
    -e COVERAGE=1 `
    -e COVERAGE_OUTPUT=/home/pi/coverage `
    srm-mock ./run_tests.sh $args

if ($LASTEXITCODE -eq 0) {
    Write-Host "Tests passed! Coverage report generated in ./coverage/"
    
    # Update local badge
    $CoberturaPath = Get-ChildItem -Path "coverage" -Filter "cobertura.xml" -Recurse | Select-Object -First 1
    if ($CoberturaPath) {
        Write-Host "Updating local coverage badge..."
        python tests/transform_coverage.py $CoberturaPath.FullName
    }
}
else {
    Write-Host "Tests failed!"
    exit 1
}
