# Memory Crashers - Progress

## Phase 1: Skeleton [DONE]
- [x] Entry point with window init, render target, main loop
- [x] Build config for native + emscripten
- [x] HTML shell template for web builds
- [x] Type definitions (cards, state, enums, tweens, particles)
- [x] 32-color palette (PICO-8/NES inspired)
- [x] RenderTexture pipeline (320x180 scaled to window with letterboxing)
- [x] Card drawing (face, back, suit symbols)
- [x] Verified: colored game renders at 320x180 scaled to window

## Phase 2: Cards + Animation + UI [DONE]
- [x] PAO table with all 52 entries (themed by suit)
- [x] Deck shuffle and seeded shuffle operations
- [x] Easing functions (linear, quad, back, bounce, elastic)
- [x] Tween system for smooth animations
- [x] Particle system with burst and confetti effects
- [x] Pixel buttons with hover states and shadows
- [x] Progress bars and text panels
- [x] Mouse-to-game coordinate mapping for scaled resolution

## Phase 3: Title + Academy [DONE]
- [x] Title scene with bouncing logo and idle animation
- [x] Gradient background with purple-to-navy stripes
- [x] 4 color-coded mode buttons
- [x] Scene transition system (fade out -> init -> fade in)
- [x] Academy flashcard mode (flip with Space, navigate with arrows)
- [x] Academy quiz mode (4-option person matching)
- [x] Card flip animation (horizontal scale trick)
- [x] Per-card mastery tracking
- [x] Confetti on correct answers, screen shake on wrong

## Phase 4: Arena + Persistence + Player [DONE]
- [x] Arena setup with 4 difficulty levels
- [x] Memorize phase (card-by-card viewing with timer)
- [x] Recall phase (grid selection in order)
- [x] Results screen (accuracy x speed bonus scoring)
- [x] High score tracking per difficulty
- [x] JSON persistence (localStorage for web, save.json for native)
- [x] XP and leveling system
- [x] Streak tracking (consecutive days)

## Phase 5: Palace + Daily [DONE]
- [x] 4 rooms (Kitchen, Bedroom, Garden, Library) with tile floors
- [x] Knight character with directional sprite and walk animation
- [x] WASD/arrow movement with room-edge transitions
- [x] 3 PAO stations per room with proximity interaction
- [x] Card placement overlay
- [x] Daily challenge with day-based seed
- [x] One-attempt-per-day enforcement
- [x] Streak counter and XP bonus for consecutive days

## Phase 6: Polish [DONE]
- [x] Clean compile with minimal warnings
- [x] Release build verified
- [x] All scene callbacks wired up
- [x] Proper git repo with stacked feature commits

---

## Future Enhancements
- [ ] Sound effects (correct ding, wrong buzz, card flip, select)
- [ ] More particle effects and screen juice
- [ ] Custom pixel font (replace raylib default)
- [ ] AI-generated character sprites (PixelLab/Retro Diffusion)
- [ ] Player stats display on title screen (level, mastery %)
- [ ] Spaced repetition algorithm for Academy drill order
- [ ] Web build CI/CD pipeline
- [ ] Touch-friendly mobile controls
- [ ] Leaderboard (SpacetimeDB or simple backend)
- [ ] Custom PAO editor (let users define their own associations)
