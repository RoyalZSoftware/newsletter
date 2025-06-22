#!/bin/bash
export NEWSLETTER_ENV=test
export SPEC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Farbige Ausgabe
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}[PASS]${NC} $msg"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}[FAIL]${NC} $msg"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((TESTS_FAILED++))
    fi
}

# Testlauf: Setup → Tests → Cleanup
run_file_tests() {
    local file="$1"
    source "$file"

    echo "Running tests in $file"

    # Finde alle Funktionen die mit test_ anfangen
    for test_func in $(declare -F | awk '{print $3}' | grep '^test_'); do
        [[ "$(type -t setup)" == "function" ]] && setup
        export LIB_DIR="$SPEC_DIR/../lib"
        source $LIB_DIR/newsletter.sh
        echo $test_func
        $test_func
        [[ "$(type -t cleanup)" == "function" ]] && cleanup
        echo "---"
    done

    # Unload die geladenen test_ Funktionen
    for func in $(declare -F | awk '{print $3}' | grep '^test_'); do
        unset -f "$func"
    done
    [[ "$(type -t setup)" == "function" ]] && unset -f setup
    [[ "$(type -t cleanup)" == "function" ]] && unset -f cleanup
    echo
}

# Alle Test-Dateien durchgehen
for testfile in ${1:-.}/test_*.sh; do
    run_file_tests "$testfile"
done

echo "==============================="
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo "==============================="

((TESTS_FAILED > 0)) && exit 1 || exit 0
