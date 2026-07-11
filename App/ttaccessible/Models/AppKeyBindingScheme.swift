//
//  AppKeyBindingScheme.swift
//  ttaccessible
//

import AppKit
import SwiftUI

enum AppKeyBindingScheme: String, Codable, CaseIterable {
    case ttaccessible
    case qtTeamTalk

    var localizationKey: String {
        switch self {
        case .ttaccessible: return "preferences.shortcuts.keyboardScheme.ttaccessible"
        case .qtTeamTalk: return "preferences.shortcuts.keyboardScheme.qtTeamTalk"
        }
    }

    func shortcut(_ command: AppShortcutCommand) -> AppKeyboardShortcut? {
        switch self {
        case .ttaccessible:
            return Self.ttaccessibleShortcuts[command] ?? nil
        case .qtTeamTalk:
            return Self.qtTeamTalkShortcuts[command] ?? Self.ttaccessibleShortcuts[command] ?? nil
        }
    }
}

enum AppShortcutCommand: Hashable {
    case preferences
    case newClientInstance
    case savedServerNew
    case savedServerConnect
    case savedServerImport
    case savedServerEdit
    case savedServerDelete
    case changeNickname
    case changeStatus
    case privateMessagesFromServerMenu
    case channelFiles
    case uploadFile
    case createChannel
    case editChannel
    case deleteChannel
    case connectedUsers
    case userAccounts
    case bannedUsers
    case serverProperties
    case saveServerConfig
    case serverStatistics
    case broadcastMessage
    case copyServerLink
    case disconnect
    case userInfo
    case muteUser
    case muteUserMediaFile
    case userVolume
    case toggleOperator
    case kickUser
    case kickUserFromServer
    case kickBanUser
    case moveUser
    case markForMove
    case moveMarkedUsers
    case focusPrimary
    case focusSecondary
    case focusMessage
    case focusHistory
    case focusMixer
    case joinChannel
    case leaveChannel
    case privateMessages
    case toggleMicrophone
    case masterMute
    case toggleTTSEvents
    case toggleSoundEvents
    case recording
    case streamMediaFile
    case streamMediaURL
    case stopMediaStream
    case hearMyself
    case announceAudio
    case exportChat
}

struct AppKeyboardShortcut {
    let key: KeyEquivalent
    let modifiers: EventModifiers
    let displayKey: String

    static func character(_ character: Character, modifiers: EventModifiers = .command) -> Self {
        Self(key: KeyEquivalent(character), modifiers: modifiers, displayKey: String(character).uppercased())
    }

    static func function(_ keyCode: Int, modifiers: EventModifiers = []) -> Self {
        let functionKey = keyCode - Int(NSF1FunctionKey) + 1
        return Self(
            key: KeyEquivalent(Character(UnicodeScalar(keyCode)!)),
            modifiers: modifiers,
            displayKey: "F\(functionKey)"
        )
    }

    static func delete(modifiers: EventModifiers = []) -> Self {
        Self(key: .delete, modifiers: modifiers, displayKey: L10n.text("help.shortcuts.key.delete"))
    }

    func displayString() -> String {
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append(L10n.text("help.shortcuts.modifier.command")) }
        if modifiers.contains(.control) { parts.append(L10n.text("help.shortcuts.modifier.control")) }
        if modifiers.contains(.option) { parts.append(L10n.text("help.shortcuts.modifier.option")) }
        if modifiers.contains(.shift) { parts.append(L10n.text("help.shortcuts.modifier.shift")) }
        parts.append(displayKey)
        return parts.joined(separator: "+")
    }
}

enum AppShortcutHelpCategory: CaseIterable {
    case application
    case server
    case user
    case navigation
    case audio
    case media
    case subscriptions

    var localizationKey: String {
        switch self {
        case .application: return "help.shortcuts.category.application"
        case .server: return "help.shortcuts.category.server"
        case .user: return "help.shortcuts.category.user"
        case .navigation: return "help.shortcuts.category.navigation"
        case .audio: return "help.shortcuts.category.audio"
        case .media: return "help.shortcuts.category.media"
        case .subscriptions: return "help.shortcuts.category.subscriptions"
        }
    }
}

