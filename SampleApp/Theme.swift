//
//  Theme.swift
//  SampleApp
//
//  Created by lee on 2024/9/21.
//

import Foundation
import Runestone
import UIKit
import SwiftUI

extension UIColor {
    public convenience init?(hex: String) {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return nil
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    var redValue: CGFloat{ return CIColor(color: self).red }
    var greenValue: CGFloat{ return CIColor(color: self).green }
    var blueValue: CGFloat{ return CIColor(color: self).blue }
    var alphaValue: CGFloat{ return CIColor(color: self).alpha }
}

extension UIColor {
    convenience init(id: String) {
        self.init(Color(id: id))
    }

    // Defining dynamic colors in Swift
    // https://www.swiftbysundell.com/articles/defining-dynamic-colors-in-swift/
    convenience init(
        light lightModeColor: @escaping @autoclosure () -> UIColor,
        dark darkModeColor: @escaping @autoclosure () -> UIColor
    ) {
        self.init { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light:
                return lightModeColor()
            case .dark:
                return darkModeColor()
            case .unspecified:
                return lightModeColor()
            @unknown default:
                return lightModeColor()
            }
        }
    }
}

extension Color {
    init(id: String) {

        var lightColor = UIColor(named: id) ?? .gray
        var darkColor = UIColor(named: id) ?? .gray

        if let darkThemeDictionary = ThemeManager.darkTheme?.dictionary {
            let darkColorDict = darkThemeDictionary["colors"] as! [String: String]
            if let hexString = darkColorDict[id] {
                darkColor = UIColor(Color(hexString: hexString))
            }
        }

        if let lightThemeDictionary = ThemeManager.lightTheme?.dictionary {
            let lightColorDict = lightThemeDictionary["colors"] as! [String: String]
            if let hexString = lightColorDict[id] {
                lightColor = UIColor(Color(hexString: hexString))
            }
        }

        self.init(
            UIColor(
                light: lightColor,
                dark: darkColor
            )
        )
    }

    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        //        case 4: // RGBA (12-bit)
        //            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // RGBA (32-bit)
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}



struct Theme {
    let id = UUID()
    let name: String
    let url: URL
    let isDark: Bool
    // editor.background, activitybar.background, statusbar_background, sidebar_background
    let preview: (Color, Color, Color, Color)

    lazy var data: Data = {
        try! Data(contentsOf: url)
    }()

    lazy var dictionary: [String: Any] = {
        try! JSONSerialization.jsonObject(with: data, options: .allowFragments)
            as! [String: Any]
    }()

    lazy var jsonString: String = {
        String(data: data, encoding: .utf8)!
    }()
}



class DynamicTheme: Runestone.Theme {

    var lightTheme: Runestone.Theme
    var darkTheme: Runestone.Theme
    var editorFont: UIFont

    init(light: Runestone.Theme, dark: Runestone.Theme, font: UIFont) {
        self.lightTheme = light
        self.darkTheme = dark
        self.editorFont = font

        self.backgroundColor = UIColor(dynamicProvider: { trait in
            UIColor(id: "editor.background")
        })
        self.textColor = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .light ? light.textColor : dark.textColor
        })
        self.gutterBackgroundColor = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .light
                ? light.gutterBackgroundColor : dark.gutterBackgroundColor
        })
        self.gutterHairlineColor = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .light
                ? light.gutterHairlineColor : dark.gutterHairlineColor
        })
        self.lineNumberColor = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .light ? light.lineNumberColor : dark.lineNumberColor
        })
        self.lineNumberFont = editorFont
        self.selectedLineBackgroundColor = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .light
                ? light.selectedLineBackgroundColor : dark.selectedLineBackgroundColor
        })
        self.selectedLinesLineNumberColor = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .light
                ? light.selectedLinesLineNumberColor : dark.selectedLinesLineNumberColor
        })
        self.selectedLinesGutterBackgroundColor = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .light
                ? light.selectedLinesGutterBackgroundColor : dark.selectedLinesGutterBackgroundColor
        })
        self.invisibleCharactersColor = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .light
                ? light.invisibleCharactersColor : dark.invisibleCharactersColor
        })
        self.pageGuideHairlineColor = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .light
                ? light.pageGuideHairlineColor : dark.pageGuideHairlineColor
        })
        self.pageGuideBackgroundColor = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .light
                ? light.pageGuideBackgroundColor : dark.pageGuideBackgroundColor
        })
        self.markedTextBackgroundColor = UIColor(dynamicProvider: { trait in
            trait.userInterfaceStyle == .light
                ? light.markedTextBackgroundColor : dark.markedTextBackgroundColor
        })
    }

    var backgroundColor: UIColor

    var font: UIFont {
        editorFont
    }

    var textColor: UIColor

    var gutterBackgroundColor: UIColor

    var gutterHairlineColor: UIColor

    var lineNumberColor: UIColor

    var lineNumberFont: UIFont

    var selectedLineBackgroundColor: UIColor

    var selectedLinesLineNumberColor: UIColor

    var selectedLinesGutterBackgroundColor: UIColor

    var invisibleCharactersColor: UIColor

    var pageGuideHairlineColor: UIColor

    var pageGuideBackgroundColor: UIColor

    var markedTextBackgroundColor: UIColor

    func textColor(for highlightName: String) -> UIColor? {
        return UIColor(dynamicProvider: { trait in
            return
                (trait.userInterfaceStyle == .light
                ? self.lightTheme.textColor(for: highlightName)
                : self.darkTheme.textColor(for: highlightName)) ?? UIColor.white
        })
    }
}

