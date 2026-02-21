# Memory Crashers

A retro pixel-art card memorization game using the **PAO (Person-Action-Object) system** — the same technique used by memory athletes to memorize a full deck of 52 cards.

Built in **Nim + naylib (raylib)** with a PICO-8-inspired art style: thick outlines, flat colors, 32-color palette, bouncy animations, screen shake, and particles.

![Memory Crashers Title Screen](docs/title.png)

## How to Run

### Prerequisites

1. **Install Nim** (2.0+):
   ```bash
   brew install nim        # macOS
   # or: choosenim stable  # cross-platform
   ```

2. **Install naylib**:
   ```bash
   nimble install naylib
   ```

### Build & Run (Native)

```bash
# Debug build (faster compile, slower runtime)
nim c -r memory_crashers.nim

# Release build (slower compile, optimized runtime)
nim c -r -d:release memory_crashers.nim
```

The game window opens at 960x540 (resizable). Internal resolution is 320x180, pixel-perfect scaled.

### Build for Web (Optional)

Requires [Emscripten SDK](https://emscripten.org/docs/getting_started/downloads.html):

```bash
# Install emsdk
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk && ./emsdk install latest && ./emsdk activate latest
source ./emsdk_env.sh
cd ..

# Build
nim c -d:emscripten -d:release memory_crashers.nim

# Serve locally
cd public && python3 -m http.server 8080
# Open http://localhost:8080
```

## Game Modes

### 1. Card Academy (Learn)
Flashcard drill for all 52 PAO associations. Tap to flip cards, navigate with arrow keys, switch to quiz mode where you match persons to cards. Tracks per-card mastery (0-5 stars).

### 2. Battle Arena (Practice)
Timed memorize-then-recall challenge. See cards one at a time, memorize the order, then select them back in sequence from a grid. 4 difficulties:
- **Easy**: 5 cards
- **Medium**: 13 cards (one suit)
- **Hard**: 26 cards (half deck)
- **Insane**: 52 cards (full deck)

Score = accuracy % x speed bonus. High scores persist.

### 3. Memory Palace (Visualize)
Top-down pixel-art rooms (Kitchen, Bedroom, Garden, Library). Walk an 8x12 knight character with WASD/arrows. Each room has 3 stations where you place PAO triples — a visual implementation of the Method of Loci technique.

### 4. Daily Challenge
Full 52-card deck with a day-based seed (same puzzle for everyone). One attempt per day. Streak counter for consecutive days played.

## Controls

| Input | Action |
|-------|--------|
| **Mouse click** | Select buttons, cards |
| **Arrow keys / WASD** | Navigate cards, move knight |
| **Space** | Flip card (Academy) |
| **E** | Interact with station (Palace) |
| **Enter** | Confirm / advance |
| **Escape** | Cancel (Palace overlay) |

## The PAO System

Each card maps to a **Person**, **Action**, and **Object**:

| Suit | Theme | Examples |
|------|-------|----------|
| Hearts | Warm/Performers | Elvis, Cupid, Einstein, Cleopatra |
| Diamonds | Rich/Glamorous | Trump, James Bond, Da Vinci, Gatsby |
| Clubs | Tough/Athletic | Ali, Bruce Lee, Jordan, Wonder Woman |
| Spades | Dark/Mysterious | Death, Dracula, Sherlock, Merlin |

When memorizing 3 cards at a time, combine: Card 1's Person + Card 2's Action + Card 3's Object = one vivid composite image. A full 52-card deck becomes just 17 images.

## Tech Stack

| Layer | Choice |
|-------|--------|
| Language | Nim 2.0+ |
| Graphics | naylib (raylib wrapper) |
| Web target | Emscripten -> WASM |
| Resolution | 320x180, scaled to window |
| Palette | 32 custom colors (PICO-8/NES inspired) |
| Persistence | localStorage (web) / save.json (native) |

## Project Structure

```
memory_crashers.nim          # Entry point, main loop, scene dispatch
memory_crashers.nims         # Build config (native + emscripten)
minshell.html                # HTML shell for web builds
src/
  types.nim                  # All shared types
  palette.nim                # 32-color palette
  cards.nim                  # 52-card PAO table, deck ops
  player.nim                 # XP, leveling, streaks
  renderer.nim               # RenderTexture scaling, card drawing
  animation.nim              # Easing, tweens, particles
  ui.nim                     # Pixel buttons, progress bars
  input_manager.nim          # Mouse -> game coordinate mapping
  storage.nim                # Persistence (localStorage / file)
  scenes/
    title_scene.nim          # Bouncing logo, mode buttons
    academy_scene.nim        # Flashcard + quiz drill
    arena_scene.nim          # Timed memorize -> recall
    palace_scene.nim         # Top-down room exploration
    daily_scene.nim          # Day-seeded challenge
```

## License

MIT
