#!/usr/bin/env bash
# Runs the named tests in tests/ and keeps going after a failure, so CI shows
# every failed test. Run: .github/scripts/run-tests.sh abbr.zsh zsh-options.sh
cd "$(dirname "$0")/../.." || exit 1
fail=0
for t in "$@"; do
  echo "::group::$t"
  if "tests/$t"; then
    echo "::endgroup::"
  else
    echo "::endgroup::"
    echo "::error title=tests/$t::tests/$t failed"
    fail=1
  fi
done
exit $fail
