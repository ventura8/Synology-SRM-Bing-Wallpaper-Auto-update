#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

readonly EXCLUDED_PREFIX='^node_modules/'

# List tracked files matching the given pathspecs, minus vendored paths.
tracked_files() {
    local status=0
    git ls-files "$@" | grep -v "$EXCLUDED_PREFIX" || status=$?
    # grep exits 1 when every line is filtered out: an empty list, not an error.
    # Anything above 1 (git or grep failure; pipefail is on) is a real error.
    if [[ "$status" -gt 1 ]]; then
        return "$status"
    fi
    return 0
}

mapfile -t shell_files < <(tracked_files "*.sh")
mapfile -t bats_files < <(tracked_files "*.bats")
mapfile -t yaml_files < <(tracked_files "*.yml" "*.yaml")
mapfile -t json_files < <(tracked_files "*.json")
mapfile -t markdown_files < <(tracked_files "*.md")

echo "Running shell formatter check (shfmt)..."
if [[ "${#shell_files[@]}" -gt 0 ]] || [[ "${#bats_files[@]}" -gt 0 ]]; then
    shfmt -i 4 -ci -d -- "${shell_files[@]}" "${bats_files[@]}"
fi

echo "Running shell lint (ShellCheck)..."
if [[ "${#shell_files[@]}" -gt 0 ]]; then
    shellcheck --severity=style --external-sources -- "${shell_files[@]}"
fi

echo "Running YAML lint..."
if [[ "${#yaml_files[@]}" -gt 0 ]]; then
    yamllint -- "${yaml_files[@]}"
fi

echo "Running JSON validation..."
if [[ "${#json_files[@]}" -gt 0 ]]; then
    for file in "${json_files[@]}"; do
        jq empty "$file" >/dev/null
    done
fi

echo "Running Python format/lint..."
ruff format --check tests/transform_coverage.py tools/*.py
ruff check tests/transform_coverage.py tools/*.py

echo "Running Markdown lint..."
if [[ "${#markdown_files[@]}" -gt 0 ]]; then
    markdownlint --config .markdownlint.json -- "${markdown_files[@]}"
fi

echo "Running non-Markdown max line-length check..."
python3 tools/check_line_length.py

echo "Running suppression policy check..."
python3 tools/check_forbidden_suppressions.py

echo "Quality checks passed."
