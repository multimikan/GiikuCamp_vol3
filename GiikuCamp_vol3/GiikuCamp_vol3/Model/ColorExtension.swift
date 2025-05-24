import SwiftUI

extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var intValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&intValue)
        
        let alpha, red, green, blue: UInt64
        
        switch hexString.count {
        case 3: // RGB (12-bit)
            alpha = 255
            red   = (intValue >> 8) * 17
            green = (intValue >> 4 & 0xF) * 17
            blue  = (intValue & 0xF) * 17
        case 6: // RGB (24-bit)
            alpha = 255
            red   = intValue >> 16
            green = intValue >> 8 & 0xFF
            blue  = intValue & 0xFF
        case 8: // ARGB (32-bit)
            alpha = intValue >> 24
            red   = intValue >> 16 & 0xFF
            green = intValue >> 8 & 0xFF
            blue  = intValue & 0xFF
        default:
            // 不正な形式の場合はデフォルト色（例：透明な黒）を設定
            alpha = 255
            red   = 0
            green = 0
            blue  = 0
            print("Warning: Invalid hex color string: \(hex). Defaulting to black.")
        }

        self.init(
            .sRGB,
            red: Double(red) / 255.0,
            green: Double(green) / 255.0,
            blue: Double(blue) / 255.0,
            opacity: Double(alpha) / 255.0
        )
    }
} 