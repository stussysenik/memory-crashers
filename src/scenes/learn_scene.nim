## Learn Scene: 7-stage progressive learning with Study, Quiz, and Speed Drill phases

import raylib
import std/strutils
import ../types, ../palette, ../design, ../ui, ../animation, ../renderer, ../cards,
       ../player, ../storage, ../hints, ../learn_data, ../tutorial

type
  DrillOption = object
    cardIdx: int
    btn: PixelButton

var
  phase: LearnPhase
  selectedStage: int
  stageCardList: seq[int]

  # Stage select
  stageButtons: array[7, PixelButton]
  backButton: PixelButton

  # Study phase
  studyIdx: int
  studyViewedAll: bool
  studyViewed: seq[bool]
  prevBtn, nextBtn, quizBtn: PixelButton
  flipTween: Tween
  showFace: bool

  # Quiz phase
  quizCardPool: seq[int]
  quizCurrentCard: int
  quizOptions: array[4, PixelButton]
  quizOptionIndices: array[4, int]
  quizCorrectOption: int
  quizAnswered: bool
  quizWasCorrect: bool
  quizFeedbackTimer: float32
  quizScore: int
  quizTotal: int

  # Drill phase
  drillCards: seq[int]
  drillIdx: int
  drillTimer: float32
  drillOptions: array[2, DrillOption]
  drillCorrectOption: int
  drillAnswered: bool
  drillFeedbackTimer: float32

  # Stage complete
  stageStars: int
  completeContinueBtn: PixelButton

var changeSceneProc*: proc(s: Scene)
var triggerShakeProc*: proc(intensity: float32; duration: float32)
var gameParticles*: ptr ParticleSystem
var playerDataPtr*: ptr PlayerData
var gameFloatingTexts*: ptr seq[FloatingText]

# Forward declarations
proc generateQuizQuestion()
proc generateDrillQuestion()

proc initLearnScene*() =
  phase = LearnStageSelect
  selectedStage = 0
  setHintCategory(HintStudy)

  backButton = newPixelButton(4, 4, 40, 14, "Back", PalRedDark, PalRed, PalWhite)

  # Create stage select buttons
  let btnW: float32 = 140
  let btnH: float32 = 14
  let startX = (ScreenW.float32 - btnW) / 2
  for i in 0..6:
    let y = float32(ContentY + 4 + i * 18)
    var col = StageColors[i]
    var hcol = PalWhite
    stageButtons[i] = newPixelButton(startX, y, btnW, btnH,
      StageNames[i], col, hcol, PalBlack)

  # Auto-unlock stages based on existing mastery data
  if playerDataPtr != nil:
    for i in 0..6:
      if checkStageUnlock(i, playerDataPtr[].cardMastery, playerDataPtr[].stageProgress):
        playerDataPtr[].stageProgress[i].unlocked = true

proc startStudy() =
  phase = LearnStudy
  setHintCategory(HintStudy)
  stageCardList = stageCards(selectedStage)
  tutorialRefCards = stageCardList
  studyIdx = 0
  showFace = true
  flipTween = Tween(active: false)
  studyViewedAll = false
  studyViewed = newSeq[bool](stageCardList.len)
  studyViewed[0] = true

  let btnY = float32(ContentY + ContentH - 18)
  prevBtn = newPixelButton(float32(ContentMargin + 4), btnY, 50, 16,
    "< Prev", PalGrayDark, PalGray, PalWhite)
  nextBtn = newPixelButton(float32(ScreenW - ContentMargin - 54), btnY, 50, 16,
    "Next >", PalGrayDark, PalGray, PalWhite)
  quizBtn = newPixelButton((ScreenW.float32 - 70) / 2, btnY, 70, 16,
    "Start Quiz", PalGreen, PalLime, PalBlack)

proc startQuiz() =
  phase = LearnQuiz
  setHintCategory(HintQuiz)
  tutorialRefCards = stageCardList
  quizScore = 0
  quizTotal = 0
  generateQuizQuestion()

