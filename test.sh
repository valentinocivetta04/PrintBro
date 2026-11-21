#!/bin/bash
# Corre swift test. Con solo Command Line Tools, SwiftPM no encuentra el plugin
# de macros de Swift Testing, así que se le pasa la ruta a mano.
set -euo pipefail
cd "$(dirname "$0")"

TOOLCHAIN="$(dirname "$(dirname "$(xcrun --find swift)")")"
PLUGINS="$TOOLCHAIN/lib/swift/host/plugins/testing"

if [ -d "$PLUGINS" ]; then
    swift test -Xswiftc -plugin-path -Xswiftc "$PLUGINS" "$@"
else
    swift test "$@"
fi
