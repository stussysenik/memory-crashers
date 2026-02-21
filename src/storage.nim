## Persistence: localStorage (web) / file (native)

import types
import std/json
import std/times

when defined(emscripten):
  proc emscripten_run_script(script: cstring) {.cdecl, importc, header: "<emscripten.h>".}
  proc emscripten_run_script_int(script: cstring): cint {.cdecl, importc, header: "<emscripten.h>".}
  proc emscripten_run_script_string(script: cstring): cstring {.cdecl, importc, header: "<emscripten.h>".}

proc playerToJson(pd: PlayerData): string =
  var j = newJObject()
  j["xp"] = %pd.xp
  j["level"] = %pd.level
  j["streak"] = %pd.streak
  j["bestStreak"] = %pd.bestStreak
  j["lastPlayDate"] = %pd.lastPlayDate
  j["dailyCompleted"] = %pd.dailyCompleted
  j["totalCardsStudied"] = %pd.totalCardsStudied
  j["totalQuizCorrect"] = %pd.totalQuizCorrect
  j["totalQuizAttempts"] = %pd.totalQuizAttempts
  j["currentStage"] = %pd.currentStage
  j["totalDrillsCompleted"] = %pd.totalDrillsCompleted
  j["speedBestTime"] = %pd.speedBestTime
  j["speedBestMemorizeTime"] = %pd.speedBestMemorizeTime
  j["speedBestAccuracy"] = %pd.speedBestAccuracy
  j["speedAttempts"] = %pd.speedAttempts

  var mdBestTimes = newJArray()
  for t in pd.multiDeckBestTimes:
    mdBestTimes.add(%t)
  j["multiDeckBestTimes"] = mdBestTimes

  var mdBestAcc = newJArray()
  for a in pd.multiDeckBestAccuracy:
    mdBestAcc.add(%a)
  j["multiDeckBestAccuracy"] = mdBestAcc

  var mastery = newJArray()
  for m in pd.cardMastery:
    mastery.add(%m)
  j["cardMastery"] = mastery

  var scores = newJArray()
  for s in pd.arenaHighScores:
    scores.add(%s)
  j["arenaHighScores"] = scores

  # Stage progress
  var stages = newJArray()
  for sp in pd.stageProgress:
    var s = newJObject()
    s["unlocked"] = %sp.unlocked
    s["completed"] = %sp.completed
    s["cardsStudied"] = %sp.cardsStudied
    s["quizScore"] = %sp.quizScore
    s["quizTotal"] = %sp.quizTotal
    s["drillBestTime"] = %sp.drillBestTime
    stages.add(s)
  j["stageProgress"] = stages

  # Practice bests
  var bestTimes = newJArray()
  for t in pd.practiceBestTimes:
    bestTimes.add(%t)
  j["practiceBestTimes"] = bestTimes

  var bestAcc = newJArray()
  for a in pd.practiceBestAccuracy:
    bestAcc.add(%a)
  j["practiceBestAccuracy"] = bestAcc

  return $j

proc jsonToPlayer(s: string): PlayerData =
  try:
    let j = parseJson(s)
    result.xp = j["xp"].getInt()
    result.level = j["level"].getInt()
    result.streak = j["streak"].getInt()
    result.bestStreak = j["bestStreak"].getInt()
    result.lastPlayDate = j["lastPlayDate"].getInt()
    result.dailyCompleted = j["dailyCompleted"].getBool()
    result.totalCardsStudied = j["totalCardsStudied"].getInt()
    result.totalQuizCorrect = j["totalQuizCorrect"].getInt()
    result.totalQuizAttempts = j["totalQuizAttempts"].getInt()

    if j.hasKey("currentStage"):
      result.currentStage = j["currentStage"].getInt()
    if j.hasKey("totalDrillsCompleted"):
      result.totalDrillsCompleted = j["totalDrillsCompleted"].getInt()

    if j.hasKey("speedBestTime"):
      result.speedBestTime = j["speedBestTime"].getFloat().float32
    if j.hasKey("speedBestMemorizeTime"):
      result.speedBestMemorizeTime = j["speedBestMemorizeTime"].getFloat().float32
    if j.hasKey("speedBestAccuracy"):
      result.speedBestAccuracy = j["speedBestAccuracy"].getFloat().float32
    if j.hasKey("speedAttempts"):
      result.speedAttempts = j["speedAttempts"].getInt()

    if j.hasKey("multiDeckBestTimes"):
      for i, t in j["multiDeckBestTimes"].getElems():
        if i < 5:
          result.multiDeckBestTimes[i] = t.getFloat().float32
    if j.hasKey("multiDeckBestAccuracy"):
      for i, a in j["multiDeckBestAccuracy"].getElems():
        if i < 5:
          result.multiDeckBestAccuracy[i] = a.getFloat().float32

    if j.hasKey("cardMastery"):
      for i, m in j["cardMastery"].getElems():
        if i < 52:
          result.cardMastery[i] = m.getInt()
    if j.hasKey("arenaHighScores"):
      for i, s in j["arenaHighScores"].getElems():
        if i < 4:
          result.arenaHighScores[i] = s.getInt()

    # Stage progress (backward compat: fill defaults if missing)
    if j.hasKey("stageProgress"):
      for i, sp in j["stageProgress"].getElems():
        if i < 7:
          result.stageProgress[i].unlocked = sp["unlocked"].getBool()
          result.stageProgress[i].completed = sp["completed"].getBool()
          result.stageProgress[i].cardsStudied = sp["cardsStudied"].getInt()
          result.stageProgress[i].quizScore = sp["quizScore"].getInt()
          result.stageProgress[i].quizTotal = sp["quizTotal"].getInt()
          result.stageProgress[i].drillBestTime = sp["drillBestTime"].getFloat().float32
    else:
      # First load: stage 1 always unlocked
      result.stageProgress[0].unlocked = true

    # Practice bests
    if j.hasKey("practiceBestTimes"):
      for i, t in j["practiceBestTimes"].getElems():
        if i < 4:
          result.practiceBestTimes[i] = t.getFloat().float32
    if j.hasKey("practiceBestAccuracy"):
      for i, a in j["practiceBestAccuracy"].getElems():
        if i < 4:
          result.practiceBestAccuracy[i] = a.getFloat().float32

  except:
    result = PlayerData()
    result.stageProgress[0].unlocked = true

proc savePlayerData*(pd: PlayerData) =
  let data = playerToJson(pd)
  when defined(emscripten):
    let escaped = data.replace("\\", "\\\\").replace("'", "\\'")
    let script = "localStorage.setItem('memory_crashers_save', '" & escaped & "')"
    emscripten_run_script(script.cstring)
  else:
    try:
      writeFile("save.json", data)
    except:
      discard

proc loadPlayerData*(): PlayerData =
  when defined(emscripten):
    let raw = emscripten_run_script_string(
      "localStorage.getItem('memory_crashers_save') || ''".cstring)
    let s = $raw
    if s.len > 0:
      return jsonToPlayer(s)
    result = PlayerData()
    result.stageProgress[0].unlocked = true
  else:
    try:
      let data = readFile("save.json")
      return jsonToPlayer(data)
    except:
      result = PlayerData()
      result.stageProgress[0].unlocked = true

proc getDayNumber*(): int =
  when defined(emscripten):
    int(emscripten_run_script_int("Math.floor(Date.now()/86400000)".cstring))
  else:
    int(epochTime() / 86400.0)