proc startDrill() =
  phase = LearnDrill
  setHintCategory(HintSpeed)
  drillCards = stageCards(selectedStage)
  tutorialRefCards = drillCards
  # Shuffle drill order
  for i in countdown(drillCards.len - 1, 1):
    let j = getRandomValue(0, int32(i))
    swap(drillCards[i], drillCards[j])
  drillIdx = 0
  drillTimer = 0
  generateDrillQuestion()

proc generateQuizQuestion() =
  quizAnswered = false
  quizWasCorrect = false
  quizFeedbackTimer = 0

  # Pick card from weighted pool
  if playerDataPtr != nil:
    quizCardPool = buildWeightedPool(stageCardList, playerDataPtr[].cardMastery)
  else:
    quizCardPool = stageCardList

  quizCurrentCard = quizCardPool[getRandomValue(0, int32(quizCardPool.len - 1))]

  # Pick correct position
  quizCorrectOption = getRandomValue(0, 3)

  # Fill options
  var used = @[quizCurrentCard]
  for i in 0..3:
    if i == quizCorrectOption:
      quizOptionIndices[i] = quizCurrentCard
    else:
      var idx = getRandomValue(0, 51)
      while idx in used:
        idx = getRandomValue(0, 51)
      used.add(idx)
      quizOptionIndices[i] = idx

  # Create option buttons
  let btnW: float32 = 140
  let btnH: float32 = 16
  let startX = (ScreenW.float32 - btnW) / 2
  for i in 0..3:
    let person = paoTable[quizOptionIndices[i]].person
    quizOptions[i] = newPixelButton(startX, float32(ContentY + 64 + i * 20),
      btnW, btnH, person, PalBlueDark, PalBlue, PalWhite)

proc generateDrillQuestion() =
  drillAnswered = false
  drillFeedbackTimer = 0

  if drillIdx >= drillCards.len:
    return  # drill finished

  let correctCard = drillCards[drillIdx]
  drillCorrectOption = getRandomValue(0, 1)

  let btnW: float32 = 130
  let btnH: float32 = 20
  let gap: float32 = 12
  let totalW = btnW * 2 + gap
  let startX = (ScreenW.float32 - totalW) / 2
  let btnY = float32(ContentY + 90)

  for i in 0..1:
    let bx = startX + float32(i) * (btnW + gap)
    if i == drillCorrectOption:
      drillOptions[i] = DrillOption(
        cardIdx: correctCard,
        btn: newPixelButton(bx, btnY, btnW, btnH,
          paoTable[correctCard].person, PalBlueDark, PalBlue, PalWhite)
      )
    else:
      var wrongIdx = getRandomValue(0, 51)
      while wrongIdx == correctCard:
        wrongIdx = getRandomValue(0, 51)
      drillOptions[i] = DrillOption(
        cardIdx: wrongIdx,
        btn: newPixelButton(bx, btnY, btnW, btnH,
          paoTable[wrongIdx].person, PalBlueDark, PalBlue, PalWhite)
      )

