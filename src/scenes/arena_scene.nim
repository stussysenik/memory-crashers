## Arena Scene: Timed memorize -> recall challenge

import raylib
import std/strutils
import ../types, ../palette, ../ui, ../animation, ../renderer, ../cards,
       ../input_manager, ../player, ../storage

var
  phase: ArenaPhase
  difficulty: Difficulty
  arenaDeck: seq[int]
  cardCount: int
  currentViewCard: int
  memorizeTimer: float32
  recallSelected: seq[int]  # player's guessed order
  recallGrid: seq[int]     # shuffled cards for selection
  scoreAccuracy: float32
  scoreFinal: int
  backButton: PixelButton
  diffButtons: array[4, PixelButton]
  startButton: PixelButton
  nextCardButton: PixelButton
  prevCardButton: PixelButton
  doneMemButton: PixelButton
  undoButton: PixelButton
  flipTween: Tween
  showingCard: bool

var changeSceneProc*: proc(s: Scene)
var triggerShakeProc*: proc(intensity: float32, duration: float32)
var gameParticles*: ptr ParticleSystem
var playerDataPtr*: ptr PlayerData

proc initArenaScene*() =
  phase = ArenaSetup
  difficulty = Easy
  arenaDeck = @[]
  recallSelected = @[]
  recallGrid = @[]
  memorizeTimer = 0
  showingCard = true

  backButton = newPixelButton(4, 4, 40, 14, "Back", PalRedDark, PalRed, PalWhite)
  startButton = newPixelButton(110, 140, 100, 20, "Start!", PalGreen, PalLime, PalBlack)

  for i in 0..3:
    let d = Difficulty(i)
    diffButtons[i] = newPixelButton(
      30 + float32(i) * 70, 90, 60, 18,
      difficultyName(d), PalBlueDark, PalBlue, PalWhite)

proc startArena() =
  cardCount = difficultyCardCount(difficulty)
  arenaDeck = newDeck()
  shuffleDeck(arenaDeck)
  arenaDeck.setLen(cardCount)

  currentViewCard = 0
  memorizeTimer = 0
  recallSelected = @[]
  showingCard = true

  recallGrid = arenaDeck
  var gridCopy = recallGrid
  for i in countdown(gridCopy.len - 1, 1):
    let j = getRandomValue(0, int32(i))
    swap(gridCopy[i], gridCopy[j])
  recallGrid = gridCopy

  phase = ArenaMemorize

  let btnY = GameHeight.float32 - 22
  prevCardButton = newPixelButton(40, btnY, 50, 16, "< Prev", PalGrayDark, PalGray, PalWhite)
  nextCardButton = newPixelButton(170, btnY, 50, 16, "Next >", PalGrayDark, PalGray, PalWhite)
  doneMemButton = newPixelButton(110, btnY, 60, 16, "Done!", PalGreen, PalLime, PalBlack)

proc calculateScore() =
  var correct = 0
  for i in 0..<min(recallSelected.len, arenaDeck.len):
    if recallSelected[i] == arenaDeck[i]:
      correct += 1
  scoreAccuracy = if arenaDeck.len > 0: float32(correct) / float32(arenaDeck.len)
                  else: 0
  # Time bonus: faster = higher multiplier (max 2x for very fast)
  let timeBonus = max(0.5, 2.0 - memorizeTimer / (float32(cardCount) * 5.0))
  scoreFinal = int(scoreAccuracy * 100.0 * timeBonus)

  if playerDataPtr != nil:
    let d = difficulty.ord
    if scoreFinal > playerDataPtr[].arenaHighScores[d]:
      playerDataPtr[].arenaHighScores[d] = scoreFinal
    addXp(playerDataPtr[], XpArenaComplete)
    savePlayerData(playerDataPtr[])

proc updateArenaScene*(dt: float32) =
  if updateButton(backButton):
    if changeSceneProc != nil:
      changeSceneProc(SceneTitle)
    return

  updateTween(flipTween, dt)

  case phase
  of ArenaSetup:
    for i in 0..3:
      if updateButton(diffButtons[i]):
        difficulty = Difficulty(i)
    if updateButton(startButton):
      startArena()

  of ArenaMemorize:
    memorizeTimer += dt

    if updateButton(prevCardButton):
      if currentViewCard > 0:
        currentViewCard -= 1
        flipTween = newTween(0, 1, 0.25, EaseOutQuad)
    if updateButton(nextCardButton):
      if currentViewCard < cardCount - 1:
        currentViewCard += 1
        flipTween = newTween(0, 1, 0.25, EaseOutQuad)
    if updateButton(doneMemButton):
      phase = ArenaRecall
      undoButton = newPixelButton(4, GameHeight.float32 - 20, 40, 16,
        "Undo", PalRedDark, PalRed, PalWhite)

    # Keyboard
    if isKeyPressed(Left) and currentViewCard > 0:
      currentViewCard -= 1
      flipTween = newTween(0, 1, 0.25, EaseOutQuad)
    if isKeyPressed(Right) and currentViewCard < cardCount - 1:
      currentViewCard += 1
      flipTween = newTween(0, 1, 0.25, EaseOutQuad)
    if isKeyPressed(Enter):
      phase = ArenaRecall

  of ArenaRecall:
    if updateButton(undoButton):
      if recallSelected.len > 0:
        discard recallSelected.pop()

    # Click on grid cards
    let mp = gameMousePos()
    let cols = min(cardCount, 13)
    let gridW = cols * (CardWidth + 2)
    let startX = (GameWidth - gridW) div 2
    let startY: int32 = 30

    for i in 0..<recallGrid.len:
      if recallGrid[i] in recallSelected:
        continue  # already selected
      let col = i mod cols
      let row = i div cols
      let cx = float32(startX + int32(col) * (CardWidth + 2))
      let cy = float32(startY + int32(row) * (CardHeight + 2))
      let rect = Rectangle(x: cx, y: cy,
                            width: CardWidth.float32, height: CardHeight.float32)
      if checkCollisionPointRec(mp, rect) and isMouseButtonPressed(Left):
        recallSelected.add(recallGrid[i])
        if recallSelected.len == cardCount:
          calculateScore()
          phase = ArenaResults
          if scoreAccuracy >= 0.8:
            if gameParticles != nil:
              spawnConfetti(gameParticles[], Vector2(x: 160, y: 90), 30)

  of ArenaResults:
    # Click anywhere to go back to setup
    if isMouseButtonPressed(Left) or isKeyPressed(Enter):
      phase = ArenaSetup

