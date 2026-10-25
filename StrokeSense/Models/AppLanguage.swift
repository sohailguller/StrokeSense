//
//  AppLanguage.swift
//  StrokeSense
//
//  The app's own language setting, chosen on first launch and changeable in Profile.
//  Translations live in <code>.lproj/Localizable.strings, keyed by the English text.
//

import SwiftUI
import UIKit

/// A language StrokeSense is translated into. Raw values are the .lproj folder names.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt-BR"
    case dutch = "nl"
    case polish = "pl"
    case russian = "ru"
    case ukrainian = "uk"
    case turkish = "tr"
    case arabic = "ar"
    case hindi = "hi"
    case bengali = "bn"
    case urdu = "ur"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case vietnamese = "vi"
    case indonesian = "id"

    var id: Self { self }

    var locale: Locale { Locale(identifier: rawValue) }

    var layoutDirection: LayoutDirection {
        locale.language.characterDirection == .rightToLeft ? .rightToLeft : .leftToRight
    }

    /// The language's name in itself, the way people look for it in a list.
    var nativeName: String {
        switch self {
        case .english: "English"
        case .spanish: "Español"
        case .french: "Français"
        case .german: "Deutsch"
        case .italian: "Italiano"
        case .portuguese: "Português (Brasil)"
        case .dutch: "Nederlands"
        case .polish: "Polski"
        case .russian: "Русский"
        case .ukrainian: "Українська"
        case .turkish: "Türkçe"
        case .arabic: "العربية"
        case .hindi: "हिन्दी"
        case .bengali: "বাংলা"
        case .urdu: "اردو"
        case .chineseSimplified: "简体中文"
        case .chineseTraditional: "繁體中文"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .vietnamese: "Tiếng Việt"
        case .indonesian: "Bahasa Indonesia"
        }
    }

    /// "Hello" in this language, for the welcome screen.
    var greeting: String {
        switch self {
        case .english: "Hello"
        case .spanish: "Hola"
        case .french: "Bonjour"
        case .german: "Hallo"
        case .italian: "Ciao"
        case .portuguese: "Olá"
        case .dutch: "Hallo"
        case .polish: "Cześć"
        case .russian: "Привет"
        case .ukrainian: "Привіт"
        case .turkish: "Merhaba"
        case .arabic: "مرحبًا"
        case .hindi: "नमस्ते"
        case .bengali: "নমস্কার"
        case .urdu: "السلام علیکم"
        case .chineseSimplified: "你好"
        case .chineseTraditional: "你好"
        case .japanese: "こんにちは"
        case .korean: "안녕하세요"
        case .vietnamese: "Xin chào"
        case .indonesian: "Halo"
        }
    }

    /// The language's name written in `language`, e.g. "Spanish" or "Espagnol".
    func name(in language: AppLanguage) -> String {
        language.locale.localizedString(forIdentifier: rawValue) ?? nativeName
    }

    /// Looks up `key` in this language's translations, whatever language the app is in.
    func localizedString(_ key: String) -> String {
        strings?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }

    fileprivate var strings: Bundle? {
        Bundle.main.path(forResource: rawValue, ofType: "lproj").flatMap(Bundle.init(path:))
    }

    /// The best match for the device's languages, which is also what a choice made earlier
    /// in the app or in the Settings app resolves to.
    private static var launchLanguage: AppLanguage {
        Bundle.main.preferredLocalizations.lazy.compactMap(AppLanguage.init(rawValue:)).first ?? .english
    }

    /// The language the app is shown in right now. Set through `LanguageSettings`.
    nonisolated(unsafe) private(set) static var current = launchLanguage

    /// Switches every string lookup to `language` straight away, and makes it the app's
    /// language in iOS too, so system screens (photo picker, Safari) follow on the next launch.
    fileprivate static func apply(_ language: AppLanguage) {
        current = language
        if !(Bundle.main is LanguageBundle) {
            object_setClass(Bundle.main, LanguageBundle.self)
        }
        LanguageBundle.strings = language.strings
        UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        // UIKit views created from now on (tab and navigation bars) read their direction from this.
        UIView.appearance().semanticContentAttribute =
            language.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
    }
}

/// Owns the language choice for the whole app. Changing it re-renders every screen in place.
@MainActor
final class LanguageSettings: ObservableObject {
    @Published var language: AppLanguage {
        didSet { AppLanguage.apply(language) }
    }

    init() {
        language = AppLanguage.current
        AppLanguage.apply(language)
    }
}

/// Routes the main bundle's string lookups to the chosen language, so text resolved in code
/// (`String(localized:)`) changes together with the text on screen.
private final class LanguageBundle: Bundle, @unchecked Sendable {
    nonisolated(unsafe) static var strings: Bundle?

    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let strings = Self.strings else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return strings.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension View {
    /// A navigation title, given as a translation key, that follows a language change made while
    /// the screen is open. UIKit keeps the first title it's handed for a `LocalizedStringKey`.
    func localizedNavigationTitle(_ key: String) -> some View {
        modifier(LocalizedNavigationTitle(key: key))
    }
}

private struct LocalizedNavigationTitle: ViewModifier {
    let key: String
    /// Read so the title is looked up again when the language changes.
    @Environment(\.locale) private var locale

    func body(content: Content) -> some View {
        content.navigationTitle(key.localized)
    }
}

extension String {
    /// This string used as a key into the app's translations, for text kept in data
    /// (quiz questions, suggested questions) rather than written as a literal.
    var localized: String {
        Bundle.main.localizedString(forKey: self, value: nil, table: nil)
    }
}