proc updateLearnScene*(dt: float32) =
  updateHints(dt)
  updateTween(flipTween, dt)

  if updateButton(backButton):
    case phase
    of LearnStageSelect:
      if changeSceneProc != nil:
        changeSceneProc(SceneHome)
    of LearnStudy, LearnQuiz, LearnDrill:
      phase = LearnStageSelect
    of LearnStageComplete:
      phase = LearnStageSelect
    return

  case phase
  of LearnStageSelect:
    for i in 0..6:
      if playerDataPtr != nil and playerDataPtr[].stageProgress[i].unlocked:
        if updateButton(stageButtons[i]):
          selectedStage = i
          stageCardList = stageCards(i)
          startStudy()

  of LearnStudy:
    if updateButton(prevBtn):
      if studyIdx > 0:
        studyIdx -= 1
        showFace = true
        flipTween = Tween(active: false)

    if updateButton(nextBtn):
      if studyIdx < stageCardList.len - 1:
        studyIdx += 1
        showFace = true
        flipTween = Tween(active: false)
        studyViewed[studyIdx] = true

    # Check if all viewed
    studyViewedAll = true
    for v in studyViewed:
      if not v: studyViewedAll = false

    if studyViewedAll:
      if updateButton(quizBtn):
        if playerDataPtr != nil:
          playerDataPtr[].stageProgress[selectedStage].cardsStudied = stageCardList.len
        startQuiz()

    # Keyboard
    if isKeyPressed(Left) and studyIdx > 0:
      studyIdx -= 1
      showFace = true
      flipTween = Tween(active: false)
    if isKeyPressed(Right) and studyIdx < stageCardList.len - 1:
      studyIdx += 1
      showFace = true
      flipTween = Tween(active: false)
      studyViewed[studyIdx] = true

  of LearnQuiz:
    if not quizAnswered:
      for i in 0..3:
        if updateButton(quizOptions[i]):
          quizAnswered = true
          quizTotal += 1
          quizWasCorrect = (i == quizCorrectOption)

          if quizWasCorrect:
            quizScore += 1
            quizFeedbackTimer = 1.0
            if playerDataPtr != nil:
              discard recordQuizAnswer(playerDataPtr[], quizCurrentCard, true)
            if gameParticles != nil:
              spawnConfetti(gameParticles[], Vector2(x: 160, y: 70), 12)
            if gameFloatingTexts != nil:
              spawnFloatingText(gameFloatingTexts[], "+10 XP", 160, 70, PalGold)
          else:
            quizFeedbackTimer = 2.5  # Longer for elaborated feedback
            if playerDataPtr != nil:
              discard recordQuizAnswer(playerDataPtr[], quizCurrentCard, false)
            if triggerShakeProc != nil:
              triggerShakeProc(3.0, 0.2)
    else:
      quizFeedbackTimer -= dt
      if quizFeedbackTimer <= 0 or
         (quizWasCorrect and isMouseButtonPressed(Left)):
        # Check if quiz is complete (10 questions or 80% threshold met)
        if quizTotal >= 10:
          if playerDataPtr != nil:
            playerDataPtr[].stageProgress[selectedStage].quizScore = quizScore
            playerDataPtr[].stageProgress[selectedStage].quizTotal = quizTotal
          if quizTotal > 0 and float32(quizScore) / float32(quizTotal) >= 0.8:
            startDrill()
          else:
            # Reset quiz for another round
            quizScore = 0
            quizTotal = 0
            generateQuizQuestion()
        else:
          generateQuizQuestion()

  of LearnDrill:
    if drillIdx >= drillCards.len:
      # Drill complete
      if playerDataPtr != nil:
        discard recordDrillComplete(playerDataPtr[], selectedStage, drillTimer)
        discard completeStage(playerDataPtr[], selectedStage)
        if gameFloatingTexts != nil:
          spawnFloatingText(gameFloatingTexts[], "+40 XP", 160, 50, PalGold)
        # Unlock next stages
        for i in 0..6:
          if checkStageUnlock(i, playerDataPtr[].cardMastery, playerDataPtr[].stageProgress):
            playerDataPtr[].stageProgress[i].unlocked = true
        savePlayerData(playerDataPtr[])

      # Calculate stars
      let secsPerCard = drillTimer / float32(drillCards.len)
      if secsPerCard < 2.0: stageStars = 3
      elif secsPerCard < 4.0: stageStars = 2
      else: stageStars = 1

      phase = LearnStageComplete
      completeContinueBtn = newPixelButton(
        (ScreenW.float32 - 100) / 2, float32(ContentY + ContentH - 24),
        100, 20, "Continue", ColBtnPrimary, PalLime, PalBlack)
      return

    if not drillAnswered:
      drillTimer += dt
      for i in 0..1:
        if updateButton(drillOptions[i].btn):
          drillAnswered = true
          if i == drillCorrectOption:
            drillFeedbackTimer = 0.4
          else:
            drillFeedbackTimer = 0.6
            if triggerShakeProc != nil:
              triggerShakeProc(2.0, 0.15)
    else:
      drillFeedbackTimer -= dt
      if drillFeedbackTimer <= 0:
        drillIdx += 1
        if drillIdx < drillCards.len:
          generateDrillQuestion()

  of LearnStageComplete:
    if updateButton(completeContinueBtn):
      phase = LearnStageSelect