proc drawArenaScene*() =
  # Header
  drawRectangle(0, 0, GameWidth, 22, PalNavy)
  drawButton(backButton)

  case phase
  of ArenaSetup:
    drawCenteredTextShadow("BATTLE ARENA", 30, 16, PalGold)
    drawCenteredText("Choose your difficulty:", 60, 8, PalLightGray)
    for i in 0..3:
      var btn = diffButtons[i]
      if Difficulty(i) == difficulty:
        btn.color = PalGreen
        btn.hoverColor = PalLime
      drawButton(btn)
    drawButton(startButton)

    # High scores
    drawPixelText("High Scores:", 30, 115, 8, PalGray)
    if playerDataPtr != nil:
      for i in 0..3:
        let d = Difficulty(i)
        drawPixelText(difficultyName(d) & ": " &
          $playerDataPtr[].arenaHighScores[i], 30, int32(125 + i * 10), 8, PalLightGray)

    drawPixelText("BATTLE ARENA", 50, 7, 8, PalWhite)

  of ArenaMemorize:
    drawPixelText("MEMORIZE", 50, 7, 8, PalWhite)
    let timeStr = "Time: " & formatFloat(memorizeTimer, ffDecimal, 1) & "s"
    drawPixelText(timeStr, 220, 7, 8, PalGold)

    # Show current card large
    let ci = arenaDeck[currentViewCard]
    let card = paoTable[ci].card
    let cardX = int32((GameWidth - CardWidth * 2) div 2)
    let cardY: int32 = 28

    if flipTween.active:
      drawCardFlipping(card, cardX, cardY, flipTween.current, CardWidth * 2, CardHeight * 2)
    else:
      drawCardFace(card, cardX, cardY, CardWidth * 2, CardHeight * 2)

    # PAO hint
    let pao = paoTable[ci]
    drawPixelText(pao.person & " " & pao.action & " " & pao.obj,
      10, 115, 8, PalGold)

    # Progress
    let progress = $(currentViewCard + 1) & " / " & $cardCount
    drawCenteredText(progress, 130, 8, PalLightGray)

    drawButton(prevCardButton)
    drawButton(nextCardButton)
    drawButton(doneMemButton)

  of ArenaRecall:
    drawPixelText("RECALL - Pick in order!", 50, 7, 8, PalWhite)
    drawPixelText($recallSelected.len & "/" & $cardCount, 260, 7, 8, PalGold)

    let cols = min(cardCount, 13)
    let gridW = cols * (CardWidth + 2)
    let startX = (GameWidth - gridW) div 2
    let startY: int32 = 26

    for i in 0..<recallGrid.len:
      let col = i mod cols
      let row = i div cols
      let cx = int32(startX + int32(col) * (CardWidth + 2))
      let cy = int32(startY + int32(row) * (CardHeight + 2))

      if recallGrid[i] in recallSelected:
        # Already picked - dim it
        drawRectangle(cx, cy, CardWidth, CardHeight,
          Color(r: 40, g: 40, b: 50, a: 255))
      else:
        let card = paoTable[recallGrid[i]].card
        drawCardFace(card, cx, cy)

    # Show selected order at bottom
    let selY = int32(GameHeight - 18)
    drawPixelText("Order: ", 4, selY, 8, PalGray)
    for i in 0..<min(recallSelected.len, 10):
      let card = paoTable[recallSelected[i]].card
      let rk = rankChar(card.rank)
      drawPixelText(rk, int32(50 + i * 14), selY, 8, PalWhite)

    drawButton(undoButton)

  of ArenaResults:
    drawPixelText("RESULTS", 50, 7, 8, PalWhite)

    drawCenteredTextShadow("Score: " & $scoreFinal, 40, 16, PalGold)

    let accPct = int(scoreAccuracy * 100)
    drawCenteredText("Accuracy: " & $accPct & "%", 65, 8,
      if scoreAccuracy >= 0.8: PalGreen else: PalRed)

    drawCenteredText("Time: " & formatFloat(memorizeTimer, ffDecimal, 1) & "s",
      80, 8, PalLightGray)

    # Show correct vs wrong
    drawPixelText("Your order vs correct:", 20, 100, 8, PalGray)
    for i in 0..<min(cardCount, 13):
      let correct = i < recallSelected.len and recallSelected[i] == arenaDeck[i]
      let col = if correct: PalGreen else: PalRed
      if i < recallSelected.len:
        let card = paoTable[recallSelected[i]].card
        drawPixelText(rankChar(card.rank), int32(20 + i * 18), 112, 8, col)
      let correctCard = paoTable[arenaDeck[i]].card
      drawPixelText(rankChar(correctCard.rank), int32(20 + i * 18), 124, 8, PalGray)

    drawCenteredText("Click to continue", 150, 8, PalLightGray)