struct AppShortcutHelpItem: Identifiable {
    let id: String
    let category: AppShortcutHelpCategory
    let titleKey: String
    let shortcut: (AppKeyBindingScheme) -> AppKeyboardShortcut?

    func title() -> String {
        L10n.text(titleKey)
    }

    func shortcutText(for scheme: AppKeyBindingScheme) -> String {
        shortcut(scheme)?.displayString() ?? L10n.text("help.shortcuts.unassigned")
    }
}

enum AppShortcutCatalog {
    static let items: [AppShortcutHelpItem] = [
        command(.preferences, category: .application, titleKey: "preferences.menu.title"),
        command(.newClientInstance, category: .application, titleKey: "profile.menu.newInstance"),

        command(.savedServerNew, category: .server, titleKey: "savedServers.menu.new"),
        command(.savedServerConnect, category: .server, titleKey: "savedServers.menu.connect"),
        command(.savedServerImport, category: .server, titleKey: "savedServers.menu.import"),
        command(.savedServerEdit, category: .server, titleKey: "savedServers.menu.edit"),
        command(.savedServerDelete, category: .server, titleKey: "savedServers.menu.delete"),
        command(.changeNickname, category: .server, titleKey: "connectedServer.identity.nickname.menu"),
        command(.changeStatus, category: .server, titleKey: "connectedServer.identity.status.menu"),
        command(.privateMessagesFromServerMenu, category: .server, titleKey: "privateMessages.menu.open"),
        command(.channelFiles, category: .server, titleKey: "files.menu.open"),
        command(.uploadFile, category: .server, titleKey: "files.menu.upload"),
        command(.createChannel, category: .server, titleKey: "connectedServer.menu.createChannel"),
        command(.editChannel, category: .server, titleKey: "connectedServer.menu.editChannel"),
        command(.deleteChannel, category: .server, titleKey: "connectedServer.menu.deleteChannel"),
        command(.connectedUsers, category: .server, titleKey: "connectedUsers.menu.open"),
        command(.userAccounts, category: .server, titleKey: "accounts.menu.open"),
        command(.bannedUsers, category: .server, titleKey: "bans.menu.open"),
        command(.serverProperties, category: .server, titleKey: "serverProperties.menu.open"),
        command(.saveServerConfig, category: .server, titleKey: "serverConfig.menu.save"),
        command(.serverStatistics, category: .server, titleKey: "stats.menu.open"),
        command(.broadcastMessage, category: .server, titleKey: "broadcast.menu.send"),
        command(.copyServerLink, category: .server, titleKey: "connectedServer.serverLink.copy"),
        command(.disconnect, category: .server, titleKey: "connectedServer.menu.disconnect"),

        command(.userInfo, category: .user, titleKey: "user.menu.info"),
        command(.muteUser, category: .user, titleKey: "help.shortcuts.command.toggleUserMute"),
        command(.muteUserMediaFile, category: .user, titleKey: "help.shortcuts.command.toggleUserMediaMute"),
        command(.userVolume, category: .user, titleKey: "user.menu.volume"),
        command(.toggleOperator, category: .user, titleKey: "help.shortcuts.command.toggleOperator"),
        command(.kickUser, category: .user, titleKey: "user.menu.kick"),
        command(.kickUserFromServer, category: .user, titleKey: "user.menu.kickServer"),
        command(.kickBanUser, category: .user, titleKey: "user.menu.kickBan"),
        command(.moveUser, category: .user, titleKey: "user.menu.move"),
        command(.markForMove, category: .user, titleKey: "connectedServer.menu.markForMove"),
        command(.moveMarkedUsers, category: .user, titleKey: "connectedServer.menu.moveMarkedUsersHere"),

        command(.focusPrimary, category: .navigation, titleKey: "shortcuts.focus.primary"),
        command(.focusSecondary, category: .navigation, titleKey: "shortcuts.focus.secondary"),
        command(.focusMessage, category: .navigation, titleKey: "shortcuts.focus.message"),
        command(.focusHistory, category: .navigation, titleKey: "shortcuts.focus.history"),
        command(.focusMixer, category: .navigation, titleKey: "mixer.menu.open"),
        command(.joinChannel, category: .navigation, titleKey: "connectedServer.menu.join"),
        command(.leaveChannel, category: .navigation, titleKey: "connectedServer.menu.leave"),
        command(.privateMessages, category: .navigation, titleKey: "shortcuts.messages"),

        command(.toggleMicrophone, category: .audio, titleKey: "shortcuts.microphone"),
        command(.masterMute, category: .audio, titleKey: "help.shortcuts.command.toggleMasterVolume"),
        command(.toggleTTSEvents, category: .audio, titleKey: "shortcuts.ttsEvents"),
        command(.toggleSoundEvents, category: .audio, titleKey: "shortcuts.soundEvents"),
        command(.recording, category: .audio, titleKey: "help.shortcuts.command.toggleRecording"),
        command(.hearMyself, category: .audio, titleKey: "shortcuts.hearMyself"),
        command(.announceAudio, category: .audio, titleKey: "shortcuts.announceAudio"),

        command(.streamMediaFile, category: .media, titleKey: "shortcuts.mediaStream.startFile"),
        command(.streamMediaURL, category: .media, titleKey: "shortcuts.mediaStream.startURL"),
        command(.stopMediaStream, category: .media, titleKey: "shortcuts.mediaStream.stop"),
        command(.exportChat, category: .media, titleKey: "shortcuts.exportChat")
    ] + UserSubscriptionOption.allCases.map { option in
        AppShortcutHelpItem(
            id: "subscription.\(option.rawValue)",
            category: .subscriptions,
            titleKey: option.localizationKey,
            shortcut: { scheme in option.shortcut(in: scheme) }
        )
    }

