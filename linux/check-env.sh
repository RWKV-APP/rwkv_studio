#!/bin/sh
set -eu

target=${1:-}

usage() {
  echo "Usage: $0 appimage|deb" >&2
  exit 2
}

case "$target" in
  appimage|deb)
    ;;
  *)
    usage
    ;;
esac

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

is_missing() {
  ! has_cmd "$1"
}

append_missing() {
  cmd=$1
  if is_missing "$cmd"; then
    missing="${missing:+$missing }$cmd"
  fi
}

package_for_apt() {
  case "$1" in
    awk) echo "gawk" ;;
    cat|chmod|cp|dirname|du|head|ln|mkdir|rm|sort|uname) echo "coreutils" ;;
    curl) echo "curl" ;;
    desktop-file-validate) echo "desktop-file-utils" ;;
    dpkg-deb) echo "dpkg-dev" ;;
    find) echo "findutils" ;;
    ninja) echo "ninja-build" ;;
    *) echo "$1" ;;
  esac
}

package_for_dnf() {
  case "$1" in
    awk) echo "gawk" ;;
    cat|chmod|cp|dirname|du|head|ln|mkdir|rm|sort|uname) echo "coreutils" ;;
    curl) echo "curl" ;;
    desktop-file-validate) echo "desktop-file-utils" ;;
    dpkg-deb) echo "dpkg" ;;
    find) echo "findutils" ;;
    ninja) echo "ninja-build" ;;
    pkg-config) echo "pkgconf-pkg-config" ;;
    *) echo "$1" ;;
  esac
}

package_for_pacman() {
  case "$1" in
    awk) echo "gawk" ;;
    cat|chmod|cp|dirname|du|head|ln|mkdir|rm|sort|uname) echo "coreutils" ;;
    curl) echo "curl" ;;
    desktop-file-validate) echo "desktop-file-utils" ;;
    dpkg-deb) echo "dpkg" ;;
    find) echo "findutils" ;;
    pkg-config) echo "pkgconf" ;;
    *) echo "$1" ;;
  esac
}

package_for_zypper() {
  case "$1" in
    awk) echo "gawk" ;;
    cat|chmod|cp|dirname|du|head|ln|mkdir|rm|sort|uname) echo "coreutils" ;;
    curl) echo "curl" ;;
    desktop-file-validate) echo "desktop-file-utils" ;;
    dpkg-deb) echo "dpkg" ;;
    find) echo "findutils" ;;
    ninja) echo "ninja" ;;
    *) echo "$1" ;;
  esac
}

unique_packages() {
  seen=" "
  for cmd in "$@"; do
    pkg=$($package_mapper "$cmd")
    case " $seen " in
      *" $pkg "*)
        ;;
      *)
        seen="$seen $pkg"
        printf '%s\n' "$pkg"
        ;;
    esac
  done
}

run_privileged() {
  if has_cmd id && [ "$(id -u)" = "0" ]; then
    "$@"
  elif has_cmd sudo; then
    sudo "$@"
  else
    echo "sudo is required to install missing tools when not running as root." >&2
    return 1
  fi
}

install_with_package_manager() {
  if [ "$#" -eq 0 ]; then
    return 0
  fi

  if has_cmd apt-get; then
    package_mapper=package_for_apt
    packages=$(unique_packages "$@")
    # shellcheck disable=SC2086
    run_privileged apt-get update && run_privileged apt-get install -y $packages
  elif has_cmd dnf; then
    package_mapper=package_for_dnf
    packages=$(unique_packages "$@")
    # shellcheck disable=SC2086
    run_privileged dnf install -y $packages
  elif has_cmd yum; then
    package_mapper=package_for_dnf
    packages=$(unique_packages "$@")
    # shellcheck disable=SC2086
    run_privileged yum install -y $packages
  elif has_cmd pacman; then
    package_mapper=package_for_pacman
    packages=$(unique_packages "$@")
    # shellcheck disable=SC2086
    run_privileged pacman -Sy --needed --noconfirm $packages
  elif has_cmd zypper; then
    package_mapper=package_for_zypper
    packages=$(unique_packages "$@")
    # shellcheck disable=SC2086
    run_privileged zypper install -y $packages
  else
    echo "No supported package manager found. Please install manually: $*" >&2
    return 1
  fi
}

install_appimagetool() {
  case "$(uname -m)" in
    x86_64)
      appimagetool_arch=x86_64
      ;;
    aarch64|arm64)
      appimagetool_arch=aarch64
      ;;
    armv7l)
      appimagetool_arch=armhf
      ;;
    i386|i686)
      appimagetool_arch=i686
      ;;
    *)
      echo "Unsupported appimagetool architecture: $(uname -m)" >&2
      return 1
      ;;
  esac

  url="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$appimagetool_arch.AppImage"
  tmp="${TMPDIR:-/tmp}/appimagetool-$$"

  if has_cmd curl; then
    curl -L "$url" -o "$tmp"
  elif has_cmd wget; then
    wget -O "$tmp" "$url"
  else
    echo "curl or wget is required to download appimagetool." >&2
    return 1
  fi

  chmod 0755 "$tmp"
  run_privileged mv "$tmp" /usr/local/bin/appimagetool
}

install_flutter() {
  if has_cmd snap; then
    run_privileged snap install flutter --classic
  else
    echo "Flutter is missing and no automatic installer is available." >&2
    echo "Install Flutter manually, then run this packaging script again." >&2
    return 1
  fi
}

install_missing_tools() {
  package_tools=""
  special_tools=""

  for cmd in "$@"; do
    case "$cmd" in
      appimagetool|flutter)
        special_tools="${special_tools:+$special_tools }$cmd"
        ;;
      *)
        package_tools="${package_tools:+$package_tools }$cmd"
        ;;
    esac
  done

  for cmd in $special_tools; do
    if [ "$cmd" = "appimagetool" ] && ! has_cmd curl && ! has_cmd wget; then
      package_tools="${package_tools:+$package_tools }curl"
      break
    fi
  done

  # shellcheck disable=SC2086
  install_with_package_manager $package_tools

  for cmd in $special_tools; do
    case "$cmd" in
      appimagetool)
        install_appimagetool
        ;;
      flutter)
        install_flutter
        ;;
    esac
  done
}

prompt_install() {
  printf 'Install missing tools now? [y/N] '
  if ! IFS= read -r answer; then
    answer=
  fi
  case "$answer" in
    y|Y|yes|YES)
      install_missing_tools "$@"
      ;;
    *)
      echo "Cannot continue until missing tools are installed: $*" >&2
      exit 1
      ;;
  esac
}

missing=""

for cmd in cat chmod cp dirname du find head ln mkdir rm sed sort uname; do
  append_missing "$cmd"
done

append_missing flutter

for cmd in clang cmake ninja pkg-config; do
  append_missing "$cmd"
done

case "$target" in
  appimage)
    append_missing appimagetool
    ;;
  deb)
    append_missing awk
    append_missing dpkg-deb
    ;;
esac

if [ -n "$missing" ]; then
  printf 'Missing required tools for %s packaging: %s\n' "$target" "$missing" >&2
  prompt_install $missing
fi

still_missing=""
for cmd in $missing; do
  if is_missing "$cmd"; then
    still_missing="${still_missing:+$still_missing }$cmd"
  fi
done

if [ -n "$still_missing" ]; then
  echo "These tools are still missing after installation: $still_missing" >&2
  exit 1
fi
