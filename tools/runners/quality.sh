#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

mapfile -t shell_files < <(git ls-files "*.sh" | { grep -v '^node_modules/' || [ $? -eq 1 ]; })
mapfile -t bats_files < <(git ls-files "*.bats" | { grep -v '^node_modules/' || [ $? -eq 1 ]; })
mapfile -t yaml_files < <(git ls-files "*.yml" "*.yaml" | { grep -v '^node_modules/' || [ $? -eq 1 ]; })
mapfile -t json_files < <(git ls-files "*.json" | { grep -v '^node_modules/' || [ $? -eq 1 ]; })
mapfile -t markdown_files < <(git ls-files "*.md" | { grep -v '^node_modules/' || [ $? -eq 1 ]; })

echo "Running shell formatter check (shfmt)..."
if [ "${#shell_files[@]}" -gt 0 ] || [ "${#bats_files[@]}" -gt 0 ]; then
    shfmt -i 4 -ci -d -- "${shell_files[@]}" "${bats_files[@]}"
fi

echo "Running shell lint (ShellCheck)..."
if [ "${#shell_files[@]}" -gt 0 ]; then
    shellcheck --severity=style --external-sources -- "${shell_files[@]}"
fi

echo "Running YAML lint..."
if [ "${#yaml_files[@]}" -gt 0 ]; then
    yamllint -- "${yaml_files[@]}"
fi

echo "Running JSON validation..."
if [ "${#json_files[@]}" -gt 0 ]; then
    for file in "${json_files[@]}"; do
        jq empty "$file" >/dev/null
    done
fi

echo "Running Python format/lint..."
ruff format --check tests/transform_coverage.py tools/*.py
ruff check tests/transform_coverage.py tools/*.py

echo "Running Markdown lint..."
if [ "${#markdown_files[@]}" -gt 0 ]; then
    markdownlint --config .markdownlint.json -- "${markdown_files[@]}"
fi

echo "Running non-Markdown max line-length check..."
python3 tools/check_line_length.py

echo "Running suppression policy check..."
python3 tools/check_forbidden_suppressions.py

echo "Quality checks passed."
