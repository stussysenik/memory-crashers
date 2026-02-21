# Memory Crashers - Technical Documentation

## Architecture Overview

### Game State Machine
```
TITLE -> { ACADEMY | ARENA | PALACE | DAILY } -> TITLE
```

Each scene exposes `init`, `update(dt)`, `draw()` procs. Scene transitions use a 0.3s fade overlay (fade out -> init new scene -> fade in). The main module (`memory_crashers.nim`) dispatches to scenes via a `case` statement.

### Rendering Pipeline

1. A `RenderTexture` is created at 320x180 with `Point` (nearest-neighbor) filtering
2. All scenes draw to this low-res render target via `beginGameDraw()`
3. The target is scaled to fill the window with letterboxing in `endGameDraw()`
4. Y-flip is handled via negative source height in `drawTexture`
5. Screen shake applies random offset to the final blit

```
beginGameDraw()        # beginTextureMode(target)
  clearBackground()
  drawScene()          # all 320x180 pixel drawing
  drawParticles()
  drawTransition()     # fade overlay
endGameDraw(shakeX, shakeY)  # endTextureMode + scale to window
```

### Scene Communication

Scenes are decoupled from the main module via callback procs:
- `changeSceneProc: proc(Scene)` — request scene transition
- `triggerShakeProc: proc(float32, float32)` — screen shake
- `gameParticles: ptr ParticleSystem` — shared particle emitter
- `playerDataPtr: ptr PlayerData` — shared player state

These are wired up in `initGame()` after all scenes are imported.

### Card System

52 cards organized by suit theme:
- **Hearts (0-12)**: Warm, performers, loved ones
- **Diamonds (13-25)**: Rich, prestigious, glamorous
- **Clubs (26-38)**: Tough, athletic, action figures
- **Spades (39-51)**: Dark, powerful, mysterious

Each card has a `PaoEntry` with `person`, `action`, and `obj` strings.

Card index = `suit.ord * 13 + rank.ord` (0-51).

### Card Flip Animation

Uses horizontal scale trick:
```
absFlip = abs(progress * 2 - 1)    # 1->0->1 curve
drawWidth = cardWidth * absFlip
if progress < 0.5: drawBack else: drawFace
```
At progress 0.5, width hits 0 (invisible) and switches from back to face.

### Persistence

**Native**: Reads/writes `save.json` in the working directory.

**Web**: Uses `emscripten_run_script` to call `localStorage.setItem/getItem` with JSON string. Data is escaped for single-quote JS strings.

**Daily seed**: `Math.floor(Date.now() / 86400000)` gives a unique integer per UTC day. Both web and native compute the same seed, ensuring identical decks.

### Player Progression

| Action | XP |
|--------|-----|
| Card studied | +2 |
| Quiz correct | +10 |
| Arena complete | +25 |
| Daily complete | +50 |
| Streak bonus | +5/day |

Level threshold: `level * 100` XP per level.

Card mastery: 0-5 per card. Correct answers increment, wrong answers decrement.

## Build System

### `memory_crashers.nims`

The `.nims` file (same name as `.nim`) is automatically loaded by the Nim compiler. It:
1. Adds `src/` to the module search path
2. Sets `--mm:orc` for the memory manager
3. When `-d:emscripten` is defined, configures the full Emscripten toolchain:
   - Sets `--os:linux --cpu:wasm32 --cc:clang`
   - Routes through `emcc` as compiler/linker
   - Passes output path, shell file, and memory growth flags

### naylib Auto-Flags

When `-d:emscripten` is defined, naylib internally adds:
- `-DPLATFORM_WEB`, `-DGRAPHICS_API_OPENGL_ES2`
- `-sUSE_GLFW=3`, `-sWASM=1`, `-sTOTAL_MEMORY=134217728`
- `-sEXPORTED_RUNTIME_METHODS=ccall`
- Resource preloading if `-d:NaylibWebResources`

You do NOT need to add these yourself.

### Web Main Loop

Browsers control the event loop. The game uses:
```nim
when defined(emscripten):
  emscriptenSetMainLoop(updateDrawFrame, 0, 1)
else:
  while not windowShouldClose(): updateDrawFrame()
```

`updateDrawFrame` must be `{.cdecl.}` and all state must be module-level globals.

