## Memory Crashers - A retro pixel-art card memorization game
## Using PAO (Person-Action-Object) system

import raylib
import types, palette, renderer, animation, input_manager, cards, storage
import scenes/title_scene, scenes/academy_scene, scenes/arena_scene,
       scenes/palace_scene, scenes/daily_scene

when defined(emscripten):
  type EmCallbackFunc = proc() {.cdecl.}
  proc emscriptenSetMainLoop(f: EmCallbackFunc, fps, simulateInfiniteLoop: int32) {.
      cdecl, importc: "emscripten_set_main_loop", header: "<emscripten.h>".}

var
  game*: GameState
  playerData*: PlayerData

proc changeScene*(target: Scene) =
  if game.transition == TransNone:
    game.nextScene = target
    game.transition = TransFadeOut
    game.transitionTimer = 0

proc triggerShake*(intensity: float32 = 3.0; duration: float32 = 0.2) =
  game.screenShake = duration
  game.screenShakeIntensity = intensity

proc initGame() =
  game = GameState(
    scene: SceneTitle,
    nextScene: SceneTitle,
    transition: TransNone,
    transitionTimer: 0,
    transitionDuration: TransitionTime,
    screenShake: 0,
    screenShakeIntensity: 0,
    particles: ParticleSystem(particles: @[]),
  )
  playerData = loadPlayerData()

  # Wire up scene callbacks
  title_scene.changeSceneProc = proc(s: Scene) = changeScene(s)
  academy_scene.changeSceneProc = proc(s: Scene) = changeScene(s)
  arena_scene.changeSceneProc = proc(s: Scene) = changeScene(s)
  palace_scene.changeSceneProc = proc(s: Scene) = changeScene(s)
  daily_scene.changeSceneProc = proc(s: Scene) = changeScene(s)

  academy_scene.triggerShakeProc = proc(intensity: float32, duration: float32) =
    triggerShake(intensity, duration)
  arena_scene.triggerShakeProc = proc(intensity: float32, duration: float32) =
    triggerShake(intensity, duration)
  daily_scene.triggerShakeProc = proc(intensity: float32, duration: float32) =
    triggerShake(intensity, duration)

  academy_scene.gameParticles = addr game.particles
  arena_scene.gameParticles = addr game.particles
  palace_scene.gameParticles = addr game.particles
  daily_scene.gameParticles = addr game.particles

  academy_scene.playerDataPtr = addr playerData
  arena_scene.playerDataPtr = addr playerData
  daily_scene.playerDataPtr = addr playerData

  initTitleScene()

proc updateGame(dt: float32) =
  # Update screen shake
  if game.screenShake > 0:
    game.screenShake -= dt
    if game.screenShake < 0: game.screenShake = 0

  # Update particles
  updateParticles(game.particles, dt)

  # Update scene transition
  if game.transition != TransNone:
    game.transitionTimer += dt
    if game.transitionTimer >= game.transitionDuration:
      game.transitionTimer = 0
      if game.transition == TransFadeOut:
        game.scene = game.nextScene
        game.transition = TransFadeIn
        # Init new scene
        case game.scene
        of SceneTitle: initTitleScene()
        of SceneAcademy: initAcademyScene()
        of SceneArena: initArenaScene()
        of ScenePalace: initPalaceScene()
        of SceneDaily: initDailyScene()
      else:
        game.transition = TransNone

  # Update current scene
  case game.scene
  of SceneTitle: updateTitleScene(dt)
  of SceneAcademy: updateAcademyScene(dt)
  of SceneArena: updateArenaScene(dt)
  of ScenePalace: updatePalaceScene(dt)
  of SceneDaily: updateDailyScene(dt)

proc drawGame() =
  beginGameDraw()
  clearBackground(PalBgDark)

  # Draw current scene
  case game.scene
  of SceneTitle: drawTitleScene()
  of SceneAcademy: drawAcademyScene()
  of SceneArena: drawArenaScene()
  of ScenePalace: drawPalaceScene()
  of SceneDaily: drawDailyScene()

  # Draw particles on top
  drawParticles(game.particles)

  # Draw transition overlay
  if game.transition != TransNone:
    let alpha = if game.transition == TransFadeOut:
      uint8(game.transitionTimer / game.transitionDuration * 255.0)
    else:
      uint8((1.0 - game.transitionTimer / game.transitionDuration) * 255.0)
    drawRectangle(0, 0, GameWidth, GameHeight,
      Color(r: PalBlack.r, g: PalBlack.g, b: PalBlack.b, a: alpha))

  # Shake offset
  var shakeX, shakeY: float32 = 0
  if game.screenShake > 0:
    let t = game.screenShake * game.screenShakeIntensity
    shakeX = float32(getRandomValue(-int32(t * 10), int32(t * 10))) / 10.0
    shakeY = float32(getRandomValue(-int32(t * 10), int32(t * 10))) / 10.0

  endGameDraw(shakeX, shakeY)

proc updateDrawFrame() {.cdecl.} =
  let dt = getFrameTime()
  let mousePos = getMousePosition()
  updateInputManager(mousePos)
  updateGame(dt)
  drawGame()

proc main() =
  setConfigFlags(flags(WindowResizable))
  initWindow(960, 540, "Memory Crashers")
  initRenderer()
  initInputManager()
  initCardTable()
  initGame()

  when defined(emscripten):
    emscriptenSetMainLoop(updateDrawFrame, 0, 1)
  else:
    setTargetFPS(60)
    while not windowShouldClose():
      updateDrawFrame()
    unloadRenderer()
    closeWindow()

main()
