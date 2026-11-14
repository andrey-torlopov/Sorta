#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
stage="${1:-help}"
if [[ $# -gt 0 ]]; then shift; fi
release_version=""
release_build=""
release_team=""
release_output=""
release_archs="arm64"

usage() {
    cat <<'USAGE'
Usage: scripts/release.sh preflight|test|archive|export|verify [options]

  --version VALUE       Marketing version for archive (digits separated by dots)
  --build VALUE         Positive integer build number for archive
  --team VALUE          Apple Developer team for archive/export
  --output DIRECTORY    New release directory for archive; existing one for export/verify
  --architectures VALUE arm64, x86_64, or "arm64 x86_64" (default: arm64)

preflight reads local configuration and tool versions; it does not access credentials.
test compiles and runs the shared scheme with ad-hoc local signing.
archive requires a clean checkout and never overwrites an existing output directory.
export prepares an App Store Connect package; it does not upload it.
verify inspects the archive, resources, entitlements, signature, and architectures.
Certificate/profile creation, upload, App Review, and publication are separate actions.
USAGE
}
fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }
while [[ $# -gt 0 ]]; do
    [[ $# -ge 2 ]] || fail "Missing value for $1"
    case "$1" in
        --version) release_version="$2" ;;
        --build) release_build="$2" ;;
        --team) release_team="$2" ;;
        --output) release_output="$2" ;;
        --architectures) release_archs="$2" ;;
        *) fail "Unknown option: $1" ;;
    esac
    shift 2
done
case "$release_archs" in 'arm64'|'x86_64'|'arm64 x86_64') ;; *) fail 'Unsupported architecture selection' ;; esac
cd "$project_root"

