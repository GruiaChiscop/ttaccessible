//
//  ServerPropertiesView.swift
//  ttaccessible
//

import SwiftUI

struct ServerPropertiesView: View {
    private let initial: ServerPropertiesData
    let onCancel: () -> Void
    let onSave: (ServerPropertiesData) -> Void

    @State private var name: String
    @State private var motd: String
    @State private var maxUsers: String
    @State private var userTimeout: String
    @State private var loginDelayMSec: String
    @State private var maxLoginAttempts: String
    @State private var maxLoginsPerIPAddress: String
    @State private var autoSave: Bool
    @State private var maxVoiceTxPerSecond: String
    @State private var maxVideoCaptureTxPerSecond: String
    @State private var maxMediaFileTxPerSecond: String
    @State private var maxDesktopTxPerSecond: String
    @State private var maxTotalTxPerSecond: String
    @State private var tcpPort: String
    @State private var udpPort: String
    private let serverVersion: String
    private let serverProtocolVersion: String

    init(properties: ServerPropertiesData, onCancel: @escaping () -> Void, onSave: @escaping (ServerPropertiesData) -> Void) {
        self.initial = properties
        self.onCancel = onCancel
        self.onSave = onSave
        _name = State(initialValue: properties.name)
        _motd = State(initialValue: properties.motdRaw)
        _maxUsers = State(initialValue: String(properties.maxUsers))
        _userTimeout = State(initialValue: String(properties.userTimeout))
        _loginDelayMSec = State(initialValue: String(properties.loginDelayMSec))
        _maxLoginAttempts = State(initialValue: String(properties.maxLoginAttempts))
        _maxLoginsPerIPAddress = State(initialValue: String(properties.maxLoginsPerIPAddress))
        _autoSave = State(initialValue: properties.autoSave)
        _maxVoiceTxPerSecond = State(initialValue: String(properties.maxVoiceTxPerSecond))
        _maxVideoCaptureTxPerSecond = State(initialValue: String(properties.maxVideoCaptureTxPerSecond))
        _maxMediaFileTxPerSecond = State(initialValue: String(properties.maxMediaFileTxPerSecond))
        _maxDesktopTxPerSecond = State(initialValue: String(properties.maxDesktopTxPerSecond))
        _maxTotalTxPerSecond = State(initialValue: String(properties.maxTotalTxPerSecond))
        _tcpPort = State(initialValue: String(properties.tcpPort))
        _udpPort = State(initialValue: String(properties.udpPort))
        self.serverVersion = properties.serverVersion
        self.serverProtocolVersion = properties.serverProtocolVersion
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView {
                Form {
                    Section(L10n.text("serverProperties.form.section.general")) {
                        FormRow(L10n.text("serverProperties.form.name")) {
                            TextField("", text: $name)
                        }
                        FormRow(L10n.text("serverProperties.form.motd")) {
                            TextEditor(text: $motd)
                                .font(.body)
                                .frame(height: 60)
                                .border(Color(nsColor: .separatorColor))
                        }
                        FormRow(L10n.text("serverProperties.form.maxUsers")) {
                            TextField("0", text: $maxUsers)
                        }
                        FormRow(L10n.text("serverProperties.form.userTimeout")) {
                            TextField("0", text: $userTimeout)
                        }
                        FormRow(L10n.text("serverProperties.form.loginDelayMSec")) {
                            TextField("0", text: $loginDelayMSec)
                        }
                        FormRow(L10n.text("serverProperties.form.maxLoginAttempts")) {
                            TextField("0", text: $maxLoginAttempts)
                        }
                        FormRow(L10n.text("serverProperties.form.maxLoginsPerIPAddress")) {
                            TextField("0", text: $maxLoginsPerIPAddress)
                        }
                        Toggle(L10n.text("serverProperties.form.autoSave"), isOn: $autoSave)
                            .toggleStyle(.checkbox)
                    }

                    Section(L10n.text("serverProperties.form.section.bandwidth")) {
                        FormRow(L10n.text("serverProperties.form.maxVoiceTx")) {
                            TextField("0", text: $maxVoiceTxPerSecond)
                        }
                        FormRow(L10n.text("serverProperties.form.maxVideoTx")) {
                            TextField("0", text: $maxVideoCaptureTxPerSecond)
                        }
                        FormRow(L10n.text("serverProperties.form.maxMediaFileTx")) {
                            TextField("0", text: $maxMediaFileTxPerSecond)
                        }
                        FormRow(L10n.text("serverProperties.form.maxDesktopTx")) {
                            TextField("0", text: $maxDesktopTxPerSecond)
                        }
                        FormRow(L10n.text("serverProperties.form.maxTotalTx")) {
                            TextField("0", text: $maxTotalTxPerSecond)
                        }
                    }

                    Section(L10n.text("serverProperties.form.section.info")) {
                        FormRow(L10n.text("serverProperties.form.tcpPort")) {
                            TextField("0", text: $tcpPort)
                        }
                        FormRow(L10n.text("serverProperties.form.udpPort")) {
                            TextField("0", text: $udpPort)
                        }
                        FormRow(L10n.text("serverProperties.form.serverVersion")) {
                            Text(serverVersion)
                        }
                        FormRow(L10n.text("serverProperties.form.protocolVersion")) {
                            Text(serverProtocolVersion)
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button(L10n.text("common.cancel")) { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.text("common.save")) { save() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 480, height: 540)
    }

    private func save() {
        var updated = initial
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.motdRaw = motd
        updated.maxUsers = Int32(maxUsers) ?? initial.maxUsers
        updated.userTimeout = Int32(userTimeout) ?? initial.userTimeout
        updated.loginDelayMSec = Int32(loginDelayMSec) ?? initial.loginDelayMSec
        updated.maxLoginAttempts = Int32(maxLoginAttempts) ?? initial.maxLoginAttempts
        updated.maxLoginsPerIPAddress = Int32(maxLoginsPerIPAddress) ?? initial.maxLoginsPerIPAddress
        updated.autoSave = autoSave
        updated.maxVoiceTxPerSecond = Int32(maxVoiceTxPerSecond) ?? initial.maxVoiceTxPerSecond
        updated.maxVideoCaptureTxPerSecond = Int32(maxVideoCaptureTxPerSecond) ?? initial.maxVideoCaptureTxPerSecond
        updated.maxMediaFileTxPerSecond = Int32(maxMediaFileTxPerSecond) ?? initial.maxMediaFileTxPerSecond
        updated.maxDesktopTxPerSecond = Int32(maxDesktopTxPerSecond) ?? initial.maxDesktopTxPerSecond
        updated.maxTotalTxPerSecond = Int32(maxTotalTxPerSecond) ?? initial.maxTotalTxPerSecond
        updated.tcpPort = Int32(tcpPort) ?? initial.tcpPort
        updated.udpPort = Int32(udpPort) ?? initial.udpPort
        onSave(updated)
    }
}

/// `LabeledContent`-style row that works back to macOS 12 (`LabeledContent` itself needs 13+).
private struct FormRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .frame(width: 160, alignment: .leading)
            content
        }
    }
}