    static func items(in category: AppShortcutHelpCategory) -> [AppShortcutHelpItem] {
        items.filter { $0.category == category }
    }

    private static func command(
        _ command: AppShortcutCommand,
        category: AppShortcutHelpCategory,
        titleKey: String
    ) -> AppShortcutHelpItem {
        AppShortcutHelpItem(
            id: "command.\(command)",
            category: category,
            titleKey: titleKey,
            shortcut: { scheme in scheme.shortcut(command) }
        )
    }
}

extension AppKeyBindingScheme {
    private static let f2 = Int(NSF2FunctionKey)
    private static let f4 = Int(NSF4FunctionKey)
    private static let f5 = Int(NSF5FunctionKey)
    private static let f6 = Int(NSF6FunctionKey)
    private static let f7 = Int(NSF7FunctionKey)
    private static let f8 = Int(NSF8FunctionKey)
    private static let f9 = Int(NSF9FunctionKey)

    private static let ttaccessibleShortcuts: [AppShortcutCommand: AppKeyboardShortcut?] = [
        .preferences: .character(","),
        .newClientInstance: .character("n", modifiers: [.command, .shift]),
        .savedServerNew: .character("n"),
        .savedServerConnect: .function(f2),
        .savedServerImport: .character("i", modifiers: [.command, .shift]),
        .savedServerEdit: .character("e"),
        .savedServerDelete: .delete(),
        .changeNickname: .function(f5),
        .changeStatus: .function(f6),
        .privateMessagesFromServerMenu: .character("e", modifiers: [.command, .shift]),
        .channelFiles: .character("f", modifiers: [.command, .shift]),
        .uploadFile: .function(f5, modifiers: [.shift]),
        .createChannel: .function(f7),
        .editChannel: .function(f7, modifiers: [.shift]),
        .deleteChannel: .function(f8),
        .connectedUsers: .character("w", modifiers: [.command, .shift]),
        .userAccounts: .character("u", modifiers: [.command, .shift]),
        .bannedUsers: .character("b", modifiers: [.command, .shift]),
        .serverProperties: .character("p", modifiers: [.command, .shift]),
        .saveServerConfig: nil,
        .serverStatistics: .character("i", modifiers: [.command, .shift]),
        .broadcastMessage: .character("b"),
        .copyServerLink: .character("l", modifiers: [.command, .shift]),
        .disconnect: .function(f2),
        .userInfo: .character("i"),
        .muteUser: .character("m", modifiers: [.command, .shift]),
        .muteUserMediaFile: .character("m", modifiers: [.command, .control, .shift]),
        .userVolume: .character("u"),
        .toggleOperator: .character("o", modifiers: [.control, .command]),
        .kickUser: .character("k"),
        .kickUserFromServer: .character("k", modifiers: [.command, .shift]),
        .kickBanUser: nil,
        .moveUser: .character("x", modifiers: [.command, .option]),
        .markForMove: .character("x"),
        .moveMarkedUsers: .character("v"),
        .focusPrimary: .character("1"),
        .focusSecondary: .character("2"),
        .focusMessage: .character("3"),
        .focusHistory: .character("4"),
        .focusMixer: .character("5"),
        .joinChannel: .character("j"),
        .leaveChannel: .character("l"),
        .privateMessages: .character("e"),
        .toggleMicrophone: .character("a", modifiers: [.command, .shift]),
        .masterMute: .character("m"),
        .toggleTTSEvents: .character("s", modifiers: [.command, .control]),
        .toggleSoundEvents: .character("z", modifiers: [.command, .option]),
        .recording: .character("r"),
        .streamMediaFile: .character("s", modifiers: [.command, .option]),
        .streamMediaURL: .character("u", modifiers: [.command, .option]),
        .stopMediaStream: .character(".", modifiers: [.command, .option]),
        .hearMyself: .character("h", modifiers: [.command, .shift]),
        .announceAudio: .function(f9),
        .exportChat: .character("s", modifiers: [.command, .shift])
    ]

