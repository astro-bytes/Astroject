#!/usr/bin/env bash
# Builds each CompileChecks target. `Allowed` must compile; every other target must fail.
# Prints each failing target's errors so the CI log shows what the compiler says.
set -u
cd "$(dirname "$0")"
status=0

if swift build --target Allowed -Xswiftc -warnings-as-errors; then
    echo "PASS Allowed compiles"
else
    echo "FAIL Allowed should compile"
    status=1
fi

for target in ReadsMainActorState BuildsMainActorType CapturesNonSendable; do
    if output=$(swift build --target "$target" -Xswiftc -warnings-as-errors 2>&1); then
        echo "FAIL $target compiled, but it should not"
        status=1
    else
        echo "PASS $target does not compile:"
        echo "$output" | grep -E "error:" | sed 's/^/    /'
    fi
done

exit $status