## Module Dependency Graph

```
memory_crashers.nim
  ├── types.nim          (shared types, no deps)
  ├── palette.nim        (colors, depends on raylib)
  ├── renderer.nim       (depends on types, palette)
  ├── animation.nim      (depends on types, palette)
  ├── ui.nim             (depends on types, palette, input_manager)
  ├── input_manager.nim  (depends on types)
  ├── cards.nim          (depends on types)
  ├── player.nim         (depends on types)
  ├── storage.nim        (depends on types)
  └── scenes/
      ├── title_scene.nim    (depends on types, palette, ui, animation)
      ├── academy_scene.nim  (depends on types, palette, ui, animation, renderer, cards, player)
      ├── arena_scene.nim    (depends on types, palette, ui, animation, renderer, cards, player, storage)
      ├── palace_scene.nim   (depends on types, palette, ui, renderer, cards)
      └── daily_scene.nim    (depends on types, palette, ui, animation, renderer, cards, player, storage)
```

## PAO Table Reference

Full 52-card PAO assignments are in `src/cards.nim`. The table is intentionally using well-known cultural figures for universality. Users should eventually be able to customize these to personal associations (planned feature).

### Hearts (Warm / Performers)
| Rank | Person | Action | Object |
|------|--------|--------|--------|
| A | Elvis | singing to | microphone |
| 2 | Cupid | shooting | bow & arrow |
| 3 | Romeo | serenading | balcony |
| 4 | Juliet | dancing with | rose |
| 5 | Marilyn | blowing | kiss |
| 6 | Ellen | laughing at | joke book |
| 7 | Mr. Rogers | waving from | cardigan |
| 8 | Oprah | giving away | car keys |
| 9 | Einstein | scribbling on | chalkboard |
| 10 | Mother Teresa | hugging | blanket |
| J | Prince | strumming | guitar |
| Q | Cleopatra | reclining on | throne |
| K | King Arthur | pulling out | sword |

### Diamonds (Rich / Glamorous)
| Rank | Person | Action | Object |
|------|--------|--------|--------|
| A | Trump | pointing at | gold tower |
| 2 | Midas | touching | golden apple |
| 3 | Scrooge | diving into | coin pile |
| 4 | Gatsby | toasting with | champagne |
| 5 | James Bond | shuffling | poker chips |
| 6 | Beyonce | strutting in | high heels |
| 7 | Jay Leno | polishing | sports car |
| 8 | Liberace | playing | grand piano |
| 9 | Da Vinci | painting | canvas |
| 10 | Rockefeller | signing | big check |
| J | Sinatra | crooning into | martini glass |
| Q | Marie Antoinette | eating | cake |
| K | Louis XIV | admiring | mirror |

### Clubs (Tough / Athletic)
| Rank | Person | Action | Object |
|------|--------|--------|--------|
| A | Ali | punching | heavy bag |
| 2 | Hercules | lifting | boulder |
| 3 | Ninja | throwing | shuriken |
| 4 | Tarzan | swinging on | vine |
| 5 | Schwarzenegger | flexing | dumbbell |
| 6 | Bruce Lee | kicking | wooden dummy |
| 7 | Jordan | dunking | basketball |
| 8 | Thor | swinging | hammer |
| 9 | Robin Hood | firing | longbow |
| 10 | Gladiator | slashing with | trident |
| J | Rocky | running up | stairs |
| Q | Wonder Woman | blocking with | shield |
| K | Spartacus | rallying | army flag |

### Spades (Dark / Mysterious)
| Rank | Person | Action | Object |
|------|--------|--------|--------|
| A | Death | reaping with | scythe |
| 2 | Dracula | biting into | goblet |
| 3 | Houdini | escaping from | chains |
| 4 | Darth Vader | force-choking | helmet |
| 5 | Sherlock | inspecting | magnifier |
| 6 | Witch | stirring | cauldron |
| 7 | Merlin | casting on | crystal ball |
| 8 | Phantom | lurking behind | mask |
| 9 | Rasputin | hypnotizing | pendulum |
| 10 | Voldemort | zapping with | wand |
| J | Joker | cackling at | playing card |
| Q | Medusa | petrifying | mirror shield |
| K | Grim Reaper | summoning | hourglass |
