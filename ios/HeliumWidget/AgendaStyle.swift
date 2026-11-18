import SwiftUI

/// The app's theme colors (`AppTheme`), light and dark.
struct AgendaPalette {
  let primary: Color
  let surface: Color
  let onSurface: Color
  let muted: Color
  let error: Color

  init(colorScheme: ColorScheme, contrast: ColorSchemeContrast) {
    let mutedAlpha = contrast == .increased ? 1 : 0.65
    switch colorScheme {
    case .dark:
      primary = Color(hex: 0x5AA2C2)
      surface = Color(hex: 0x0F1417)
      onSurface = Color(hex: 0xDFE3E7)
      error = Color(hex: 0xE15C7B)
    default:
      primary = Color(hex: 0x418EB9)
      surface = Color(hex: 0xF6FAFE)
      onSurface = Color(hex: 0x181C1F)
      error = Color(hex: 0xC51D4B)
    }
    muted = onSurface.opacity(mutedAlpha)
  }
}

enum AgendaFont {
  static func title(_ size: CGFloat) -> Font { .custom("DMSerifDisplay-Regular", fixedSize: size) }
  static func medium(_ size: CGFloat) -> Font { .custom("Poppins-Medium", fixedSize: size) }
  static func semiBold(_ size: CGFloat) -> Font { .custom("Poppins-SemiBold", fixedSize: size) }
  static func regular(_ size: CGFloat) -> Font { .custom("Poppins-Regular", fixedSize: size) }
}

extension Color {
  init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255)
  }

  init(hex: String) {
    self.init(hex: Self.value(ofHex: hex))
  }

  static func value(ofHex hex: String) -> UInt32 {
    UInt32(hex.dropFirst(), radix: 16)!
  }
}

/// Black or white for a check drawn on an item color, as the app's `HeliumColors.contrastingTextColor`.
enum ContrastingInk {
  static func color(onHex hex: String, contrast: ColorSchemeContrast) -> Color {
    let luminance = relativeLuminance(hex)
    if contrast == .increased {
      let onBlack = (luminance + 0.05) / 0.05
      let onWhite = 1.05 / (luminance + 0.05)
      return onBlack >= onWhite ? .black : .white
    }
    return luminance > 0.5 ? .black : .white
  }

  private static func relativeLuminance(_ hex: String) -> Double {
    let value = Color.value(ofHex: hex)
    func linear(_ shift: UInt32) -> Double {
      let channel = Double((value >> shift) & 0xFF) / 255
      return channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linear(16) + 0.7152 * linear(8) + 0.0722 * linear(0)
  }
}
