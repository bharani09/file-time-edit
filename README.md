# File Time Edit

A native macOS utility for applying one creation date and modification date to
files, batches of files, folders, and folder contents.

## Features

- Select files and folders together with the standard macOS picker.
- Drag files or folders into the window.
- Set year, month, day, hours, minutes, and seconds independently.
- Recursively update folder contents, including hidden items.
- Update creation and modification timestamps in one operation.
- Report successful updates and individual permission or filesystem failures.
- Avoid external runtime dependencies and the `SetFile` command.

## Requirements

- macOS 14 Sonoma or later
- Xcode 15.4 or later for development and tests
- A free Apple ID for local development signing, or an Apple Developer Program
  membership for Developer ID distribution and notarization

The standalone Command Line Tools can compile most of the project, but full
Xcode is recommended because it provides the macOS UI and test frameworks.

## Build and run

### Xcode

1. Install Xcode from the Mac App Store and launch it once.
2. Select the full Xcode toolchain:

   ```sh
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

3. Open `Package.swift` in Xcode.
4. Select the `FileTimeEdit` scheme and **My Mac** destination.
5. Press **Run** (`Command-R`).

### Command line

```sh
swift build
swift run FileTimeEdit
```

Run the automated tests with:

```sh
swift test
```

## Use

1. Add one or more files or folders, or drag them into the window.
2. Enter the required year, month, day, hours, minutes, and seconds. The fields
   initially contain the current local date and time.
3. Keep **Include folder contents** enabled to process folders recursively.
4. Click **Apply Timestamp** or press `Command-Return`.

The operation writes both `creationDate` and `modificationDate` through
Foundation. APFS and HFS+ support both attributes. Other mounted filesystems may
reject creation-date changes or round timestamps; failures appear in the app.
Changing folder contents can itself alter a folder's modified time, so the app
processes directories after their descendants.

## Create a distributable app

The packaging script builds a release executable, generates an app icon,
creates a standard `.app` bundle, signs it, and creates a ZIP:

```sh
bash Scripts/package-app.sh
open "dist/File Time Edit.app"
```

By default the app is ad-hoc signed, which is suitable for local testing. Set
release metadata with environment variables:

```sh
VERSION=1.0.0 \
BUILD_NUMBER=1 \
BUNDLE_IDENTIFIER=com.example.filetimeedit \
IDENTITY="Developer ID Application: Your Name (TEAMID)" \
bash Scripts/package-app.sh
```

Replace the bundle identifier in examples with an identifier you control.

## Sign and notarize a public release

Distribution outside the Mac App Store should use a Developer ID Application
certificate and Apple notarization. After packaging with `IDENTITY` set:

1. Store notarization credentials once:

   ```sh
   xcrun notarytool store-credentials "file-time-edit-notary" \
     --apple-id "you@example.com" \
     --team-id "TEAMID" \
     --password "APP_SPECIFIC_PASSWORD"
   ```

2. Submit and wait for notarization:

   ```sh
   xcrun notarytool submit "dist/FileTimeEdit-1.0.0.zip" \
     --keychain-profile "file-time-edit-notary" --wait
   ```

3. Staple the ticket and recreate the ZIP:

   ```sh
   xcrun stapler staple "dist/File Time Edit.app"
   rm "dist/FileTimeEdit-1.0.0.zip"
   ditto -c -k --sequesterRsrc --keepParent \
     "dist/File Time Edit.app" "dist/FileTimeEdit-1.0.0.zip"
   spctl --assess --type execute --verbose "dist/File Time Edit.app"
   ```

Never commit certificates, passwords, API keys, or notarization profiles.

## Publish on GitHub

1. Create an empty GitHub repository, for example `file-time-edit`.
2. Initialize and push this source tree:

   ```sh
   git init
   git add .
   git commit -m "Initial open-source release"
   git branch -M main
   git remote add origin git@github.com:YOUR_ACCOUNT/file-time-edit.git
   git push -u origin main
   ```

3. Update `BUNDLE_IDENTIFIER`, copyright ownership, and repository links for
   your project.
4. Enable GitHub Actions. The included workflow builds, tests, packages, and
   uploads an unsigned artifact for each push and pull request.
5. For a release, build and notarize locally, create a Git tag, and attach the
   notarized ZIP to a GitHub Release:

   ```sh
   git tag v1.0.0
   git push origin v1.0.0
   gh release create v1.0.0 "dist/FileTimeEdit-1.0.0.zip" \
     --title "File Time Edit 1.0.0" --generate-notes
   ```

## Project structure

```text
Sources/FileTimeCore/       Filesystem timestamp engine
Sources/FileTimeEdit/       SwiftUI macOS application
Tests/FileTimeCoreTests/    Temporary-filesystem tests
Resources/                  Bundle metadata
Scripts/                    Icon and app packaging tools
.github/workflows/          Continuous integration
```

## Privacy and security

File Time Edit works locally and has no networking or analytics. It changes
metadata in place, so use backups for important data. macOS permissions and
read-only filesystems can prevent updates; the app does not attempt to bypass
those controls.

## License

Released under the [MIT License](LICENSE).