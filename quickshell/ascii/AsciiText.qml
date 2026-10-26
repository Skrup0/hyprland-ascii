import QtQuick
import qs.config

Text {
    color: Ascii.fg
    font.family: Ascii.family
    font.styleName: Ascii.style
    font.pixelSize: Ascii.pixelSize
    lineHeightMode: Text.FixedHeight
    lineHeight: Ascii.ch
    textFormat: Text.PlainText
}
