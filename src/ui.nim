## Pixel-art UI components: buttons, progress bars, text panels

import raylib
import types, palette, input_manager

proc newPixelButton*(x, y, w, h: float32, label: string,
                     color: Color = PalBlue, hoverColor: Color = PalSkyBlue,
                     textColor: Color = PalWhite): PixelButton =
  PixelButton(
    rect: Rectangle(x: x, y: y, width: w, height: h),
    label: label,
    color: color,
    hoverColor: hoverColor,
    textColor: textColor,
    hovered: false,
    pressed: false,
  )

proc updateButton*(btn: var PixelButton): bool =
  ## Returns true if clicked this frame
  let mp = gameMousePos()
  btn.hovered = checkCollisionPointRec(mp, btn.rect)
  btn.pressed = btn.hovered and isMouseButtonPressed(Left)
  return btn.pressed

proc drawButton*(btn: PixelButton) =
  let col = if btn.hovered: btn.hoverColor else: btn.color
  # Shadow
  drawRectangle(int32(btn.rect.x) + 1, int32(btn.rect.y) + 1,
    int32(btn.rect.width), int32(btn.rect.height), PalBlack)
  # Body
  drawRectangle(int32(btn.rect.x), int32(btn.rect.y),
    int32(btn.rect.width), int32(btn.rect.height), col)
  # Border
  drawRectangleLines(
    Rectangle(x: btn.rect.x, y: btn.rect.y,
              width: btn.rect.width, height: btn.rect.height), 1.0, PalBlack)
  # Highlight (top edge)
  drawRectangle(int32(btn.rect.x) + 1, int32(btn.rect.y),
    int32(btn.rect.width) - 2, 1, Color(r: 255, g: 255, b: 255, a: 60))

  # Text centered
  let fontSize: int32 = 8
  let textW = measureText(btn.label, fontSize)
  let tx = int32(btn.rect.x) + (int32(btn.rect.width) - textW) div 2
  let ty = int32(btn.rect.y) + (int32(btn.rect.height) - fontSize) div 2
  drawText(btn.label, tx, ty, fontSize, btn.textColor)

proc drawProgressBar*(x, y, w, h: int32, progress: float32,
                      bgColor: Color = PalGrayDark, fgColor: Color = PalGreen,
                      borderColor: Color = PalBlack) =
  # Background
  drawRectangle(x, y, w, h, bgColor)
  # Fill
  let fillW = int32(float32(w) * clamp(progress, 0, 1))
  if fillW > 0:
    drawRectangle(x, y, fillW, h, fgColor)
  # Border
  drawRectangleLines(Rectangle(x: x.float32, y: y.float32,
    width: w.float32, height: h.float32), 1.0, borderColor)

proc drawTextPanel*(x, y, w, h: int32, text: string,
                    bgColor: Color = PalNavy, textColor: Color = PalWhite,
                    fontSize: int32 = 8) =
  drawRectangle(x, y, w, h, bgColor)
  drawRectangleLines(Rectangle(x: x.float32, y: y.float32,
    width: w.float32, height: h.float32), 1.0, PalBlack)
  drawText(text, x + 4, y + 4, fontSize, textColor)

proc drawCenteredText*(text: string, y: int32, fontSize: int32 = 8,
                       color: Color = PalWhite) =
  let textW = measureText(text, fontSize)
  let x = (GameWidth - textW) div 2
  drawText(text, x, y, fontSize, color)

proc drawPixelText*(text: string, x, y: int32, fontSize: int32 = 8,
                    color: Color = PalWhite) =
  drawText(text, x, y, fontSize, color)

proc drawTextShadow*(text: string, x, y: int32, fontSize: int32 = 8,
                     color: Color = PalWhite, shadowColor: Color = PalBlack) =
  drawText(text, x + 1, y + 1, fontSize, shadowColor)
  drawText(text, x, y, fontSize, color)

proc drawCenteredTextShadow*(text: string, y: int32, fontSize: int32 = 8,
                              color: Color = PalWhite) =
  let textW = measureText(text, fontSize)
  let x = (GameWidth - textW) div 2
  drawTextShadow(text, x, y, fontSize, color)
