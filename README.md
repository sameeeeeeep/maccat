# macthecat

**A desktop pet cat for macOS that follows your cursor, befriends your apps, and fights you off Instagram.**

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Follows your cursor** - walks and hops between levels like a platformer to reach you
- **Buddy cat** - a companion cat spawns based on your active app or website (orange for Claude, blue for VS Code, pink for Instagram, red for YouTube, and many more)
- **Focus mode** - blocks distracting sites (Instagram, YouTube, Reddit, TikTok, etc.) by having your cats fight on screen until you navigate away
- **Tamagotchi needs** - hunger, happiness, and energy that decay over time
- **Sprite animations** - walking, sitting, sleeping, grooming, playing, stretching, jumping
- **Sounds** - meows, purrs, chirps, and hisses (with mute toggle)
- **Color picker** - original, orange, ginger, golden, black, white, blue, pink
- **Perches on windows** - sits on top of your open apps

## Install

### Download

1. Grab `macthecat.dmg` from [Releases](https://github.com/sameeeeeeep/maccat/releases)
2. Open the DMG and drag macthecat to Applications
3. Launch it (right-click > Open if macOS blocks it)

### Build from source

```bash
git clone https://github.com/sameeeeeeep/maccat.git
cd maccat
xcodebuild -project MenuBarCat.xcodeproj -scheme MenuBarCat build
```

Or open `MenuBarCat.xcodeproj` in Xcode and hit Run.

## Controls

Click the pawprint in your menu bar:

| Action | Shortcut | What it does |
|--------|----------|--------------|
| Feed | Cmd+F | Fills hunger, cat meows |
| Play | Cmd+P | Boosts happiness, uses energy |
| Pet | Cmd+E | Happiness + energy, cat purrs |
| Nap | Cmd+N | Cat sleeps, restores energy |
| Wake Up | Cmd+W | Wakes a sleeping cat |
| Rename | Cmd+R | Name your cat |
| Buddy Cat | Cmd+B | Toggle companion cat on/off |
| Focus Mode | Cmd+D | Block distracting websites |
| Mute Sound | Cmd+M | Toggle all sounds |

## How it works

The cat lives in a transparent fullscreen window. The screen is divided into horizontal platforms - when the cursor is on a different level, the cat does diagonal hops (like jumping up stairs) to reach it, then walks the rest of the way.

**Buddy cat** detects your frontmost app via NSWorkspace and reads browser tab URLs via AppleScript (first launch asks for automation permission). Each app/site gets a themed companion cat color.

**Focus mode** checks the active Chrome/Safari tab URL against a blocklist. When you're on a distracting site, the screen darkens and both cats start fighting until you leave.

Needs (hunger, happiness, energy) decay every 30 seconds. If they get low, the cat meows at you. State is saved between launches via UserDefaults.

## Permissions

- **Automation** (one-time prompt) - to read browser tab URLs for buddy cat and focus mode

## Contributing

Open source under the MIT license. PRs welcome - ideas:

- More cat skins / sprite sheets
- Multiple user cats
- Cat toys that appear on screen
- Launch at login
- Custom blocklist for focus mode
- Homebrew formula

## Credits

Built with [Claude Code](https://claude.ai/code). Cat sprites from the pixel art community.

## License

MIT
