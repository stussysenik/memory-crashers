## Player progression: XP, leveling, streak logic, stage completion

import types

const
  XpPerLevel* = 100
  XpCorrectAnswer* = 10
  XpCardStudied* = 2
  XpArenaComplete* = 25
  XpDailyComplete* = 50
  XpStreakBonus* = 5  # per streak day
  XpDrillComplete* = 15
  XpStageComplete* = 40
  XpSpeedComplete* = 75

proc xpForLevel*(level: int): int =
  level * XpPerLevel

proc addXp*(pd: var PlayerData; amount: int): bool =
  ## Add XP and return true if leveled up
  let oldLevel = pd.level
  pd.xp += amount
  while pd.xp >= xpForLevel(pd.level + 1):
    pd.xp -= xpForLevel(pd.level + 1)
    pd.level += 1
  result = pd.level > oldLevel

proc xpProgress*(pd: PlayerData): float32 =
  let needed = xpForLevel(pd.level + 1)
  if needed == 0: return 1.0
  float32(pd.xp) / float32(needed)

proc updateStreak*(pd: var PlayerData; today: int) =
  if pd.lastPlayDate == today - 1:
    pd.streak += 1
    if pd.streak > pd.bestStreak:
      pd.bestStreak = pd.streak
  elif pd.lastPlayDate != today:
    pd.streak = 1
  pd.lastPlayDate = today

proc recordCardStudied*(pd: var PlayerData; cardIdx: int): bool =
  pd.totalCardsStudied += 1
  if pd.cardMastery[cardIdx] < 5:
    pd.cardMastery[cardIdx] += 1
  result = addXp(pd, XpCardStudied)

proc recordQuizAnswer*(pd: var PlayerData; cardIdx: int; correct: bool): bool =
  pd.totalQuizAttempts += 1
  if correct:
    pd.totalQuizCorrect += 1
    if pd.cardMastery[cardIdx] < 5:
      pd.cardMastery[cardIdx] += 1
    result = addXp(pd, XpCorrectAnswer)
  else:
    if pd.cardMastery[cardIdx] > 0:
      pd.cardMastery[cardIdx] -= 1

proc masteryPercent*(pd: PlayerData): float32 =
  var total = 0
  for m in pd.cardMastery:
    total += m
  float32(total) / float32(52 * 5) * 100.0

proc stageProgressPercent*(pd: PlayerData; stage: int): float32 =
  ## Returns 0.0-1.0 progress within a stage
  let sp = pd.stageProgress[stage]
  if sp.completed: return 1.0
  if not sp.unlocked: return 0.0
  # Weight: study=30%, quiz=40%, drill=30%
  var progress: float32 = 0.0
  # Study completion contributes 30%
  let studyCount = sp.cardsStudied
  if studyCount > 0: progress += 0.3
  # Quiz accuracy contributes 40%
  if sp.quizTotal > 0:
    let acc = float32(sp.quizScore) / float32(sp.quizTotal)
    if acc >= 0.8: progress += 0.4
    else: progress += 0.4 * acc
  # Drill completion contributes 30%
  if sp.drillBestTime > 0: progress += 0.3
  progress

proc overallStageProgress*(pd: PlayerData): float32 =
  ## Returns 0.0-1.0 total progress across all 7 stages
  var total: float32 = 0.0
  for i in 0..6:
    total += stageProgressPercent(pd, i)
  total / 7.0

proc currentStageDisplay*(pd: PlayerData): string =
  ## Human-readable current stage indicator
  let stage = pd.currentStage
  if stage >= 7: return "All stages complete!"
  $(stage + 1) & "/7"

proc recordDrillComplete*(pd: var PlayerData; stage: int; time: float32): bool =
  pd.totalDrillsCompleted += 1
  if pd.stageProgress[stage].drillBestTime <= 0 or
     time < pd.stageProgress[stage].drillBestTime:
    pd.stageProgress[stage].drillBestTime = time
  result = addXp(pd, XpDrillComplete)

proc completeStage*(pd: var PlayerData; stage: int): bool =
  pd.stageProgress[stage].completed = true
  if stage == pd.currentStage and pd.currentStage < 6:
    pd.currentStage += 1
  result = addXp(pd, XpStageComplete)

proc recordPracticeResult*(pd: var PlayerData; cardCount: int;
                           time: float32; accuracy: float32): bool =
  let idx = practiceCountIndex(cardCount)
  if pd.practiceBestTimes[idx] <= 0 or time < pd.practiceBestTimes[idx]:
    pd.practiceBestTimes[idx] = time
  if accuracy > pd.practiceBestAccuracy[idx]:
    pd.practiceBestAccuracy[idx] = accuracy
  result = addXp(pd, XpArenaComplete)

proc recordMultiDeckResult*(pd: var PlayerData; deckCount: int;
                            time, accuracy: float32): bool =
  ## Record best time/accuracy for multi-deck (1-5 decks). Returns true if leveled up.
  let idx = deckCount - 1  # 0-indexed
  if idx >= 0 and idx < 5:
    if pd.multiDeckBestTimes[idx] <= 0 or time < pd.multiDeckBestTimes[idx]:
      pd.multiDeckBestTimes[idx] = time
    if accuracy > pd.multiDeckBestAccuracy[idx]:
      pd.multiDeckBestAccuracy[idx] = accuracy
  result = addXp(pd, XpArenaComplete)

proc recordSpeedResult*(pd: var PlayerData; totalTime, memorizeTime: float32;
                        accuracy: float32): bool =
  pd.speedAttempts += 1
  if pd.speedBestTime <= 0 or totalTime < pd.speedBestTime:
    pd.speedBestTime = totalTime
  if pd.speedBestMemorizeTime <= 0 or memorizeTime < pd.speedBestMemorizeTime:
    pd.speedBestMemorizeTime = memorizeTime
  if accuracy > pd.speedBestAccuracy:
    pd.speedBestAccuracy = accuracy
  result = addXp(pd, XpSpeedComplete)
