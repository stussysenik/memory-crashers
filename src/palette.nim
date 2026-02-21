## 32-color palette inspired by PICO-8 and NES
## Castle Crashers-style vibrant colors

import raylib

const
  Pal* = [
    # Row 0: Darks and basics
    Color(r: 0, g: 0, b: 0, a: 255),         # 0  Black
    Color(r: 29, g: 24, b: 51, a: 255),       # 1  Dark Navy
    Color(r: 54, g: 42, b: 80, a: 255),       # 2  Purple Dark
    Color(r: 99, g: 59, b: 99, a: 255),       # 3  Plum
    Color(r: 143, g: 77, b: 87, a: 255),      # 4  Mauve
    Color(r: 190, g: 100, b: 80, a: 255),     # 5  Rust
    Color(r: 224, g: 139, b: 75, a: 255),      # 6  Orange
    Color(r: 247, g: 190, b: 84, a: 255),     # 7  Gold

    # Row 1: Greens and teals
    Color(r: 39, g: 70, b: 45, a: 255),       # 8  Forest
    Color(r: 56, g: 105, b: 57, a: 255),      # 9  Green Dark
    Color(r: 78, g: 150, b: 68, a: 255),      # 10 Green
    Color(r: 126, g: 196, b: 89, a: 255),     # 11 Lime
    Color(r: 178, g: 224, b: 122, a: 255),    # 12 Light Green
    Color(r: 41, g: 84, b: 110, a: 255),      # 13 Teal Dark
    Color(r: 50, g: 120, b: 152, a: 255),     # 14 Teal
    Color(r: 79, g: 170, b: 196, a: 255),     # 15 Cyan

    # Row 2: Blues and purples
    Color(r: 27, g: 38, b: 76, a: 255),       # 16 Navy
    Color(r: 39, g: 62, b: 122, a: 255),      # 17 Blue Dark
    Color(r: 55, g: 100, b: 176, a: 255),     # 18 Blue
    Color(r: 88, g: 148, b: 220, a: 255),     # 19 Sky Blue
    Color(r: 148, g: 196, b: 235, a: 255),    # 20 Light Blue
    Color(r: 120, g: 68, b: 164, a: 255),     # 21 Purple
    Color(r: 172, g: 95, b: 196, a: 255),     # 22 Magenta
    Color(r: 215, g: 142, b: 218, a: 255),    # 23 Pink

    # Row 3: Reds, whites, grays
    Color(r: 156, g: 36, b: 51, a: 255),      # 24 Red Dark
    Color(r: 212, g: 53, b: 61, a: 255),      # 25 Red
    Color(r: 245, g: 100, b: 90, a: 255),     # 26 Coral
    Color(r: 252, g: 163, b: 132, a: 255),    # 27 Peach
    Color(r: 75, g: 78, b: 88, a: 255),       # 28 Gray Dark
    Color(r: 128, g: 131, b: 140, a: 255),    # 29 Gray
    Color(r: 195, g: 197, b: 203, a: 255),    # 30 Light Gray
    Color(r: 239, g: 241, b: 245, a: 255),    # 31 White
  ]

  # Semantic aliases
  PalBlack* = Pal[0]
  PalNavy* = Pal[1]
  PalPurpleDark* = Pal[2]
  PalPlum* = Pal[3]
  PalMauve* = Pal[4]
  PalRust* = Pal[5]
  PalOrange* = Pal[6]
  PalGold* = Pal[7]
  PalForest* = Pal[8]
  PalGreenDark* = Pal[9]
  PalGreen* = Pal[10]
  PalLime* = Pal[11]
  PalLightGreen* = Pal[12]
  PalTealDark* = Pal[13]
  PalTeal* = Pal[14]
  PalCyan* = Pal[15]
  PalNavyBlue* = Pal[16]
  PalBlueDark* = Pal[17]
  PalBlue* = Pal[18]
  PalSkyBlue* = Pal[19]
  PalLightBlue* = Pal[20]
  PalPurple* = Pal[21]
  PalMagenta* = Pal[22]
  PalPink* = Pal[23]
  PalRedDark* = Pal[24]
  PalRed* = Pal[25]
  PalCoral* = Pal[26]
  PalPeach* = Pal[27]
  PalGrayDark* = Pal[28]
  PalGray* = Pal[29]
  PalLightGray* = Pal[30]
  PalWhite* = Pal[31]

  # Card-specific colors
  PalCardRed* = Pal[25]
  PalCardBlack* = Pal[0]
  PalCardBack* = Pal[17]
  PalCardFace* = Pal[31]
  PalCardBorder* = Pal[1]

  # UI colors
  PalBgDark* = Pal[1]
  PalBgMid* = Pal[2]
  PalAccent* = Pal[7]
  PalSuccess* = Pal[10]
  PalError* = Pal[25]
  PalTextLight* = Pal[31]
  PalTextDark* = Pal[0]

  # Semantic color tokens for design system
  ColBgPrimary* = Pal[1]     # Navy
  ColBgSecondary* = Pal[2]   # Purple Dark
  ColTextPrimary* = Pal[31]  # White
  ColTextSecondary* = Pal[30] # Light Gray
  ColTextAccent* = Pal[7]    # Gold

  ColBtnPrimary* = Pal[10]   # Green
  ColBtnSecondary* = Pal[18] # Blue
  ColBtnDanger* = Pal[25]    # Red

  ColCorrect* = Pal[10]      # Green
  ColWrong* = Pal[25]        # Red
  ColHint* = Pal[15]         # Cyan

  ColSpeedGold* = Pal[7]   # Gold accent for Speed Cards mode

  # Stage colors (one per learning stage)
  ColStage1* = Pal[7]        # Gold (face cards)
  ColStage2* = Pal[25]       # Red (hearts)
  ColStage3* = Pal[19]       # Sky Blue (diamonds)
  ColStage4* = Pal[10]       # Green (clubs)
  ColStage5* = Pal[28]       # Gray Dark (spades)
  ColStage6* = Pal[22]       # Magenta (half deck)
  ColStage7* = Pal[6]        # Orange (full deck)

  StageColors*: array[7, Color] = [
    ColStage1, ColStage2, ColStage3, ColStage4,
    ColStage5, ColStage6, ColStage7,
  ]

  # Mastery colors (gray to green gradient)
  ColMastery0* = Pal[28]     # Gray Dark (new)
  ColMastery1* = Pal[25]     # Red (seen)
  ColMastery2* = Pal[6]      # Orange (learning)
  ColMastery3* = Pal[7]      # Gold (familiar)
  ColMastery4* = Pal[11]     # Lime (confident)
  ColMastery5* = Pal[10]     # Green (mastered)

  MasteryColors*: array[6, Color] = [
    ColMastery0, ColMastery1, ColMastery2,
    ColMastery3, ColMastery4, ColMastery5,
  ]

proc masteryColor*(level: int): Color =
  if level >= 0 and level <= 5:
    MasteryColors[level]
  else:
    ColMastery0
