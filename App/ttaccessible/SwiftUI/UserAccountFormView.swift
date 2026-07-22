//
//  UserAccountFormView.swift
//  ttaccessible
//

import SwiftUI

// MARK: - Mode

enum UserAccountFormMode {
    case create
    case edit(UserAccountProperties)
}

// MARK: - Rights table row

private struct UserRightRow {
    let bit: UInt32
    let label: String
}

private let allUserRights: [UserRightRow] = [
    UserRightRow(bit: UInt32(USERRIGHT_MULTI_LOGIN.rawValue),              label: L10n.text("accounts.rights.multiLogin")),
    UserRightRow(bit: UInt32(USERRIGHT_VIEW_ALL_USERS.rawValue),           label: L10n.text("accounts.rights.viewAllUsers")),
    UserRightRow(bit: UInt32(USERRIGHT_CREATE_TEMPORARY_CHANNEL.rawValue), label: L10n.text("accounts.rights.createTemporaryChannel")),
    UserRightRow(bit: UInt32(USERRIGHT_MODIFY_CHANNELS.rawValue),          label: L10n.text("accounts.rights.modifyChannels")),
    UserRightRow(bit: UInt32(USERRIGHT_TEXTMESSAGE_BROADCAST.rawValue),    label: L10n.text("accounts.rights.broadcastMessage")),
    UserRightRow(bit: UInt32(USERRIGHT_KICK_USERS.rawValue),               label: L10n.text("accounts.rights.kickUsers")),
    UserRightRow(bit: UInt32(USERRIGHT_BAN_USERS.rawValue),                label: L10n.text("accounts.rights.banUsers")),
    UserRightRow(bit: UInt32(USERRIGHT_MOVE_USERS.rawValue),               label: L10n.text("accounts.rights.moveUsers")),
    UserRightRow(bit: UInt32(USERRIGHT_OPERATOR_ENABLE.rawValue),          label: L10n.text("accounts.rights.operatorEnable")),
    UserRightRow(bit: UInt32(USERRIGHT_UPLOAD_FILES.rawValue),             label: L10n.text("accounts.rights.uploadFiles")),
    UserRightRow(bit: UInt32(USERRIGHT_DOWNLOAD_FILES.rawValue),           label: L10n.text("accounts.rights.downloadFiles")),
    UserRightRow(bit: UInt32(USERRIGHT_UPDATE_SERVERPROPERTIES.rawValue),  label: L10n.text("accounts.rights.updateServerProperties")),
    UserRightRow(bit: UInt32(USERRIGHT_TRANSMIT_VOICE.rawValue),           label: L10n.text("accounts.rights.transmitVoice")),
    UserRightRow(bit: UInt32(USERRIGHT_TRANSMIT_VIDEOCAPTURE.rawValue),    label: L10n.text("accounts.rights.transmitVideoCapture")),
    UserRightRow(bit: UInt32(USERRIGHT_TRANSMIT_DESKTOP.rawValue),         label: L10n.text("accounts.rights.transmitDesktop")),
    UserRightRow(bit: UInt32(USERRIGHT_TRANSMIT_DESKTOPINPUT.rawValue),    label: L10n.text("accounts.rights.transmitDesktopInput")),
    UserRightRow(bit: UInt32(USERRIGHT_TRANSMIT_MEDIAFILE_AUDIO.rawValue), label: L10n.text("accounts.rights.transmitMediaFileAudio")),
    UserRightRow(bit: UInt32(USERRIGHT_TRANSMIT_MEDIAFILE_VIDEO.rawValue), label: L10n.text("accounts.rights.transmitMediaFileVideo")),
    UserRightRow(bit: UInt32(USERRIGHT_LOCKED_NICKNAME.rawValue),          label: L10n.text("accounts.rights.lockedNickname")),
    UserRightRow(bit: UInt32(USERRIGHT_LOCKED_STATUS.rawValue),            label: L10n.text("accounts.rights.lockedStatus")),
    UserRightRow(bit: UInt32(USERRIGHT_RECORD_VOICE.rawValue),             label: L10n.text("accounts.rights.recordVoice")),
    UserRightRow(bit: UInt32(USERRIGHT_VIEW_HIDDEN_CHANNELS.rawValue),     label: L10n.text("accounts.rights.viewHiddenChannels")),
    UserRightRow(bit: UInt32(USERRIGHT_TEXTMESSAGE_USER.rawValue),         label: L10n.text("accounts.rights.textMessageUser")),
    UserRightRow(bit: UInt32(USERRIGHT_TEXTMESSAGE_CHANNEL.rawValue),      label: L10n.text("accounts.rights.textMessageChannel")),
]

// MARK: - Form view

struct UserAccountFormView: View {
    let mode: UserAccountFormMode
    let connectionController: TeamTalkConnectionController?

    /// Closes the presenting sheet. Called on cancel, and immediately after a
    /// valid save (before the network round-trip finishes) — matching the
    /// previous AppKit form's dismiss-then-submit ordering.
    let onDismiss: () -> Void
    /// Called once the create/update request completes.
    let onSave: () -> Void

