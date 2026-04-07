# WaterBar

WaterBar is a native macOS menu bar app for daily water tracking. It stores a daily goal in milliliters, logs drinks in a default increment, resets automatically at local midnight, keeps a simple daily history, and can send periodic reminders until the goal is complete.

The app icon uses [water.png](/Users/joehage/Documents/WaterBar/Support/water.png), and the menu bar mark uses a simplified matching cup outline.

## Run

```sh
swift run --package-path /Users/joehage/Documents/WaterBar WaterBar
```

## Build A `.app`

```sh
/Users/joehage/Documents/WaterBar/Scripts/build-app.sh
```

The script outputs `/Users/joehage/Documents/WaterBar/.dist/WaterBar.app`.

## Build A `.dmg`

```sh
/Users/joehage/Documents/WaterBar/Scripts/build-dmg.sh
```

The script outputs `/Users/joehage/Documents/WaterBar/.dist/WaterBar.dmg`.

Users can open the DMG, drag `WaterBar.app` into `Applications`, and launch it from there.

## GitHub Releases

- Push a tag like `v0.1.0`.
- GitHub Actions builds `WaterBar.dmg`.
- The DMG is attached to the GitHub release automatically.

## Tests

```sh
swift test
```

On this machine, the Apple Command Line Tools installation can compile the app but does not provide the test modules needed by `swift test`. Running the tests requires a full Xcode toolchain or another Swift toolchain that includes macOS test support.

## Notes

- Settings default to `2000 ml` goal and `250 ml` per drink.
- History stores one total per day.
- Reminders are local-only and stop once the current day reaches the goal.
