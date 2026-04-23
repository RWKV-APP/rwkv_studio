#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sh "$SCRIPT_DIR/check-env.sh" deb
. "$SCRIPT_DIR/packaging/common.sh"

require_cmd dpkg-deb

build_release_bundle "$@"
bundle_dir=$(locate_bundle_dir)

out_dir="$LINUX_DIR/out/deb"
stage_dir="$out_dir/staging"
pkg_dir="$stage_dir/${PACKAGE_NAME}_${DEB_VERSION}_${DEB_ARCH}"
app_dir="$pkg_dir/opt/$PACKAGE_NAME"
bin_dir="$pkg_dir/usr/bin"
desktop_dir="$pkg_dir/usr/share/applications"
icon_dir="$pkg_dir/usr/share/icons/hicolor/512x512/apps"
pixmaps_dir="$pkg_dir/usr/share/pixmaps"
metainfo_dir="$pkg_dir/usr/share/metainfo"
doc_dir="$pkg_dir/usr/share/doc/$PACKAGE_NAME"
control_dir="$pkg_dir/DEBIAN"
deb_path="$out_dir/${PACKAGE_NAME}_${DEB_VERSION}_${DEB_ARCH}.deb"

recreate_dir "$pkg_dir"
mkdir -p \
  "$app_dir" \
  "$bin_dir" \
  "$desktop_dir" \
  "$icon_dir" \
  "$pixmaps_dir" \
  "$metainfo_dir" \
  "$doc_dir" \
  "$control_dir"

copy_dir_contents "$bundle_dir" "$app_dir"
sync_bundle_icon "$app_dir"
render_wrapper_script "$LINUX_DIR/packaging/rwkv-studio.in" \
  "$bin_dir/$PACKAGE_NAME" \
  "/opt/$PACKAGE_NAME"
render_desktop_file \
  "$desktop_dir/$APP_ID.desktop" \
  "$PACKAGE_NAME" \
  "/usr/share/pixmaps/$APP_ID.png"
copy_file "$ICON_SOURCE" "$icon_dir/$APP_ID.png"
copy_file "$ICON_SOURCE" "$pixmaps_dir/$APP_ID.png"
copy_file "$LINUX_DIR/packaging/$APP_ID.metainfo.xml" \
  "$metainfo_dir/$APP_ID.metainfo.xml"
copy_file "$LINUX_DIR/packaging/copyright" \
  "$doc_dir/copyright"
copy_file "$LINUX_DIR/packaging/postinst" \
  "$control_dir/postinst"
copy_file "$LINUX_DIR/packaging/postrm" \
  "$control_dir/postrm"

installed_size_kb=$(
  du -sk "$pkg_dir" | awk '{print $1}'
)

cat > "$control_dir/control" <<EOF
Package: $PACKAGE_NAME
Version: $DEB_VERSION
Section: utils
Priority: optional
Architecture: $DEB_ARCH
Maintainer: dengzixx@gmail.com
Depends: libgtk-3-0, libstdc++6, libmpv2 | libmpv1
Installed-Size: $installed_size_kb
Homepage: https://github.com/RWKV-APP/rwkv_studio
Description: RWKV Studio
 Offline-first AI studio for RWKV and OpenAI-compatible models.
 Includes chat, model lifecycle management, MCP tooling, workflow editing,
 and local service integration in a single desktop application.
EOF

chmod 0755 "$bin_dir/$PACKAGE_NAME"
chmod 0755 "$control_dir/postinst" "$control_dir/postrm"
find "$app_dir" -type d -exec chmod 0755 {} \;
find "$app_dir" -type f -exec chmod 0644 {} \;
chmod 0755 "$app_dir/$BINARY_NAME"
find "$app_dir/lib" -type f \( -name '*.so' -o -name '*.so.*' \) -exec chmod 0755 {} \; 2>/dev/null || true
find "$app_dir/data/flutter_assets" -type f -exec chmod 0644 {} \; 2>/dev/null || true

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$desktop_dir/$APP_ID.desktop"
fi

mkdir -p "$out_dir"
rm -f "$deb_path"
dpkg-deb --build --root-owner-group "$pkg_dir" "$deb_path"

printf 'DEB package ready: %s\n' "$deb_path"
