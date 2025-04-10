#!/bin/bash

set -euo pipefail
trap 'echo "failed:$LINENO \"$BASH_COMMAND\""' ERR

usage() {
    echo "Usage: $0 <program> <tests_dir>"
    echo
    echo "Arguments:"
    echo "  <program>     Path to the binary to test"
    echo "  <tests_dir>   Directory containing test input/output files"
    echo
    echo "Returns: count of failed tests"
    echo
    echo "Each test consists of a directory test/ with:"
    echo "  - optional args file containing command arguments"
    echo "  - input file passed to the binary by path"
    echo "  - expected file with the expected result"
    echo "  - output.txt file the output of the last test execution"
    echo
    echo "Example:"
    echo "  $0 ./build/bin tests/"
}

case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
esac

if [ $# -ne 2 ]; then
    usage
    exit 1
fi

program="$1"
tests_dir="$2"

echo "Running test..."

if [ "$program" != ./\* ]; then
    program="./$program"
fi

failed=0
for test in "$tests_dir"/*/; do
    testname=$(basename "$test")

    test_args=$(cat "$test/args" 2>/dev/null || true)
    test_input="$test/input"
    test_expected="$test/expected"
    test_output="$test/output.txt"

    if [ ! -f "$test_input" ]; then
        echo "Skipping $testname: missing input file"
        continue
    fi

    if [ ! -f "$test_expected" ]; then
        echo "Skipping $testname: missing expected file"
        continue
    fi

    echo -n "Test $testname: "

    # execute program and discard control output
    $program $test_args <"$test_input" >"$test_output" 2>/dev/null

    if diff=$(diff "$test_expected" "$test_output"); then
        echo "PASSED"
    else
        echo "FAILED"
        echo "  DIFF:"
        echo "$diff"
        failed=$((failed+1))
    fi
done

exit $failed