case "$stage" in
    help|--help|-h) usage ;;
    preflight)
        xcodebuild -version
        xcrun swift --version
        plutil -lint MacosApp.xcodeproj/project.pbxproj MacosApp/Info.plist MacosApp/MacosApp.entitlements MacosApp/Resources/PrivacyInfo.xcprivacy
        [[ -f MacosApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved ]] || fail 'Missing tracked Package.resolved'
        git ls-files --error-unmatch MacosApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved >/dev/null || fail 'Package.resolved is not tracked yet'
        git diff --check
        printf 'Source commit: '
        git rev-parse HEAD
        git status --short
        ;;
    test)
        xcodebuild -project MacosApp.xcodeproj -scheme MacosApp -configuration Debug \
            -onlyUsePackageVersionsFromResolvedFile -disableAutomaticPackageResolution \
            -destination 'platform=macOS' -parallel-testing-enabled NO \
            -derivedDataPath build/verification \
            CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= test
        ;;
    archive)
        [[ "$release_version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] || fail 'An explicit numeric --version is required'
        [[ "$release_build" =~ ^[1-9][0-9]*$ ]] || fail 'An explicit positive --build is required'
        [[ "$release_team" =~ ^[A-Z0-9]{10}$ ]] || fail 'An explicit --team is required'
        [[ -n "$release_output" ]] || fail '--output is required'
        release_output="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "$release_output")"
        case "$release_output/" in
            "$project_root/MacosApp/"*|"$project_root/MacosAppTests/"*|"$project_root/MacosAppUITests/"*|"$project_root/MacosApp.xcodeproj/"*|"$project_root/scripts/"*|"$project_root/.git/"*)
                fail 'Archive output must stay outside source/configuration directories' ;;
        esac
        [[ -z "$(git status --porcelain)" ]] || fail 'Commit or preserve working changes before making a release archive'
        [[ ! -e "$release_output" ]] || fail 'Output already exists; use a new release directory'
        mkdir -p "$release_output"
        release_output="$(cd "$release_output" && pwd)"
        cp MacosApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved "$release_output/Package.resolved"
        xcodebuild -project MacosApp.xcodeproj -scheme MacosApp -configuration Release \
            -onlyUsePackageVersionsFromResolvedFile -disableAutomaticPackageResolution \
            -destination 'generic/platform=macOS' -archivePath "$release_output/Sorta.xcarchive" \
            -derivedDataPath "$release_output/DerivedData" \
            ARCHS="$release_archs" ONLY_ACTIVE_ARCH=NO \
            MARKETING_VERSION="$release_version" CURRENT_PROJECT_VERSION="$release_build" \
            DEVELOPMENT_TEAM="$release_team" CODE_SIGN_STYLE=Automatic archive \
            2>&1 | tee "$release_output/archive.log"
        git rev-parse HEAD > "$release_output/source-commit.txt"
        cmp MacosApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved "$release_output/Package.resolved" || fail 'Resolved dependencies changed during archive'
        printf '%s\n' "$release_archs" > "$release_output/architectures.txt"
        printf '%s\n' "$release_version" > "$release_output/version.txt"
        printf '%s\n' "$release_build" > "$release_output/build.txt"
        printf '%s\n' "$release_team" > "$release_output/team.txt"
        xcodebuild -version > "$release_output/toolchain.txt"
        ;;
    export)
        [[ -n "$release_output" && -d "$release_output/Sorta.xcarchive" ]] || fail 'An existing archive --output is required'
        [[ "$release_team" =~ ^[A-Z0-9]{10}$ ]] || fail 'An explicit --team is required'
        [[ ! -e "$release_output/Export" ]] || fail 'Export already exists; preserve it and use a new archive directory'
        export_options="$release_output/ExportOptions.plist"
        /usr/bin/plutil -create xml1 "$export_options"
        /usr/bin/plutil -insert method -string app-store-connect "$export_options"
        /usr/bin/plutil -insert destination -string export "$export_options"
        /usr/bin/plutil -insert teamID -string "$release_team" "$export_options"
        /usr/bin/plutil -insert signingStyle -string automatic "$export_options"
        /usr/bin/plutil -insert manageAppVersionAndBuildNumber -bool NO "$export_options"
        xcodebuild -exportArchive -archivePath "$release_output/Sorta.xcarchive" \
            -exportPath "$release_output/Export" -exportOptionsPlist "$export_options" \
            2>&1 | tee "$release_output/export.log"
        ;;
    verify)
        [[ -n "$release_output" ]] || fail '--output is required'
        archive_app="$release_output/Sorta.xcarchive/Products/Applications/Sorta.app"
        [[ -d "$archive_app" ]] || fail 'Archive does not contain Sorta.app'
        [[ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$archive_app/Contents/Info.plist")" == dev.torlopov.sorta.macos ]] || fail 'Wrong Bundle ID'
        [[ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$archive_app/Contents/Info.plist")" == "$(cat "$release_output/version.txt")" ]] || fail 'Marketing version mismatch'
        [[ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$archive_app/Contents/Info.plist")" == "$(cat "$release_output/build.txt")" ]] || fail 'Build number mismatch'
        [[ "$(/usr/libexec/PlistBuddy -c 'Print LSMinimumSystemVersion' "$archive_app/Contents/Info.plist")" == 15.1 ]] || fail 'Unexpected minimum macOS'
        [[ -f "$archive_app/Contents/Resources/PrivacyInfo.xcprivacy" ]] || fail 'Missing privacy manifest in app bundle'
        [[ -f "$archive_app/Contents/Resources/Acknowledgements.txt" ]] || fail 'Missing dependency acknowledgements'
        for language in en ru; do
            [[ -f "$archive_app/Contents/Resources/$language.lproj/InfoPlist.strings" ]] || fail "Missing $language usage descriptions"
            [[ -f "$archive_app/Contents/Resources/$language.lproj/Localizable.strings" ]] || fail "Missing $language localization"
        done
        codesign --verify --deep --strict --verbose=2 "$archive_app"
        codesign -dv "$archive_app" 2> "$release_output/codesign.txt"
        /usr/bin/grep -Fxq "TeamIdentifier=$(cat "$release_output/team.txt")" "$release_output/codesign.txt" || fail 'Unexpected signing team'
        entitlement_file="$(mktemp -t sorta-entitlements)"
        trap 'rm -f "$entitlement_file"' EXIT
        codesign -d --entitlements :- "$archive_app" > "$entitlement_file"
        [[ "$(/usr/libexec/PlistBuddy -c 'Print com.apple.security.app-sandbox' "$entitlement_file")" == true ]] || fail 'Sandbox is disabled'
        [[ "$(/usr/libexec/PlistBuddy -c 'Print com.apple.security.files.user-selected.read-write' "$entitlement_file")" == true ]] || fail 'Missing selected-folder entitlement'
        [[ -f "$release_output/architectures.txt" ]] || fail 'Missing expected architecture manifest'
        read -r expected_archs < "$release_output/architectures.txt"
        python3 scripts/verify-bundle.py "$archive_app" "$expected_archs"
        printf 'Archive structure, signature, sandbox and expected architectures verified.\n'
        ;;
    *) usage >&2; fail "Unknown stage: $stage" ;;
esac
