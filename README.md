# Jump King — Flutter Mobile Game

A faithful recreation of the **Jump King** experience for mobile (Android/iOS), built entirely in Flutter/Dart with procedural rendering via `CustomPainter`. No external game engines or image assets required.

---

## 🎮 Gameplay

- **Hold the right side** of the screen to charge your jump — the longer you hold, the more power
- **Drag left/right** on the left side of the screen to aim your jump and move on the ground
- **Release** to launch! Angle is set by your horizontal movement while charging
- Fall onto spikes → respawn at last **checkpoint**
- Reach the **crown tile** at the top of each level to advance
- Climb all **5 levels** to become the Jump King!

---

## 📁 Project Structure

```
jump_king/
├── pubspec.yaml
├── README.md
└── lib/
    ├── main.dart                  # App entry, game loop (Ticker)
    ├── game/
    │   ├── game_engine.dart       # Game loop, state, particles
    │   ├── player.dart            # Physics, charge mechanic, states
    │   ├── game_map.dart          # Tile map, crumble runtime state
    │   ├── levels.dart            # 5 hand-designed levels
    │   └── collision.dart         # AABB tile collision + wind
    ├── rendering/
    │   └── game_renderer.dart     # CustomPainter: tiles, player, FX
    ├── ui/
    │   ├── hud.dart               # HUD: level, time, deaths, charge bar
    │   ├── touch_controls.dart    # Left drag + right hold/release
    │   ├── main_menu.dart         # Animated main menu
    │   └── victory_screen.dart    # Victory screen with stats
    └── utils/
        ├── constants.dart         # All constants & color palette
        └── audio_manager.dart     # Audio placeholder
```

---

## 🧱 Tile Types

| Tile | Behavior |
|---|---|
| **Solid** | Normal wall/floor |
| **Platform** | One-way (jump through from below) |
| **Ice** | Slippery — gradual acceleration & carry-over velocity |
| **Crumble** | Shakes then falls 0.5s after standing on it; respawns after 4s |
| **Spike** | Sends you back to last checkpoint |
| **Wind** | Pushes player horizontally while airborne |
| **Checkpoint** | Saves respawn position (flash notification) |
| **Goal** | Advances to next level |

---

## 🗺️ Levels

| # | Name | Theme |
|---|---|---|
| 0 | The Dungeon | Tutorial — basic platforms, spikes, crumble, ice |
| 1 | The Caverns | Tighter gaps, more spikes |
| 2 | The Mossy Ruins | Wind zones added |
| 3 | The Volcanic Peaks | Crumble + ice + wind combo |
| 4 | The Summit | Hardest — all mechanics, narrow gaps |

---

## 🚀 How to Run

### Prerequisites

Install Flutter: https://flutter.dev/docs/get-started/install

### Run

```bash
cd jump_king
flutter pub get
flutter run                # Debug on connected device / emulator
flutter build apk          # Release APK for Android
flutter build ios          # Release build for iOS
```

### Recommended test device
- Android emulator (portrait, any modern API level)
- Physical phone for best touch feel

---

## 🔧 Extending the Game

- **Add sounds**: Fill in `lib/utils/audio_manager.dart` with the `audioplayers` package
- **Add levels**: Add a new `GameLevel` to `lib/game/levels.dart` and increment `JKConstants.totalLevels`
- **Add enemies**: Create an enemy class and render in `GameRenderer`
- **Save progress**: Use `shared_preferences` to persist checkpoint between sessions
"# jump_king" 
