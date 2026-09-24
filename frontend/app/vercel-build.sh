#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/vercel-flutter.sh"

if [ "${VERCEL:-0}" = "1" ] && [ -z "${API_URL:-}" ]; then
	echo "API_URL must be configured in Vercel before building."
	exit 1
fi

flutter build web --release --base-href / \
	--dart-define="API_URL=${API_URL:-https://whatsapp-chatbot-tvds.onrender.com}"
