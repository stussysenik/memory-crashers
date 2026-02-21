## Persistence: localStorage (web) / file (native)

import types
import std/json
import std/strutils
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
  var mastery = newJArray()
  for m in pd.cardMastery:
    mastery.add(%m)
  j["cardMastery"] = mastery
  var scores = newJArray()
  for s in pd.arenaHighScores:
    scores.add(%s)
  j["arenaHighScores"] = scores
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
    if j.hasKey("cardMastery"):
      for i, m in j["cardMastery"].getElems():
        if i < 52:
          result.cardMastery[i] = m.getInt()
    if j.hasKey("arenaHighScores"):
      for i, s in j["arenaHighScores"].getElems():
        if i < 4:
          result.arenaHighScores[i] = s.getInt()
  except:
    result = PlayerData()

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
    return PlayerData()
  else:
    try:
      let data = readFile("save.json")
      return jsonToPlayer(data)
    except:
      return PlayerData()

proc getDayNumber*(): int =
  when defined(emscripten):
    int(emscripten_run_script_int("Math.floor(Date.now()/86400000)".cstring))
  else:
    int(epochTime() / 86400.0)
