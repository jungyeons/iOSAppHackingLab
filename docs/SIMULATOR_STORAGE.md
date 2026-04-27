# Simulator Storage Inspection

This note documents where this lab app writes local data in the iOS Simulator. It is intended only for `com.jungyeons.iosapphackinglab`.

## Find the App Container

Build, install, and launch the simulator target, then ask CoreSimulator for this app's data container:

```bash
APP_DATA="$(xcrun simctl get_app_container booted com.jungyeons.iosapphackinglab data)"
echo "$APP_DATA"
```

Typical shape:

```text
~/Library/Developer/CoreSimulator/Devices/<device-uuid>/data/Containers/Data/Application/<app-container-uuid>
```

The UUIDs change when the app is reinstalled, so prefer `xcrun simctl get_app_container` over copying a path from an older run.

## UserDefaults Plist

The vulnerable storage and progress labs use the app defaults domain:

```bash
PREFS="$APP_DATA/Library/Preferences/com.jungyeons.iosapphackinglab.plist"
plutil -p "$PREFS"
```

Keys currently written by the lab:

```text
lab.username
lab.password
lab.premium.enabled
lab.premium.serverClaim
lab.progress.completedChallengeIDs
lab.progress.notes
```

What to capture:

- `lab.username` and `lab.password` demonstrate plaintext preference storage.
- `lab.premium.enabled` demonstrates mutable local entitlement state.
- `lab.premium.serverClaim` demonstrates a safer cache shape where the account is hashed and the decision source is explicit.
- `lab.progress.*` demonstrates normal non-sensitive app state.

## App Sandbox Folders

Useful locations inside the same app data container:

```text
Documents/
Library/
Library/Preferences/
Library/Caches/
tmp/
```

This project currently focuses on `Library/Preferences`. If future labs write files, screenshots, or cached API responses, document the exact path and the reason the data is safe or unsafe to store there.

## Keychain Note

The Keychain comparison does not write the secret into the app container plist. In the simulator, Keychain storage belongs to the simulator device environment rather than the app's `Library/Preferences` file. For this portfolio lab, capture the app's Keychain success output and the absence of the Keychain password in `com.jungyeons.iosapphackinglab.plist` instead of publishing raw secrets.

## Resetting Local Lab State

Reset only this lab app's simulator state:

```bash
xcrun simctl uninstall booted com.jungyeons.iosapphackinglab
```

Then reinstall from Xcode or `xcrun simctl install booted <path-to-iOSAppHackingLab.app>`.

## Safety Boundary

Do not inspect third-party app containers, production app data, or real user data. Keep screenshots redacted if they include secrets produced by the intentionally vulnerable lab flows.
