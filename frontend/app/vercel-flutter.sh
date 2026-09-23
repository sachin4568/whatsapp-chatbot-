#!/usr/bin/env bash
set -euo pipefail

export FLUTTER_ROOT="${HOME}/flutter"

if [ ! -x "${FLUTTER_ROOT}/bin/flutter" ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${FLUTTER_ROOT}"
fi

export PATH="${FLUTTER_ROOT}/bin:${FLUTTER_ROOT}/bin/cache/dart-sdk/bin:${PATH}"
flutter config --no-analytics
