# macthecat

**your mac has a cat now. deal with it.**

a pixel art cat that lives on your screen, chases your cursor like it owes him money, and judges your browser habits.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## what does he do

- **chases your cursor** - hops between levels like a little platformer character. he will find you.
- **buddy system** - a second cat spawns based on whatever app you're using. open Claude? orange cat appears. VS Code? blue cat. Instagram? pink cat. they hang out together.
- **focus mode** - turn this on and try opening Instagram. your cats will literally start fighting on screen and block you from doomscrolling. you asked for this.
- **tamagotchi vibes** - hunger, happiness, energy. they decay. he will meow at you when he's hungry. you will feel guilty.
- **sounds** - meows, purrs, chirps when happy, hisses when you're on Instagram in focus mode. mute button exists if your coworkers are wondering why your laptop is meowing.
- **customizable** - 8 colors. rename him whatever you want. he doesn't care, he's a cat.

## install

### download

1. grab `macthecat.dmg` from [Releases](https://github.com/sameeeeeeep/maccat/releases)
2. drag to Applications
3. launch (right-click > Open if macOS gets suspicious)

### build from source

```bash
git clone https://github.com/sameeeeeeep/maccat.git
cd maccat
xcodebuild -project MenuBarCat.xcodeproj -scheme MenuBarCat build
```

or just open the `.xcodeproj` in Xcode and hit Run.

## controls

click the pawprint in your menu bar:

| action | shortcut | what happens |
|--------|----------|-------------|
| Feed | Cmd+F | fills hunger, grateful meow |
| Play | Cmd+P | boosts happiness, burns energy |
| Pet | Cmd+E | purring intensifies |
| Nap | Cmd+N | zzz, energy recharges |
| Wake Up | Cmd+W | interrupts his nap (rude) |
| Rename | Cmd+R | he won't respond to it anyway |
| Buddy Cat | Cmd+B | toggle the companion cat |
| Focus Mode | Cmd+D | blocks distracting sites via cat violence |
| Mute Sound | Cmd+M | silence the meowing |

## how it actually works

transparent fullscreen NSWindow. cat sprite walks around on it. screen is divided into horizontal platforms - cat does diagonal staircase hops to reach your cursor level, then walks horizontally.

**buddy cat** reads your frontmost app via `NSWorkspace` and browser tab URLs via AppleScript (Chrome, Safari, Arc, Brave, Edge, Firefox). each app/site maps to a colored companion.

**focus mode** checks the active tab URL against a blocklist (instagram, youtube, reddit, tiktok, twitter, facebook, netflix, twitch, linkedin, threads). match = screen darkens, cats fight, mouse blocked. navigate away = peace restored.

stats decay every 30s. state persists via UserDefaults.

## permissions

first time you enable focus mode or use a browser, macOS asks to let macthecat control Chrome/Safari. say yes or the cat can't read your tabs and focus mode won't work.

## contributing

MIT licensed. PRs welcome:

- more sprite sheets / skins
- custom focus mode blocklist
- multiple user cats
- cat toys on screen
- launch at login
- homebrew formula
- whatever weird cat feature you can think of

## credits

built with [Claude Code](https://claude.ai/code). sprite sheet from the pixel art community.

## license

MIT
