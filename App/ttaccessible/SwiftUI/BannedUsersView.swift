//
//  BannedUsersView.swift
//  ttaccessible
//

import SwiftUI
import AppKit
import Combine

extension BannedUserProperties: Identifiable {
    var id: String { "\(banTime)|\(username)|\(ipAddress)|\(banTypes)|\(owner)" }
}

@MainActor
final class BannedUsersViewModel: ObservableObject {
    @Published private(set) var bans: [BannedUserProperties] = []
    weak var connectionController: TeamTalkConnectionController?

    init(connectionController: TeamTalkConnectionController?) {
        self.connectionController = connectionController
    }

    func update(bans: [BannedUserProperties]) {
        self.bans = bans.sorted { $0.banTime > $1.banTime }
    }

    func refresh() {
        connectionController?.listBans()
    }

    func removeBans(_ bans: [BannedUserProperties], completion: @escaping () -> Void) {
        let group = DispatchGroup()
        for ban in bans {
            group.enter()
            connectionController?.removeBan(ban) { _ in group.leave() }
        }
        group.notify(queue: .main, execute: completion)
    }

    func addBan(_ ban: BannedUserProperties, completion: @escaping () -> Void) {
        connectionController?.addBan(ban) { _ in completion() }
    }
}

struct BannedUsersView: View {
    @ObservedObject var viewModel: BannedUsersViewModel

    @State private var selection = Set<BannedUserProperties.ID>()
    @State private var isShowingUnbanConfirm = false
    @State private var isShowingAddBan = false

    var body: some View {
        VStack(spacing: 12) {
            Table(viewModel.bans, selection: $selection) {
                TableColumn(L10n.text("bans.column.nickname"), value: \.nickname)
                TableColumn(L10n.text("bans.column.username"), value: \.username)
                TableColumn(L10n.text("bans.column.type"), value: \.displayBanType)
                TableColumn(L10n.text("bans.column.date"), value: \.banTime)
                TableColumn(L10n.text("bans.column.owner"), value: \.owner)
                TableColumn(L10n.text("bans.column.channel"), value: \.channelPath)
                TableColumn(L10n.text("bans.column.ip"), value: \.ipAddress)
            }
            .accessibilityLabel(L10n.text("bans.table.accessibilityLabel"))
            .onDeleteCommand {
                guard selection.isEmpty == false else { return }
                isShowingUnbanConfirm = true
            }

            HStack {
                Button(L10n.text("bans.button.refresh")) { viewModel.refresh() }
                Spacer()
                Button(L10n.text("bans.button.add")) { isShowingAddBan = true }
                Button(L10n.text("bans.button.unban")) { isShowingUnbanConfirm = true }
                    .disabled(selection.isEmpty)
            }
        }
        .padding(12)
        .frame(minWidth: 760, minHeight: 460)
        .alert(unbanTitle, isPresented: $isShowingUnbanConfirm) {
            Button(L10n.text("bans.unban.confirm"), role: .destructive) { unbanSelected() }
            Button(L10n.text("common.cancel"), role: .cancel) {}
        } message: {
            Text(L10n.text("bans.unban.message"))
        }
        .sheet(isPresented: $isShowingAddBan) {
            AddBanSheet(
                onCancel: { isShowingAddBan = false },
                onAdd: { ban in
                    isShowingAddBan = false
                    let value = ban.ipAddress.isEmpty == false ? ban.ipAddress : ban.username
                    viewModel.addBan(ban) {
                        viewModel.refresh()
                        announce(L10n.format("bans.announced.banned", value))
                    }
                }
            )
        }
    }

    private var selectedBans: [BannedUserProperties] {
        viewModel.bans.filter { selection.contains($0.id) }
    }

    private var unbanTitle: String {
        let bans = selectedBans
        let name = bans.count == 1 ? bans[0].displayName : "\(bans.count) utilisateurs"
        return L10n.format("bans.unban.title", name)
    }

    private func unbanSelected() {
        let bans = selectedBans
        guard bans.isEmpty == false else { return }
        let name = bans.count == 1 ? bans[0].displayName : "\(bans.count) utilisateurs"
        viewModel.removeBans(bans) {
            viewModel.refresh()
            announce(L10n.format("bans.announced.unbanned", name))
        }
    }
}

private struct AddBanSheet: View {
    let onCancel: () -> Void
    let onAdd: (BannedUserProperties) -> Void

    @State private var typeIndex = 0
    @State private var value = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("bans.add.title"))
                .font(.headline)

            Picker(L10n.text("bans.add.type"), selection: $typeIndex) {
                Text(L10n.text("bans.add.type.ip")).tag(0)
                Text(L10n.text("bans.add.type.username")).tag(1)
            }
            .pickerStyle(.radioGroup)

            TextField(L10n.text("bans.add.value.placeholder"), text: $value)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button(L10n.text("common.cancel")) { onCancel() }
                    .keyboardShortcut(.cancelAction)
                Button(L10n.text("common.save")) { add() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 340)
    }

    private func add() {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        var ban = BannedUserProperties(ipAddress: "", channelPath: "", banTime: "",
                                        nickname: "", username: "", banTypes: 0, owner: "")
        if typeIndex == 0 {
            ban.ipAddress = trimmed
            ban.banTypes = UInt32(BANTYPE_IPADDR.rawValue)
        } else {
            ban.username = trimmed
            ban.banTypes = UInt32(BANTYPE_USERNAME.rawValue)
        }
        onAdd(ban)
    }
}

@MainActor
private func announce(_ message: String) {
    let element = NSApp.accessibilityWindow() ?? NSApp.keyWindow as Any
    NSAccessibility.post(
        element: element,
        notification: .announcementRequested,
        userInfo: [
            NSAccessibility.NotificationUserInfoKey.announcement: message,
            NSAccessibility.NotificationUserInfoKey.priority: NSAccessibilityPriorityLevel.high.rawValue
        ]
    )
}
