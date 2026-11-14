# Development and architecture

*[Русский](../ru/development.md)*

Sorta is a native SwiftUI/AppKit application for **macOS 15.1 or later**. The initial distribution target is **Apple Silicon (arm64)**. Use Xcode with Swift 6 and an SDK that supports the configured deployment target. Intel support is not established by the presence of an architecture option in a script.

## Open and build the project

```sh
git clone https://github.com/andrey-torlopov/Sorta.git
cd Sorta
open MacosApp.xcodeproj
```

Select the shared **MacosApp** scheme and **My Mac**. The product is named **Sorta**. The repository root is the directory containing `MacosApp.xcodeproj`; commands below run there.

The GUI uses the remote Swift package [PhotoSorterCore](https://github.com/andrey-torlopov/PhotoSorterCore), pinned to **exactly 0.0.2**, revision `6b97352c15a956d633493bee955037d73757a304`. Keep the project requirement and tracked `MacosApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` consistent. Dependency resolution needs access to GitHub for a fresh checkout. The separately installed CLI is not a GUI dependency.

A local arm64 Debug build with ad-hoc signing:

```sh
xcodebuild \
  -project MacosApp.xcodeproj \
  -scheme MacosApp \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/LocalDebug \
  -clonedSourcePackagesDirPath build/SourcePackages \
  -onlyUsePackageVersionsFromResolvedFile \
  -disableAutomaticPackageResolution \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  build
```

Launch through Xcode or open the `.app` through Finder/LaunchServices. Local ad-hoc signing is for development; it does not produce an App Store distribution build. Certificates, provisioning profiles, credentials, and release archives are not included in the source repository.

## Code map

| Location | Responsibility |
|---|---|
| `MacosApp/MacosAppApp.swift` | Application composition, window lifetime, shared preferences, command wiring |
| `MacosApp/Modules/SortPhotos/`, `ConvertDngToHeic/`, `FixDates/` | Operation-specific views and state; calls into Core |
| `MacosApp/Modules/Onboarding/` | First-run acknowledgement and monotonic 30-second countdown |
| `MacosApp/Modules/Settings/`, `About/`, `MacosApp/Help/` | Auxiliary windows and their content |
| `MacosApp/Core/` | Folder selection/access, operation-session lifetime, localization and presentation preferences |
| `MacosApp/Design/` | Shared controls, typed log presentation, common developer information |
| `MacosApp/Resources/` | RU/EN string catalog, localized Help, icons/avatar, privacy manifest and acknowledgements |
| `MacosAppTests/`, `MacosAppUITests/` | Unit and UI test targets |
| `scripts/` | Staged release commands and Mach-O/bundle verification |

Feature folders are organizational boundaries in the app target, not separate SwiftPM packages. **PhotoSorterCore** owns shared file-processing algorithms. The GUI owns access selection, user interaction, localized presentation and operation lifetime. Its `Core/` folder is application support code and is distinct from the external package.

## State and concurrency

One observable `AppPreferences` instance supplies language and appearance to the hosting roots. UserDefaults stores these preferences and the onboarding acknowledgement. Changing language or theme updates existing windows without replacing their roots, resetting folder selections or restarting an operation. AppKit-owned menu commands and dialog controls may keep the macOS language.

`PhotoOperationSession` owns each operation's status and cancellation. Events are associated with the active operation; completion waits for worker and event-drain boundaries. Blocking folder checks and synchronous date work run on dedicated actors rather than the UI actor. A cancellation request does not undo filesystem changes already completed.

Log entries retain typed localization keys, arguments and timestamps until rendering. Translate a Core event into the GUI's typed message instead of storing a rendered English sentence. Keep file paths, user input and technical values intact. New strings need Russian and English entries, including error branches and auxiliary windows.

## Files and privacy

The sandbox grants user-selected read/write access. Keep security-scoped access balanced, validate destination access, and treat dropped URLs as requiring confirmation when the system has not granted access. The application does not persist a photo catalog or its current folder selections.

Do not infer behavior from a UI label alone: sorting without folder structure uses original directories, DNG conversion writes results to the selected root, and date correction updates filesystem/content-creation dates rather than EXIF `DateTimeOriginal`. Document any change to these contracts in [features](features.md) and [data handling](data-and-privacy.md).

The privacy manifest declares local preference and file-timestamp API use. Update both the manifest and [privacy policy](../../PRIVACY.md) when the application's data practices change.

## Verification

Run the unit target locally without the UI suite:

```sh
xcodebuild \
  -project MacosApp.xcodeproj \
  -scheme MacosApp \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath build/UnitTests \
  -clonedSourcePackagesDirPath build/SourcePackages \
  -onlyUsePackageVersionsFromResolvedFile \
  -disableAutomaticPackageResolution \
  -parallel-testing-enabled NO \
  -only-testing:MacosAppTests \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= \
  test
```

Tests cover onboarding, preferences, localization, links, folder access/selection, and operation cancellation/lifetime. Core has its own test suite in its repository. Use synthetic or anonymized copies for file tests; do not commit personal photographs or logs with private paths.

Manual checks should cover first launch, reopening information, folder access, both languages and themes, an active operation during a presentation change, cancellation, and Settings after closing the main window. A local test does not establish minimum-OS, Intel, external-drive, file-provider, clean-install or upgrade compatibility. See [recorded verification](releases.md) and the [release runbook](../release.md) for separate distribution stages.

No repository-wide open-source license has been assigned to the GUI. Public source availability is not a license grant. PhotoSorterCore declares MIT licensing; its notice is included in [Acknowledgements.txt](../../MacosApp/Resources/Acknowledgements.txt).

---

[Documentation](index.md) · [README](../../README.md) · [Release status](releases.md)