    private static let qtTeamTalkShortcuts: [AppShortcutCommand: AppKeyboardShortcut?] = [
        .preferences: .function(f4),
        .newClientInstance: .character("n"),
        .savedServerNew: nil,
        .privateMessagesFromServerMenu: nil,
        .connectedUsers: .character("u", modifiers: [.command, .shift]),
        .userAccounts: .character("l", modifiers: [.command, .shift]),
        .serverProperties: .function(f9),
        .saveServerConfig: .character("s", modifiers: [.command, .shift]),
        .serverStatistics: .function(f9, modifiers: [.shift]),
        .broadcastMessage: .character("e", modifiers: [.command, .shift]),
        .copyServerLink: .character("r", modifiers: [.command, .shift]),
        .muteUserMediaFile: .character("m", modifiers: [.command, .option, .shift]),
        .toggleOperator: .character("o"),
        .kickUserFromServer: .character("k", modifiers: [.command, .option]),
        .kickBanUser: .character("b", modifiers: [.command, .option]),
        .moveUser: nil,
        .markForMove: .character("x", modifiers: [.command, .option]),
        .moveMarkedUsers: .character("v", modifiers: [.command, .option]),
        .focusPrimary: nil,
        .focusSecondary: nil,
        .focusMessage: nil,
        .focusHistory: nil,
        .focusMixer: nil,
        .toggleTTSEvents: .character("s", modifiers: [.command, .option]),
        .toggleSoundEvents: .character("z", modifiers: [.command, .option]),
        .announceAudio: .character("t"),
        .streamMediaFile: .character("s"),
        .streamMediaURL: nil,
        .stopMediaStream: nil,
        .hearMyself: .character("3", modifiers: [.command, .shift]),
        .exportChat: nil
    ]
}

extension View {
    @ViewBuilder
    func appKeyboardShortcut(_ shortcut: AppKeyboardShortcut?) -> some View {
        if let shortcut {
            keyboardShortcut(shortcut.key, modifiers: shortcut.modifiers)
        } else {
            self
        }
    }
}
