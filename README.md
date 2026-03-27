# macthecat

**your mac has a cat now. deal with it.**

a pixel art pet that lives on your screen, chases your cursor like it owes him money, and judges your browser habits. pick your vibe — cat, dog, or bird.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## what does he do

- **chases your cursor** - hops between levels like a little platformer character. he will find you.
- **animal themes** - cat, dog, or bird. each with their own sprites, sounds, and personality. cat meows, dog barks, bird tweets. they all judge you equally.
- **buddy system** - a companion spawns based on whatever app you're using. open Claude? orange buddy. VS Code? blue buddy. Instagram? pink buddy. they hang out together.
- **focus mode** - turn this on and try opening Instagram. your pets will literally start fighting on screen and block you from doomscrolling. you asked for this.
- **focus timer** - set a 5-60 minute timer from the menu. your pet stays focused and so should you. tiny timer floats above them as a reminder.
- **tamagotchi vibes** - hunger, happiness, energy. they decay. he will meow/bark/tweet at you when he's hungry. you will feel guilty.
- **sounds** - theme-specific audio. meows, barks, tweets, purrs, growls, hisses. mute button exists if your coworkers are wondering why your laptop is barking.
- **customizable** - 8 colors (for cat theme). rename your pet whatever you want. they don't care.

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
| Buddy | Cmd+B | toggle the companion pet |
| Focus Mode | Cmd+D | blocks distracting sites via cat violence |
| Mute Sound | Cmd+M | silence the meowing |

## how it actually works

transparent fullscreen NSWindow. pet sprite walks around on it. screen is divided into horizontal platforms - pet does diagonal staircase hops to reach your cursor level, then walks horizontally.

**themes** — swap between cat, dog, and bird. each theme has its own sprite sheets, sounds, avatar art, and mood emojis. sprites are pixel art loaded from theme-specific directories.

**buddy** reads your frontmost app via `NSWorkspace` and browser tab URLs via AppleScript (Chrome, Safari, Arc, Brave, Edge, Firefox). each app/site maps to a colored companion that follows your main pet around.

**focus mode** checks the active tab URL against a blocklist (instagram, youtube, reddit, tiktok, twitter, facebook, netflix, twitch, linkedin, threads). match = screen darkens, pets fight, mouse blocked. navigate away = peace restored.

**focus timer** — set from the menu (5-60 min). pet stays seated with a countdown timer floating above. returns to normal behavior when time's up.

stats decay every 30s. state persists via UserDefaults.

## permissions

first time you enable focus mode or use a browser, macOS asks to let macthecat control Chrome/Safari. say yes or the cat can't read your tabs and focus mode won't work.

## contributing

MIT licensed. PRs welcome:

- more animal themes (panda, snake, etc.)
- custom focus mode blocklist
- pet interactions and toys
- launch at login
- homebrew formula
- whatever weird pet feature you can think of

## credits

built with [Claude Code](https://claude.ai/code). sprite sheet from the pixel art community.

## license

MIT
