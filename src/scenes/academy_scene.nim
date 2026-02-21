## Academy Scene: Flashcard + quiz drill for PAO associations

import raylib
import ../types, ../palette, ../ui, ../animation, ../renderer, ../cards,
       ../player

var
  mode: AcademyMode
  currentCardIdx: int
  flipProgress: float32
  flipTween: Tween
  showFace: bool
  quizOptions: array[4, int]  # card indices for quiz
  quizCorrect: int  # which option is correct (0-3)
  quizAnswered: bool
  quizResult: bool
  quizButtons: array[4, PixelButton]
  backButton: PixelButton
  nextButton: PixelButton
  prevButton: PixelButton
  flipButton: PixelButton
  modeButton: PixelButton
  feedbackTimer: float32
  cardList: seq[int]
  cardListPos: int

var changeSceneProc*: proc(s: Scene)
var triggerShakeProc*: proc(intensity: float32, duration: float32)
var gameParticles*: ptr ParticleSystem
var playerDataPtr*: ptr PlayerData

proc generateQuiz() =
  quizAnswered = false
  quizResult = false
  let correctIdx = cardList[cardListPos]
  quizCorrect = getRandomValue(0, 3)

  # Fill with random wrong answers
  var used = @[correctIdx]
  for i in 0..3:
    if i == quizCorrect:
      quizOptions[i] = correctIdx
    else:
      var idx = getRandomValue(0, 51)
      while idx in used:
        idx = getRandomValue(0, 51)
      used.add(idx)
      quizOptions[i] = idx

  # Create quiz buttons
  let btnW: float32 = 140
  let btnH: float32 = 16
  let startX: float32 = (GameWidth.float32 - btnW) / 2
  for i in 0..3:
    let person = paoTable[quizOptions[i]].person
    quizButtons[i] = newPixelButton(startX, 85 + float32(i) * 20, btnW, btnH,
      person, PalBlueDark, PalBlue, PalWhite)

proc initAcademyScene*() =
  mode = AcademyFlashcard
  currentCardIdx = 0
  flipProgress = 0
  flipTween = Tween(active: false)
  showFace = true
  feedbackTimer = 0

  cardList = newDeck()
  shuffleDeck(cardList)
  cardListPos = 0

  let btnY: float32 = GameHeight.float32 - 20
  backButton = newPixelButton(4, 4, 40, 14, "Back", PalRedDark, PalRed, PalWhite)
  prevButton = newPixelButton(60, btnY, 40, 16, "< Prev", PalGrayDark, PalGray, PalWhite)
  nextButton = newPixelButton(220, btnY, 40, 16, "Next >", PalGrayDark, PalGray, PalWhite)
  flipButton = newPixelButton(130, btnY, 60, 16, "Flip", PalBlue, PalSkyBlue, PalWhite)
  modeButton = newPixelButton(230, 4, 86, 14, "Switch Mode", PalPurple, PalMagenta, PalWhite)

  generateQuiz()

