#!/usr/bin/env bash
#
# Signs an unsigned `flutter build ipa --no-codesign` archive with Apple's cloud-managed distribution certificate
# and exports the App Store IPA. The App Store Connect API key (Admin role) lets Xcode create and renew the
# certificate and profiles itself, so there's no .p12 or provisioning profile to rotate.
#
# An unsigned archive carries no entitlements, and the export doesn't add them back, so the app is ad-hoc signed with
# its entitlements first (any `$(NAME)` in them filled from the environment, as Xcode would from build settings). The
# exported IPA is then checked to carry exactly those entitlements.

set -euo pipefail
shopt -s nullglob

ARCHIVE_PATH="${ARCHIVE_PATH:-build/ios/archive/Helium.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-build/ios/ipa}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-ios/ExportOptions.plist}"
ENTITLEMENTS="${ENTITLEMENTS:-ios/Runner/Runner.entitlements}"
APP_STORE_CONNECT_API_KEY_ID="${APP_STORE_CONNECT_API_KEY_ID:-}"
APP_STORE_CONNECT_API_ISSUER_ID="${APP_STORE_CONNECT_API_ISSUER_ID:-}"

if [[ -z "$APP_STORE_CONNECT_API_KEY_ID" ]]; then echo "APP_STORE_CONNECT_API_KEY_ID is not set"; exit 1; fi
if [[ -z "$APP_STORE_CONNECT_API_ISSUER_ID" ]]; then echo "APP_STORE_CONNECT_API_ISSUER_ID is not set"; exit 1; fi

KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${APP_STORE_CONNECT_API_KEY_ID}.p8"
if [[ ! -f "$KEY_PATH" ]]; then echo "Error: API key not found at $KEY_PATH"; exit 1; fi

APPS=("$ARCHIVE_PATH"/Products/Applications/*.app)
if [[ ${#APPS[@]} -ne 1 ]]; then echo "Error: expected one app in $ARCHIVE_PATH, found ${#APPS[@]}"; exit 1; fi
APP_PATH="${APPS[0]}"

if [[ -d "$APP_PATH/PlugIns" ]]; then
  echo "Error: $APP_PATH contains app extensions, which need their own entitlements; not supported yet"
  exit 1
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

python3 - "$ENTITLEMENTS" "$WORK_DIR/app.entitlements" <<'EOF'
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

for framework in "$APP_PATH"/Frameworks/*; do
  codesign --force --sign - --timestamp=none "$framework"
done
codesign --force --sign - --timestamp=none --entitlements "$WORK_DIR/app.entitlements" "$APP_PATH"

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
codesign -d --entitlements - --xml "${EXPORTED_APPS[0]}" > "$WORK_DIR/exported.entitlements" 2>/dev/null

python3 - "$WORK_DIR/app.entitlements" "$WORK_DIR/exported.entitlements" <<'EOF'
import plistlib
import sys

with open(sys.argv[1], "rb") as expected_file, open(sys.argv[2], "rb") as exported_file:
    expected = plistlib.load(expected_file)
    exported = plistlib.load(exported_file)

mismatched = sorted(key for key, value in expected.items() if exported.get(key) != value)
if mismatched:
    for key in mismatched:
        print(f"Error: entitlement {key} is {exported.get(key)!r} in the exported IPA, expected {expected[key]!r}")
    sys.exit(1)
print(f"Exported IPA carries all {len(expected)} entitlements")
EOF
