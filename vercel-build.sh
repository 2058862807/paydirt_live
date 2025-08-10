#!/usr/bin/env bash
set -euo pipefail
FLUTTER_VERSION=3.29.2
CACHE="$HOME/flutter_$FLUTTER_VERSION"

# Download Flutter if not cached
if [ ! -d "$CACHE" ]; then
  curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
  | tar -xJ -C "$HOME"
  mv "$HOME/flutter" "$CACHE"
fi

export PATH="$CACHE/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get

# Pass Vercel env to Flutter
DEFINES=()
[ -n "${API_BASE_URL:-}" ] && DEFINES+=(--dart-define=API_BASE_URL="$API_BASE_URL")
[ -n "${PUBLIC_KEY:-}" ] && DEFINES+=(--dart-define=PUBLIC_KEY="$PUBLIC_KEY")

flutter build web --release --web-renderer html "${DEFINES[@]}"
