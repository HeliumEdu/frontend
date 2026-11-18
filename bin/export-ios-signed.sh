#!/usr/bin/env bash
#
# Signs an unsigned `flutter build ipa --no-codesign` archive with Apple's cloud-managed distribution certificate
# and exports the App Store IPA. The App Store Connect API key (Admin role) lets Xcode create and renew the
# certificate and profiles itself, so there's no .p12 or provisioning profile to rotate.
#
# An unsigned archive carries no entitlements, and the export doesn't add them back, so the app and each of its app
# extensions are ad-hoc signed with their entitlements first (any `$(NAME)` in them filled from the environment, as
# Xcode would from build settings), inside out: frameworks, then extensions, then the app. An extension `<Name>.appex`
# takes its entitlements from `ios/<Name>/<Name>.entitlements`. The exported IPA is then checked to carry exactly
# those entitlements on every bundle.

set -euo pipefail
shopt -s nullglob

ARCHIVE_PATH="${ARCHIVE_PATH:-build/ios/archive/Helium.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-build/ios/ipa}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-ios/ExportOptions.plist}"
ENTITLEMENTS="${ENTITLEMENTS:-ios/Runner/Runner.entitlements}"
EXTENSIONS_DIR="${EXTENSIONS_DIR:-ios}"
APP_STORE_CONNECT_API_KEY_ID="${APP_STORE_CONNECT_API_KEY_ID:-}"
APP_STORE_CONNECT_API_ISSUER_ID="${APP_STORE_CONNECT_API_ISSUER_ID:-}"

if [[ -z "$APP_STORE_CONNECT_API_KEY_ID" ]]; then echo "APP_STORE_CONNECT_API_KEY_ID is not set"; exit 1; fi
if [[ -z "$APP_STORE_CONNECT_API_ISSUER_ID" ]]; then echo "APP_STORE_CONNECT_API_ISSUER_ID is not set"; exit 1; fi

KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${APP_STORE_CONNECT_API_KEY_ID}.p8"
if [[ ! -f "$KEY_PATH" ]]; then echo "Error: API key not found at $KEY_PATH"; exit 1; fi

APPS=("$ARCHIVE_PATH"/Products/Applications/*.app)
if [[ ${#APPS[@]} -ne 1 ]]; then echo "Error: expected one app in $ARCHIVE_PATH, found ${#APPS[@]}"; exit 1; fi
APP_PATH="${APPS[0]}"

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

resolve_entitlements() {
  python3 - "$1" "$2" <<'EOF'
import os
import plistlib
import re
import sys

BUILD_VARIABLE = re.compile(r"\$\((\w+)\)")


def resolve(value):
    if isinstance(value, str):
        return BUILD_VARIABLE.sub(lambda match: environment_value(match.group(1)), value)
    if isinstance(value, list):
        return [resolve(item) for item in value]
    if isinstance(value, dict):
        return {key: resolve(item) for key, item in value.items()}
    return value


def environment_value(name):
    if not os.environ.get(name):
        print(f"Error: the entitlements use $({name}), but {name} is not set")
        sys.exit(1)
    return os.environ[name]


with open(sys.argv[1], "rb") as source_file:
    entitlements = resolve(plistlib.load(source_file))
with open(sys.argv[2], "wb") as resolved_file:
    plistlib.dump(entitlements, resolved_file, fmt=plistlib.FMT_XML)
EOF
}

sign_bundle() {
  local bundle="$1" entitlements="$2"
  for framework in "$bundle"/Frameworks/*; do
    codesign --force --sign - --timestamp=none "$framework"
  done
  codesign --force --sign - --timestamp=none --entitlements "$entitlements" "$bundle"
}

# "<bundle path inside the .app>:<resolved entitlements>"; the app itself has an empty path.
SIGNED_BUNDLES=()

for extension in "$APP_PATH"/PlugIns/*.appex; do
  name=$(basename "$extension" .appex)
  source_entitlements="$EXTENSIONS_DIR/$name/$name.entitlements"
  if [[ ! -f "$source_entitlements" ]]; then
    echo "Error: $source_entitlements not found for the $name extension"
    exit 1
  fi
  resolve_entitlements "$source_entitlements" "$WORK_DIR/$name.entitlements"
  sign_bundle "$extension" "$WORK_DIR/$name.entitlements"
  SIGNED_BUNDLES+=("/PlugIns/$name.appex:$WORK_DIR/$name.entitlements")
done

resolve_entitlements "$ENTITLEMENTS" "$WORK_DIR/app.entitlements"
sign_bundle "$APP_PATH" "$WORK_DIR/app.entitlements"
SIGNED_BUNDLES+=(":$WORK_DIR/app.entitlements")

rm -rf "$EXPORT_PATH"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$KEY_PATH" \
  -authenticationKeyID "$APP_STORE_CONNECT_API_KEY_ID" \
  -authenticationKeyIssuerID "$APP_STORE_CONNECT_API_ISSUER_ID"

IPAS=("$EXPORT_PATH"/*.ipa)
if [[ ${#IPAS[@]} -ne 1 ]]; then echo "Error: expected one IPA in $EXPORT_PATH, found ${#IPAS[@]}"; exit 1; fi

unzip -q "${IPAS[0]}" -d "$WORK_DIR/ipa"
EXPORTED_APPS=("$WORK_DIR"/ipa/Payload/*.app)

for signed_bundle in "${SIGNED_BUNDLES[@]}"; do
  bundle_path="${EXPORTED_APPS[0]}${signed_bundle%%:*}"
  if [[ ! -d "$bundle_path" ]]; then echo "Error: the exported IPA has no ${signed_bundle%%:*}"; exit 1; fi
  codesign -d --entitlements - --xml "$bundle_path" > "$WORK_DIR/exported.entitlements" 2>/dev/null

  python3 - "${signed_bundle#*:}" "$WORK_DIR/exported.entitlements" "$(basename "$bundle_path")" <<'EOF'
import plistlib
import sys

with open(sys.argv[1], "rb") as expected_file, open(sys.argv[2], "rb") as exported_file:
    expected = plistlib.load(expected_file)
    exported = plistlib.load(exported_file)
bundle = sys.argv[3]

mismatched = sorted(key for key, value in expected.items() if exported.get(key) != value)
if mismatched:
    for key in mismatched:
        print(f"Error: entitlement {key} is {exported.get(key)!r} in the exported {bundle}, expected {expected[key]!r}")
    sys.exit(1)
print(f"Exported {bundle} carries all {len(expected)} entitlements")
EOF
done
