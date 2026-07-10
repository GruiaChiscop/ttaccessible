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
        case .ttaccessible: return "preferences.general.keyBindingScheme.ttaccessible"
        case .qtTeamTalk: return "preferences.general.keyBindingScheme.qtTeamTalk"
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

    static func character(_ character: Character, modifiers: EventModifiers = .command) -> Self {
        Self(key: KeyEquivalent(character), modifiers: modifiers)
    }

    static func function(_ keyCode: Int, modifiers: EventModifiers = []) -> Self {
        Self(key: KeyEquivalent(Character(UnicodeScalar(keyCode)!)), modifiers: modifiers)
    }

    static func delete(modifiers: EventModifiers = []) -> Self {
        Self(key: .delete, modifiers: modifiers)
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
        .markForMove: nil,
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
        .toggleTTSEvents: nil,
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
        .moveUser: .character("v", modifiers: [.command, .option]),
        .markForMove: .character("x", modifiers: [.command, .option]),
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