class RunestoneTheme: Runestone.Theme {

    private var vsTheme: Theme
    private var baseTheme = DefaultTheme()
    private var editorFont: UIFont
    var backgroundColor: UIColor? {
        UIColor(hex: vsColors["editor.background"] ?? "")
    }

    init(vsTheme: Theme) {
        self.vsTheme = vsTheme
        self.editorFont = UIFont()
    }

    private var vsColors: [String: String] {
        vsTheme.dictionary as? [String: String] ?? [:]
    }

    private lazy var vsTokenColors: [String: String] = {
        var result: [String: String] = [:]
        guard let tokenColors = vsTheme.dictionary["tokenColors"] as? [[String: Any]] else {
            return result
        }
        for tokenColor in tokenColors {
            var scopes = tokenColor["scope"] as? [String]
            if let scope = tokenColor["scope"] as? String {
                scopes = [scope]
            }
            guard let scopes,
                let settings = tokenColor["settings"] as? [String: Any],
                let foreground = settings["foreground"] as? String
            else {
                continue
            }
            for scope in scopes {
                result[scope] = foreground
            }
        }
        return result
    }()

    var font: UIFont {
        editorFont
    }

    var textColor: UIColor {
        UIColor(hex: vsColors["editor.foreground"] ?? "") ?? baseTheme.textColor
    }

    var gutterBackgroundColor: UIColor {
        UIColor.clear
    }

    var gutterHairlineColor: UIColor {
        UIColor.clear
    }

    var lineNumberColor: UIColor {
        UIColor(hex: vsColors["editorLineNumber.foreground"] ?? "") ?? baseTheme.lineNumberColor
    }

    var lineNumberFont: UIFont {
        editorFont
    }

    var selectedLineBackgroundColor: UIColor {
        UIColor(hex: vsColors["editor.background"] ?? "") ?? baseTheme.selectedLineBackgroundColor
    }

    var selectedLinesLineNumberColor: UIColor {
        UIColor(hex: vsColors["editorLineNumber.activeForeground"] ?? "")
            ?? baseTheme.selectedLinesLineNumberColor
    }

    var selectedLinesGutterBackgroundColor: UIColor {
        UIColor(hex: vsColors["editor.background"] ?? "")
            ?? baseTheme.selectedLinesGutterBackgroundColor
    }

    var invisibleCharactersColor: UIColor {
        baseTheme.invisibleCharactersColor
    }

    var pageGuideHairlineColor: UIColor {
        UIColor(hex: vsColors["editor.background"] ?? "")
            ?? baseTheme.pageGuideHairlineColor
    }

    var pageGuideBackgroundColor: UIColor {
        UIColor(hex: vsColors["editor.background"] ?? "")
            ?? baseTheme.pageGuideBackgroundColor
    }

    var markedTextBackgroundColor: UIColor {
        UIColor(hex: vsColors["editor.selectionBackground"] ?? "")
            ?? baseTheme.markedTextBackgroundColor
    }

    func textColor(for highlightName: String) -> UIColor? {
        // https://github.com/yonihemi/TM2Runestone/blob/main/Sources/TM2Runestone/Convert.swift
        let mapping = [
            "delimeter": "punctuation.separator",
            "text.strong_emphasis": "markup.bold",
            "text.emphasis": "markup.italic",
            "text.title": "markup.heading",
            "text.link": "markup.underline.link",

            "attribute": "entity.other.attribute-name",
            "constant": "support.constant",
            "constant.builtin": "constant.language",
            "constructor": "",
            "comment": "comment",
            "delimiter": "",
            "escape": "constant.character.escape",
            "field": "",
            "function": "entity.name.function",
            "function.builtin": "entity.name.function",
            "function.method": "entity.name.function",
            "keyword": "keyword",
            "number": "constant.numeric",
            "operator": "keyword.operator",
            "property": "variable",
            "punctuation.bracket": "punctuation",
            "punctuation.delimiter": "punctuation",
            "punctuation.special": "punctuation",
            "string": "string",
            "string.special": "constant.other.symbol",
            "tag": "entity.name.tag",
            "type": "storage.type",
            "type.builtin": "storage.type",
            "variable": "variable",
            "variable.builtin": "variable",

        ]
        guard let tokenName = mapping[highlightName],
            let hex = vsTokenColors[tokenName]
        else {
            return baseTheme.textColor
        }
        return UIColor(hex: hex)
    }

}
