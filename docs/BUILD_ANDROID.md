# Building for Android

## Quick build (debug APK for testing)

```bash
tools/build_android.sh            # -> game/build/skyline-stack-debug.apk
tools/build_android.sh install    # also installs on a USB-connected phone (USB debugging on)
```

The APK is debug-signed with the standard public Android debug key. Use it only for testing; never upload it to a store.

## Installing on a phone (for HR-0017)
Pick one:
- **USB:** enable Developer options → USB debugging on the phone, connect it, run `tools/build_android.sh install`.
- **File transfer:** copy `game/build/skyline-stack-debug.apk` to the phone (AirDrop is not supported on Android;
  use Google Drive, a USB cable, or email), open it, and allow "install unknown apps" when asked.

## One-time setup on a new Mac (already done on the planner's machine, 2026-10-13)

```bash
brew install --cask godot                       # Godot 4.7.x
brew install openjdk@17                         # Java for Android tools
brew install --cask android-commandlinetools    # sdkmanager
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
SDK=/opt/homebrew/share/android-commandlinetools
yes | sdkmanager --sdk_root=$SDK --licenses     # accepts Google's Android SDK licence
sdkmanager --sdk_root=$SDK "platform-tools" "build-tools;35.0.1" "platforms;android-35"
keytool -genkeypair -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey \
  -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
```

Export templates: download `Godot_v<version>-stable_export_templates.tpz` from the Godot GitHub release, check it
against `SHA512-SUMS.txt`, and copy at least `version.txt`, `android_debug.apk`, `android_release.apk` and
`android_source.zip` into `~/Library/Application Support/Godot/export_templates/<version>.stable/`.
Only the Android templates are installed on the planner's machine; add others (iOS, web) when needed.

`tools/build_android.sh` writes the SDK, JDK and debug-keystore paths into the local Godot editor settings each run,
so nothing machine-specific is stored in the repo.

## What's in the build
- Preset "Android Debug" in `game/export_presets.cfg`: arm64-v8a and armeabi-v7a, immersive portrait, no internet
  permission yet (ads in M5 will need it), vibrate permission for haptics.
- `*.json` configs are included explicitly (`include_filter`), tests and tools are excluded.
- Package id is a placeholder (`com.placeholder.skylinestack`) until HR-0013 decides the real one.
  **The package id can never change after the first store upload.**

## Known warnings
- "Could not find version of build tools that matches Target SDK, using 35.0.1": harmless for debug builds.
  Install the matching build-tools when setting up release builds (T-0601).

## Release builds
T-0601: signed AAB with the upload keystore from HR-0014 (passwords via environment variables, never in the repo).
