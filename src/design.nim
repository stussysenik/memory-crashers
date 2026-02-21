## Design system: grid, spacing, typography, layout constants

const
  # Grid & Spacing (4px base unit)
  SpaceXS* = 2
  SpaceSM* = 4
  SpaceMD* = 8
  SpaceLG* = 12
  SpaceXL* = 16

  # Screen Layout (320x180)
  ScreenW* = 320
  ScreenH* = 180

  # Header: y=0..19
  HeaderY* = 0
  HeaderH* = 20

  # Content area: y=24..161 (8px margins on sides)
  ContentY* = 24
  ContentH* = 138
  ContentMargin* = 8
  ContentW* = ScreenW - ContentMargin * 2  # 304

  # Hint bar: y=166..179 (14px tall for readability)
  HintBarY* = 166
  HintBarH* = 14

  # Typography
  FontLarge* = 20'i32
  FontMedium* = 14'i32
  FontSmall* = 10'i32
  FontBody* = 10'i32   # Readable body text (same as FontSmall)
  FontTiny* = 8'i32

  # Card Sizes
  CardLGW* = 44'i32
  CardLGH* = 64'i32
  CardMDW* = 28'i32
  CardMDH* = 40'i32
  CardSMW* = 20'i32
  CardSMH* = 28'i32

  # Standard Button Sizes
  BtnPrimaryW* = 180
  BtnPrimaryH* = 20
  BtnSecondaryW* = 70
  BtnSecondaryH* = 18
  BtnSmallW* = 50
  BtnSmallH* = 16
  BtnBackW* = 40
  BtnBackH* = 14
  BtnHelpW* = 16
  BtnHelpH* = 14

  # Standard spacing
  RowGap* = 4       # between items in a row
  SectionGap* = 12  # between visual sections
  LineH* = 10       # single text line height with spacing

  # Header layout
  HelpBtnX* = ScreenW - BtnHelpW - 2  # "?" right-aligned in header
  HelpBtnY* = 3
  BackBtnX* = 4
  BackBtnY* = 3

  # Hint bar settings
  HintRotateInterval* = 8.0'f32  # seconds between tip changes
  HintMaxChars* = 38
