#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=$(mktemp -d)
swiftc -O DigimonWatch/Core/Tuning.swift DigimonWatch/Core/World.swift \
       DigimonWatch/Core/Simulator.swift DigimonWatch/Core/Evolution.swift \
       DigimonWatch/Core/Schedule.swift \
       Tests/main.swift -o "$OUT/kc"
"$OUT/kc"
rm -rf "$OUT"
