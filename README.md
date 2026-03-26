# mac cat

**A cat that lives on your Mac and chases your mouse cursor all across the screen.**

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Follows your cursor** - walks and hops between levels like a platformer to reach you
- **Lives on your screen** - a transparent overlay cat that roams your desktop
- **Perches on windows** - sits on top of your open apps, grooms, naps
- **Tamagotchi needs** - hunger, happiness, and energy that decay over time
- **Animations** - walking, sitting, sleeping, grooming, playing, stretching, jumping
- **Sounds** - meows when hungry, purrs when petted, chirps when playing
- **Menu bar controls** - feed, play, pet, nap, or wake up your cat

## Install

### Download

1. Grab `maccat.dmg` from [Releases](https://github.com/sameeeeeeep/maccat/releases)
2. Open the DMG and drag maccat to Applications
3. Launch it (right-click > Open if macOS blocks it)

### Build from source

```bash
git clone https://github.com/sameeeeeeep/maccat.git
cd MenuBarCat
xcodebuild -project MenuBarCat.xcodeproj -scheme MenuBarCat build
```

Or open `MenuBarCat.xcodeproj` in Xcode and hit Run.

## Controls

Click the 🐾 in your menu bar:

| Action | Shortcut | What it does |
|--------|----------|--------------|
| Feed | `Cmd+F` | Fills hunger, cat meows |
| Play | `Cmd+P` | Boosts happiness, uses energy |
| Pet | `Cmd+E` | Happiness + energy, cat purrs |
| Nap | `Cmd+N` | Cat sleeps, restores energy |
| Wake Up | `Cmd+W` | Wakes a sleeping cat |
| Rename | `Cmd+R` | Name your cat |

## How it works

The cat lives in a transparent fullscreen window. The screen is divided into horizontal platforms - when the cursor is on a different level, the cat does diagonal hops (like jumping up stairs) to reach it, then walks the rest of the way.

Needs (hunger, happiness, energy) decay every 30 seconds. If they get low, the cat meows at you. State is saved between launches via UserDefaults.

## Contributing

Open source under the MIT license. PRs welcome - ideas:

- More cat skins / sprite sheets
- Multiple cats
- Cat toys that appear on screen
- Better walk animation cycle
- Launch at login
- Homebrew formula

## Credits

Built with [Claude Code](https://claude.ai/code). Cat sprites from the pixel art community.

## License

MIT
