#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
sh "$SCRIPT_DIR/check-env.sh" appimage
. "$SCRIPT_DIR/packaging/common.sh"

require_cmd appimagetool

build_release_bundle "$@"
bundle_dir=$(locate_bundle_dir)

out_dir="$LINUX_DIR/out/appimage"
appdir="$out_dir/$PACKAGE_NAME.AppDir"
usr_dir="$appdir/usr"
app_root="$usr_dir/lib/$PACKAGE_NAME"
bin_dir="$usr_dir/bin"
share_app_dir="$usr_dir/share/applications"
share_icon_dir="$usr_dir/share/icons/hicolor/512x512/apps"
share_metainfo_dir="$usr_dir/share/metainfo"
appimage_path="$out_dir/${PACKAGE_NAME}-${APP_VERSION}-${APPIMAGE_ARCH}.AppImage"

recreate_dir "$appdir"
mkdir -p "$app_root" "$bin_dir" "$share_app_dir" "$share_icon_dir" "$share_metainfo_dir"

copy_dir_contents "$bundle_dir" "$app_root"
sync_bundle_icon "$app_root"
render_appdir_runner "$appdir/AppRun"
ln -s ../../AppRun "$bin_dir/$PACKAGE_NAME"
render_desktop_file "$appdir/$APP_ID.desktop" "AppRun" "$APP_ID"
copy_file "$appdir/$APP_ID.desktop" "$share_app_dir/$APP_ID.desktop"
copy_file "$ICON_SOURCE" "$appdir/$APP_ID.png"
ln -s "$APP_ID.png" "$appdir/.DirIcon"
copy_file "$ICON_SOURCE" "$share_icon_dir/$APP_ID.png"
copy_file "$LINUX_DIR/packaging/$APP_ID.metainfo.xml" \
  "$share_metainfo_dir/$APP_ID.metainfo.xml"

chmod 0755 "$appdir/AppRun" "$bin_dir/$PACKAGE_NAME"
chmod 0755 "$app_root/$BINARY_NAME"

if command -v desktop-file-validate >/dev/null 2>&1; then
  desktop-file-validate "$appdir/$APP_ID.desktop"
fi

mkdir -p "$out_dir"
rm -f "$appimage_path"
ARCH="$APPIMAGE_ARCH" appimagetool "$appdir" "$appimage_path"

printf 'AppImage ready: %s\n' "$appimage_path"
