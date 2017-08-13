#!/usr/bin/env bash

ULIMIT="$(ulimit -Sn)"
if [ "${ULIMIT}" -lt "100000" ]; then
    echo "ERROR: ulimit open files is too low (${ULIMIT})"
    echo "  -> [MacOS] Execute '00__update_ulimit.sh' and restart your operating system to increase the limit."
    echo "  -> [RHEL & Fedora] Please refer to this article to increase the limit: https://access.redhat.com/solutions/60746"
    exit 1
fi
