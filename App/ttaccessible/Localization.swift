//
//  Localization.swift
//  ttaccessible
//
//  Created by Mathieu Martin on 17/03/2026.
//

import Foundation

enum AppLanguagePreference: String, Codable, CaseIterable {
    case system
    case english
    case french

    var localizationKey: String {
        switch self {
        case .system:
            return "preferences.general.language.system"
        case .english:
            return "preferences.general.language.english"
        case .french:
            return "preferences.general.language.french"
        }
    }

    var languageCode: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .french:
            return "fr"
        }
    }
}

enum L10n {
    private nonisolated(unsafe) static var overrideBundle: Bundle?

    nonisolated static func configure(languagePreference: AppLanguagePreference) {
        guard let languageCode = languagePreference.languageCode,
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj") else {
            overrideBundle = nil
            return
        }
        overrideBundle = Bundle(path: path)
    }

    nonisolated static func text(_ key: String) -> String {
        if let overrideBundle {
            return overrideBundle.localizedString(forKey: key, value: nil, table: nil)
        }
        return NSLocalizedString(key, comment: "")
    }

    nonisolated static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments)
    }
}
