## Player progression: XP, leveling, streak logic

import types

const
  XpPerLevel* = 100
  XpCorrectAnswer* = 10
  XpCardStudied* = 2
  XpArenaComplete* = 25
  XpDailyComplete* = 50
  XpStreakBonus* = 5  # per streak day

proc xpForLevel*(level: int): int =
  level * XpPerLevel

proc addXp*(pd: var PlayerData, amount: int) =
  pd.xp += amount
  while pd.xp >= xpForLevel(pd.level + 1):
    pd.xp -= xpForLevel(pd.level + 1)
    pd.level += 1

proc xpProgress*(pd: PlayerData): float32 =
  let needed = xpForLevel(pd.level + 1)
  if needed == 0: return 1.0
  float32(pd.xp) / float32(needed)

proc updateStreak*(pd: var PlayerData, today: int) =
  if pd.lastPlayDate == today - 1:
    pd.streak += 1
    if pd.streak > pd.bestStreak:
      pd.bestStreak = pd.streak
  elif pd.lastPlayDate != today:
    pd.streak = 1
  pd.lastPlayDate = today

proc recordCardStudied*(pd: var PlayerData, cardIdx: int) =
  pd.totalCardsStudied += 1
  if pd.cardMastery[cardIdx] < 5:
    pd.cardMastery[cardIdx] += 1
  addXp(pd, XpCardStudied)

proc recordQuizAnswer*(pd: var PlayerData, cardIdx: int, correct: bool) =
  pd.totalQuizAttempts += 1
  if correct:
    pd.totalQuizCorrect += 1
    if pd.cardMastery[cardIdx] < 5:
      pd.cardMastery[cardIdx] += 1
    addXp(pd, XpCorrectAnswer)
  else:
    if pd.cardMastery[cardIdx] > 0:
      pd.cardMastery[cardIdx] -= 1

proc masteryPercent*(pd: PlayerData): float32 =
  var total = 0
  for m in pd.cardMastery:
    total += m
  float32(total) / float32(52 * 5) * 100.0
