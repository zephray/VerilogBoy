#!/bin/bash

PASS=0
FAIL=0
for test in *.actual; do
	if cmp "$test" "${test%.actual}.expected" > /dev/null; then
		echo "Passed $test"
		PASS=$((PASS+1))
	else
		echo "Failed $test"
		FAIL=$((FAIL+1))
	fi
done
echo "Passed $PASS tests, failed $FAIL tests."