    @State private var username: String
    @State private var password: String
    @State private var userTypeIndex: Int
    @State private var initChannel: String
    @State private var note: String
    @State private var userRights: UInt32
    @State private var audioBpsLimit: String
    @State private var commandsLimit: String
    @State private var commandsIntervalMSec: String

    init(mode: UserAccountFormMode, connectionController: TeamTalkConnectionController?, onDismiss: @escaping () -> Void, onSave: @escaping () -> Void) {
        self.mode = mode
        self.connectionController = connectionController
        self.onDismiss = onDismiss
        self.onSave = onSave

        switch mode {
        case .create:
            _username = State(initialValue: "")
            _password = State(initialValue: "")
            _userTypeIndex = State(initialValue: 0)
            _initChannel = State(initialValue: "")
            _note = State(initialValue: "")
            _userRights = State(initialValue: UserAccountProperties.defaultUserRights)
            _audioBpsLimit = State(initialValue: "")
            _commandsLimit = State(initialValue: "")
            _commandsIntervalMSec = State(initialValue: "")
        case .edit(let account):
            _username = State(initialValue: account.username)
            _password = State(initialValue: account.password)
            _userTypeIndex = State(initialValue: account.userType == .defaultUser ? 0 : (account.userType == .admin ? 1 : 2))
            _initChannel = State(initialValue: account.initChannel)
            _note = State(initialValue: account.note)
            _userRights = State(initialValue: account.userRights)
            _audioBpsLimit = State(initialValue: account.audioBpsLimit == 0 ? "" : "\(account.audioBpsLimit)")
            _commandsLimit = State(initialValue: account.commandsLimit == 0 ? "" : "\(account.commandsLimit)")
            _commandsIntervalMSec = State(initialValue: account.commandsIntervalMSec == 0 ? "" : "\(account.commandsIntervalMSec)")
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            TabView {
                essentialTab
                    .tabItem { Text(L10n.text("accounts.form.tab.essential")) }
                rightsTab
                    .tabItem { Text(L10n.text("accounts.form.tab.rights")) }
                advancedTab
                    .tabItem { Text(L10n.text("accounts.form.tab.advanced")) }
            }

            HStack {
                Spacer()
                Button(L10n.text("common.cancel")) { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.text("common.save")) { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 520, height: 440)
    }

    private var essentialTab: some View {
        Form {
            TextField(L10n.text("accounts.form.username"), text: $username)
            TextField(L10n.text("accounts.form.password"), text: $password)
            Picker(L10n.text("accounts.form.type"), selection: $userTypeIndex) {
                Text(L10n.text("accounts.type.default")).tag(0)
                Text(L10n.text("accounts.type.admin")).tag(1)
                Text(L10n.text("accounts.type.disabled")).tag(2)
            }
            TextField(L10n.text("accounts.form.initChannel"), text: $initChannel)
            TextField(L10n.text("accounts.form.note"), text: $note)
        }
        .padding()
    }

    private var rightsTab: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(L10n.text("accounts.form.rights.enableAll")) {
                    userRights = allUserRights.reduce(0) { $0 | $1.bit }
                }
                Button(L10n.text("accounts.form.rights.disableAll")) {
                    userRights = 0
                }
                Button(L10n.text("accounts.form.rights.defaultRights")) {
                    userRights = UserAccountProperties.defaultUserRights
                }
                Spacer()
            }
            List(allUserRights, id: \.bit) { right in
                Toggle(right.label, isOn: Binding(
                    get: { (userRights & right.bit) != 0 },
                    set: { isOn in
                        if isOn {
                            userRights |= right.bit
                        } else {
                            userRights &= ~right.bit
                        }
                    }
                ))
                .toggleStyle(.checkbox)
            }
        }
        .padding()
    }

    private var advancedTab: some View {
        Form {
            TextField(L10n.text("accounts.form.audioBpsLimit"), text: $audioBpsLimit)
            TextField(L10n.text("accounts.form.commandsLimit"), text: $commandsLimit)
            TextField(L10n.text("accounts.form.commandsInterval"), text: $commandsIntervalMSec)
        }
        .padding()
    }

    private func save() {
        var account = UserAccountProperties()
        account.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        account.password = password
        switch userTypeIndex {
        case 0: account.userType = .defaultUser
        case 1: account.userType = .admin
        default: account.userType = .disabled
        }
        account.userRights = userRights
        account.initChannel = initChannel.trimmingCharacters(in: .whitespacesAndNewlines)
        account.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        account.audioBpsLimit = Int32(audioBpsLimit) ?? 0
        account.commandsLimit = Int32(commandsLimit) ?? 0
        account.commandsIntervalMSec = Int32(commandsIntervalMSec) ?? 0

        guard account.username.isEmpty == false else { return }

        onDismiss()

        switch mode {
        case .create:
            connectionController?.createUserAccount(account) { [onSave] _ in onSave() }
        case .edit(let original):
            connectionController?.updateUserAccount(originalUsername: original.username, updated: account) { [onSave] _ in onSave() }
        }
    }
}
