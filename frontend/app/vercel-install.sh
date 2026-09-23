#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/vercel-flutter.sh"
flutter pub get