proc drawLearnScene*() =
  # Header
  drawHeader("LEARN")
  drawButton(backButton)

  case phase
  of LearnStageSelect:
    drawCenteredText("Choose a Stage", int32(ContentY - 2), FontSmall, ColTextAccent)

    for i in 0..6:
      var btn = stageButtons[i]
      let unlocked = playerDataPtr != nil and playerDataPtr[].stageProgress[i].unlocked
      let completed = playerDataPtr != nil and playerDataPtr[].stageProgress[i].completed

      if not unlocked:
        btn.color = PalGrayDark
        btn.hoverColor = PalGrayDark
        btn.textColor = PalGray
        btn.label = StageNames[i] & " [locked]"

      if completed:
        btn.label = StageNames[i] & " [done]"

      drawButton(btn)

      # Draw card count label to the right
      let countText = $stageCardCount(i) & " cards"
      drawPixelText(countText, int32(btn.rect.x + btn.rect.width + 6),
        int32(btn.rect.y + 3), FontTiny, PalGray)

  of LearnStudy:
    let ci = stageCardList[studyIdx]
    let card = paoTable[ci].card
    let pao = paoTable[ci]

    # Draw card large
    let cardX = int32((ScreenW - CardLGW) div 2)
    let cardY = int32(ContentY + 4)

    if flipTween.active:
      drawCardFlipping(card, cardX, cardY, flipTween.current, CardLGW, CardLGH)
    else:
      drawCardFace(card, cardX, cardY, CardLGW, CardLGH)

    # PAO info to the right of card
    let infoX = int32(cardX + CardLGW + 12)
    let infoY = int32(ContentY + 8)
    drawPixelText("P: " & pao.person, infoX, infoY, FontTiny, PalGold)
    drawPixelText("A: " & pao.action, infoX, infoY + 12, FontTiny, PalCyan)
    drawPixelText("O: " & pao.obj, infoX, infoY + 24, FontTiny, PalPink)

    # Also show suit theme hint
    drawPixelText(suitThemeHint(card.suit), int32(ContentMargin),
      int32(ContentY + 74), FontTiny, PalGray)

    # Card counter
    let counterText = $(studyIdx + 1) & " / " & $stageCardList.len
    drawCenteredText(counterText, int32(ContentY + 88), FontTiny, ColTextSecondary)

    # Mastery dots
    if playerDataPtr != nil:
      let mastery = playerDataPtr[].cardMastery[ci]
      drawPixelText("Mastery:", int32(ContentMargin), int32(ContentY + 100), FontTiny, PalGray)
      drawMasteryDots(int32(ContentMargin + 52), int32(ContentY + 100), mastery)

    # Progress indicator
    let viewedCount = block:
      var c = 0
      for v in studyViewed:
        if v: c += 1
      c
    drawPixelText("Viewed: " & $viewedCount & "/" & $stageCardList.len,
      int32(ContentMargin), int32(ContentY + 112), FontTiny,
      if studyViewedAll: PalGreen else: PalGray)

    drawButton(prevBtn)
    drawButton(nextBtn)
    if studyViewedAll:
      drawButton(quizBtn)

  of LearnQuiz:
    # Show card
    let ci = quizCurrentCard
    let card = paoTable[ci].card

    let cardX = int32((ScreenW - CardMDW * 2) div 2)
    let cardY = int32(ContentY + 2)
    drawCardFace(card, cardX, cardY, CardMDW * 2, CardMDH * 2)

    drawCenteredText("Who is this card's Person?", int32(ContentY + 54),
      FontTiny, ColTextSecondary)

    # Score display
    drawPixelText("Score: " & $quizScore & "/" & $quizTotal,
      int32(ScreenW - ContentMargin - 70), int32(ContentY + 2), FontTiny, PalGold)

    # Quiz options
    for i in 0..3:
      var btn = quizOptions[i]
      if quizAnswered:
        if i == quizCorrectOption:
          btn.color = PalGreenDark
          btn.hoverColor = PalGreen
        elif quizOptionIndices[i] == quizOptionIndices[quizCorrectOption]:
          discard
        else:
          btn.color = PalGrayDark
          btn.hoverColor = PalGrayDark
      drawButton(btn)

    # Feedback
    if quizAnswered:
      if quizWasCorrect:
        drawCenteredText("Correct!", int32(ContentY + ContentH - 18),
          FontTiny, ColCorrect)
      else:
        # Elaborated feedback
        let correctPao = paoTable[quizCurrentCard]
        let feedY = int32(ContentY + ContentH - 36)
        drawCenteredText("Wrong! It's " & correctPao.person, feedY, FontTiny, ColWrong)
        let paoStr = correctPao.person & " " & correctPao.action & " " & correctPao.obj
        drawCenteredText(paoStr, feedY + 10, FontTiny, PalGold)
        drawCenteredText(suitThemeHint(correctPao.card.suit), feedY + 20,
          FontTiny, PalGray)

  of LearnDrill:
    if drillIdx < drillCards.len:
      let ci = drillCards[drillIdx]
      let card = paoTable[ci].card

      drawCenteredText("SPEED DRILL", int32(ContentY + 2), FontSmall, PalGold)

      # Timer
      let timeStr = formatFloat(drillTimer, ffDecimal, 1) & "s"
      drawPixelText(timeStr, int32(ScreenW - ContentMargin - 40),
        int32(ContentY + 4), FontTiny, PalGold)

      # Card
      let cardX = int32((ScreenW - CardMDW * 2) div 2)
      let cardY = int32(ContentY + 18)
      drawCardFace(card, cardX, cardY, CardMDW * 2, CardMDH * 2)

      # Progress
      drawCenteredText($(drillIdx + 1) & " / " & $drillCards.len,
        int32(ContentY + 78), FontTiny, ColTextSecondary)

      # Options
      for i in 0..1:
        var btn = drillOptions[i].btn
        if drillAnswered:
          if i == drillCorrectOption:
            btn.color = PalGreenDark
            btn.hoverColor = PalGreen
          else:
            btn.color = PalRedDark
            btn.hoverColor = PalRed
        drawButton(btn)

  of LearnStageComplete:
    drawCenteredTextShadow("STAGE COMPLETE!", int32(ContentY + 10), FontMedium, PalGold)
    drawCenteredText(StageNames[selectedStage], int32(ContentY + 30), FontSmall, ColTextSecondary)

    # Stars
    let starY = int32(ContentY + 48)
    let starSize: int32 = 12
    let totalStarW = starSize * 3 + SpaceSM * 2
    let starStartX = int32((ScreenW - totalStarW) div 2)
    for i in 0..2:
      let sx = starStartX + int32(i) * (starSize + SpaceSM)
      let col = if i < stageStars: PalGold else: PalGrayDark
      drawRectangle(sx, starY, starSize, starSize, col)
      drawRectangleLines(Rectangle(x: sx.float32, y: starY.float32,
        width: starSize.float32, height: starSize.float32), 1.0, PalBlack)

    # Speed tier
    if drillCards.len > 0:
      let secsPerCard = drillTimer / float32(drillCards.len)
      let tier = tierForTime(secsPerCard)
      drawCenteredText("Time: " & formatFloat(drillTimer, ffDecimal, 1) & "s (" &
        formatFloat(secsPerCard, ffDecimal, 1) & "s/card)", int32(ContentY + 68),
        FontTiny, ColTextSecondary)
      drawCenteredText(tierName(tier), int32(ContentY + 80), FontTiny, PalGold)

    drawButton(completeContinueBtn)

  # Hint bar on all phases
  drawHintBar()