proc updateAcademyScene*(dt: float32) =
  feedbackTimer -= dt
  if feedbackTimer < 0: feedbackTimer = 0

  updateTween(flipTween, dt)
  if flipTween.active:
    flipProgress = flipTween.current

  if updateButton(backButton):
    if changeSceneProc != nil:
      changeSceneProc(SceneTitle)
    return

  if updateButton(modeButton):
    if mode == AcademyFlashcard:
      mode = AcademyQuiz
      generateQuiz()
    else:
      mode = AcademyFlashcard
      showFace = true
      flipProgress = 1.0

  case mode
  of AcademyFlashcard:
    if updateButton(flipButton):
      showFace = not showFace
      if showFace:
        flipTween = newTween(0, 1, 0.3, EaseOutQuad)
      else:
        flipTween = newTween(1, 0, 0.3, EaseOutQuad)
      # Record card as studied
      if playerDataPtr != nil and showFace:
        recordCardStudied(playerDataPtr[], cardList[cardListPos])

    if updateButton(prevButton):
      if cardListPos > 0:
        cardListPos -= 1
        showFace = true
        flipProgress = 1.0
        flipTween = Tween(active: false)

    if updateButton(nextButton):
      if cardListPos < cardList.len - 1:
        cardListPos += 1
        showFace = true
        flipProgress = 1.0
        flipTween = Tween(active: false)

    # Keyboard shortcuts
    if isKeyPressed(Left) or isKeyPressed(A):
      if cardListPos > 0:
        cardListPos -= 1
        showFace = true
        flipProgress = 1.0
    if isKeyPressed(Right) or isKeyPressed(D):
      if cardListPos < cardList.len - 1:
        cardListPos += 1
        showFace = true
        flipProgress = 1.0
    if isKeyPressed(Space):
      showFace = not showFace
      if showFace:
        flipTween = newTween(0, 1, 0.3, EaseOutQuad)
      else:
        flipTween = newTween(1, 0, 0.3, EaseOutQuad)

  of AcademyQuiz:
    if not quizAnswered:
      for i in 0..3:
        if updateButton(quizButtons[i]):
          quizAnswered = true
          quizResult = (i == quizCorrect)
          feedbackTimer = 1.5
          let cIdx = cardList[cardListPos]
          if playerDataPtr != nil:
            recordQuizAnswer(playerDataPtr[], cIdx, quizResult)
          if quizResult:
            if gameParticles != nil:
              let px = GameWidth.float32 / 2
              let py = 70.0'f32
              spawnConfetti(gameParticles[], Vector2(x: px, y: py), 15)
          else:
            if triggerShakeProc != nil:
              triggerShakeProc(4.0, 0.3)
    else:
      if feedbackTimer <= 0 or isMouseButtonPressed(Left):
        cardListPos = (cardListPos + 1) mod cardList.len
        generateQuiz()

proc drawAcademyScene*() =
  # Header
  drawRectangle(0, 0, GameWidth, 22, PalNavy)
  let modeStr = if mode == AcademyFlashcard: "Flashcard Mode" else: "Quiz Mode"
  drawPixelText(modeStr, 50, 7, 8, PalWhite)
  drawButton(backButton)
  drawButton(modeButton)

  let ci = cardList[cardListPos]
  let card = paoTable[ci].card

  case mode
  of AcademyFlashcard:
    # Card display
    let cardX = int32((GameWidth - CardWidth * 2) div 2)
    let cardY: int32 = 32

    if flipTween.active:
      drawCardFlipping(card, cardX, cardY, flipProgress,
                       CardWidth * 2, CardHeight * 2)
    elif showFace:
      drawCardFace(card, cardX, cardY, CardWidth * 2, CardHeight * 2)
    else:
      drawCardBack(cardX, cardY, CardWidth * 2, CardHeight * 2)

    # PAO info (shown when face up)
    if showFace and not flipTween.active:
      let pao = paoTable[ci]
      drawPixelText("P: " & pao.person, 10, 120, 8, PalGold)
      drawPixelText("A: " & pao.action, 10, 132, 8, PalCyan)
      drawPixelText("O: " & pao.obj, 10, 144, 8, PalPink)

    # Card counter
    let counterText = $(cardListPos + 1) & " / 52"
    drawCenteredText(counterText, 115, 8, PalLightGray)

    # Mastery bar
    if playerDataPtr != nil:
      let mastery = playerDataPtr[].cardMastery[ci]
      drawPixelText("Mastery:", 200, 120, 8, PalGray)
      drawProgressBar(200, 130, 60, 6, float32(mastery) / 5.0,
                      PalGrayDark, PalGreen)

    drawButton(prevButton)
    drawButton(nextButton)
    drawButton(flipButton)

  of AcademyQuiz:
    # Show card
    let cardX = int32((GameWidth - CardWidth * 2) div 2)
    let cardY: int32 = 28
    drawCardFace(card, cardX, cardY, CardWidth * 2, CardHeight * 2)

    drawCenteredText("Who is this card's Person?", 78, 8, PalLightGray)

    for i in 0..3:
      var btn = quizButtons[i]
      if quizAnswered:
        if i == quizCorrect:
          btn.color = PalGreenDark
          btn.hoverColor = PalGreen
        elif quizOptions[i] != quizOptions[quizCorrect]:
          btn.color = PalRedDark
          btn.hoverColor = PalRed
      drawButton(btn)

    if quizAnswered:
      if quizResult:
        drawCenteredText("Correct!", 170, 8, PalGreen)
      else:
        let rightPerson = paoTable[quizOptions[quizCorrect]].person
        drawCenteredText("Wrong! It's " & rightPerson, 170, 8, PalRed)
