## Memory Crashers - A retro pixel-art card memorization game
## Using PAO (Person-Action-Object) system
## Learning-first redesign: Home -> Learn / Practice / Speed / Daily

import raylib
import std/sequtils
import types, palette, design, renderer, animation, ui, input_manager, cards, storage, tutorial
import scenes/home_scene, scenes/learn_scene, scenes/practice_scene,
       scenes/daily_scene, scenes/speed_scene, scenes/browse_scene

when defined(emscripten):
  type EmCallbackFunc = proc() {.cdecl.}
  proc emscriptenSetMainLoop(f: EmCallbackFunc; fps, simulateInfiniteLoop: int32) {.
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
    scene: SceneHome,
    nextScene: SceneHome,
    transition: TransNone,
    transitionTimer: 0,
    transitionDuration: TransitionTime,
    screenShake: 0,
    screenShakeIntensity: 0,
    particles: ParticleSystem(particles: @[]),
    floatingTexts: @[],
    levelUpTimer: 0,
  )
  playerData = loadPlayerData()

  # Wire up scene callbacks
  home_scene.changeSceneProc = proc(s: Scene) = changeScene(s)
  learn_scene.changeSceneProc = proc(s: Scene) = changeScene(s)
  practice_scene.changeSceneProc = proc(s: Scene) = changeScene(s)
  daily_scene.changeSceneProc = proc(s: Scene) = changeScene(s)
  speed_scene.changeSceneProc = proc(s: Scene) = changeScene(s)
  browse_scene.changeSceneProc = proc(s: Scene) = changeScene(s)

  learn_scene.triggerShakeProc = proc(intensity: float32; duration: float32) =
    triggerShake(intensity, duration)
  practice_scene.triggerShakeProc = proc(intensity: float32; duration: float32) =
    triggerShake(intensity, duration)
  daily_scene.triggerShakeProc = proc(intensity: float32; duration: float32) =
    triggerShake(intensity, duration)
  speed_scene.triggerShakeProc = proc(intensity: float32; duration: float32) =
    triggerShake(intensity, duration)

  learn_scene.gameParticles = addr game.particles
  practice_scene.gameParticles = addr game.particles
  daily_scene.gameParticles = addr game.particles
  speed_scene.gameParticles = addr game.particles

  home_scene.playerDataPtr = addr playerData
  learn_scene.playerDataPtr = addr playerData
  practice_scene.playerDataPtr = addr playerData
  daily_scene.playerDataPtr = addr playerData
  speed_scene.playerDataPtr = addr playerData
  browse_scene.playerDataPtr = addr playerData

  # Floating text pointers
  home_scene.gameFloatingTexts = addr game.floatingTexts
  learn_scene.gameFloatingTexts = addr game.floatingTexts
  practice_scene.gameFloatingTexts = addr game.floatingTexts
  daily_scene.gameFloatingTexts = addr game.floatingTexts
  speed_scene.gameFloatingTexts = addr game.floatingTexts
  browse_scene.gameFloatingTexts = addr game.floatingTexts

  initHomeScene()

proc updateGame(dt: float32) =
  # TAB toggles tutorial overlay
  if isKeyPressed(Tab):
    toggleTutorial(game.scene)

  # If tutorial is open, only update tutorial
  if tutorialVisible:
    updateTutorial()
    return

  # Update screen shake
  if game.screenShake > 0:
    game.screenShake -= dt
    if game.screenShake < 0: game.screenShake = 0

  # Update particles
  updateParticles(game.particles, dt)

  # Update floating texts
  updateFloatingTexts(game.floatingTexts, dt)

  # Update level-up timer
  if game.levelUpTimer > 0:
    game.levelUpTimer -= dt

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
        of SceneHome:
          initHomeScene()
          tutorialRefCards = toSeq(0..51)
        of SceneLearn:
          initLearnScene()
          tutorialRefCards = toSeq(0..51)
        of ScenePractice:
          initPracticeScene()
          tutorialRefCards = toSeq(0..51)
        of SceneDaily:
          initDailyScene()
          tutorialRefCards = toSeq(0..51)
        of SceneSpeedCards:
          initSpeedScene()
          tutorialRefCards = toSeq(0..51)
        of SceneBrowse:
          initBrowseScene()
          tutorialRefCards = toSeq(0..51)
      else:
        game.transition = TransNone

  # Update current scene
  case game.scene
  of SceneHome: updateHomeScene(dt)
  of SceneLearn: updateLearnScene(dt)
  of ScenePractice: updatePracticeScene(dt)
  of SceneDaily: updateDailyScene(dt)
  of SceneSpeedCards: updateSpeedScene(dt)
  of SceneBrowse: updateBrowseScene(dt)

proc drawGame() =
  beginGameDraw()
  clearBackground(PalBgDark)

  # Draw current scene
  case game.scene
  of SceneHome: drawHomeScene()
  of SceneLearn: drawLearnScene()
  of ScenePractice: drawPracticeScene()
  of SceneDaily: drawDailyScene()
  of SceneSpeedCards: drawSpeedScene()
  of SceneBrowse: drawBrowseScene()

  # Draw particles on top
  drawParticles(game.particles)

  # Draw floating texts
  drawFloatingTexts(game.floatingTexts)

  # Level-up flash
  if game.levelUpTimer > 0:
    let alpha = uint8(min(game.levelUpTimer / 1.0, 1.0) * 255.0)
    let col = Color(r: PalGold.r, g: PalGold.g, b: PalGold.b, a: alpha)
    drawCenteredTextShadow("LEVEL UP!", 80, 14, col)

  # Draw tutorial overlay (on top of everything except transition)
  drawTutorial()

  # Help button in header (for mobile/touch) — top right
  if not tutorialVisible:
    if drawHelpButton(int32(HelpBtnX), int32(HelpBtnY)):
      toggleTutorial(game.scene)

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
