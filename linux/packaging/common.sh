#!/bin/sh
set -eu

: "${SCRIPT_DIR:?SCRIPT_DIR must be set before sourcing common.sh}"

LINUX_DIR=$SCRIPT_DIR
ROOT_DIR=$(CDPATH= cd -- "$LINUX_DIR/.." && pwd)

APP_ID="com.rwkv.studio"
APP_NAME="RWKV Studio"
PACKAGE_NAME="rwkv-studio"
BINARY_NAME="rwkv-studio"
ICON_SOURCE="$LINUX_DIR/runner/resources/$APP_ID.png"

PUBSPEC_VERSION=$(
  sed -n 's/^version:[[:space:]]*//p' "$ROOT_DIR/pubspec.yaml" | head -n 1
)

if [ -z "$PUBSPEC_VERSION" ]; then
  echo "Failed to read version from pubspec.yaml" >&2
  exit 1
fi

APP_VERSION=${PUBSPEC_VERSION%%+*}
BUILD_NUMBER=${PUBSPEC_VERSION#*+}
if [ "$BUILD_NUMBER" = "$PUBSPEC_VERSION" ]; then
  BUILD_NUMBER=1
fi
DEB_VERSION="${APP_VERSION}-${BUILD_NUMBER}"

ARCH_UNAME=$(uname -m)
case "$ARCH_UNAME" in
  x86_64)
    APPIMAGE_ARCH="x86_64"
    DEFAULT_DEB_ARCH="amd64"
    ;;
  aarch64|arm64)
    APPIMAGE_ARCH="aarch64"
    DEFAULT_DEB_ARCH="arm64"
    ;;
  armv7l)
    APPIMAGE_ARCH="armhf"
    DEFAULT_DEB_ARCH="armhf"
    ;;
  *)
    APPIMAGE_ARCH="$ARCH_UNAME"
    DEFAULT_DEB_ARCH="$ARCH_UNAME"
    ;;
esac

if command -v dpkg >/dev/null 2>&1; then
  DEB_ARCH=$(dpkg --print-architecture)
else
  DEB_ARCH="$DEFAULT_DEB_ARCH"
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

recreate_dir() {
  rm -rf "$1"
  mkdir -p "$1"
}

copy_dir_contents() {
  src=$1
  dst=$2
  mkdir -p "$dst"
  cp -a "$src/." "$dst/"
}

copy_file() {
  src=$1
  dst=$2
  mkdir -p "$(dirname -- "$dst")"
  cp "$src" "$dst"
}

sync_bundle_icon() {
  bundle_root=$1
  copy_file "$ICON_SOURCE" "$bundle_root/$APP_ID.png"
}

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[\/&]/\\&/g'
}

render_template() {
  template=$1
  output=$2
  shift 2

  mkdir -p "$(dirname -- "$output")"
  cp "$template" "$output"

  while [ "$#" -gt 0 ]; do
    key=$1
    value=$2
    shift 2
    escaped=$(escape_sed_replacement "$value")
    sed -i "s|@$key@|$escaped|g" "$output"
  done
}

render_wrapper_script() {
  template=$1
  output=$2
  install_root=$3

  render_template \
    "$template" \
    "$output" \
    INSTALL_ROOT "$install_root" \
    BINARY_NAME "$BINARY_NAME"

  chmod 0755 "$output"
}

render_appdir_runner() {
  output=$1
  render_template \
    "$LINUX_DIR/packaging/AppRun.in" \
    "$output" \
    PACKAGE_NAME "$PACKAGE_NAME" \
    BINARY_NAME "$BINARY_NAME"
  chmod 0755 "$output"
}

render_desktop_file() {
  output=$1
  exec_cmd=$2
  icon_name=$3

  render_template \
    "$LINUX_DIR/packaging/$APP_ID.desktop.in" \
    "$output" \
    APP_NAME "$APP_NAME" \
    APP_ID "$APP_ID" \
    PACKAGE_NAME "$PACKAGE_NAME" \
    EXEC_COMMAND "$exec_cmd" \
    ICON_NAME "$icon_name"
}

build_release_bundle() {
  require_cmd flutter
  (
    cd "$ROOT_DIR"
    flutter build linux --release "$@"
  )
}

locate_bundle_dir() {
  bundle_dir=$(
    find "$ROOT_DIR/build/linux" -type d -path '*/release/bundle' | sort | head -n 1
  )

  if [ -z "$bundle_dir" ]; then
    echo "Linux release bundle not found under build/linux" >&2
    exit 1
  fi

  printf '%s\n' "$bundle_dir"
}
