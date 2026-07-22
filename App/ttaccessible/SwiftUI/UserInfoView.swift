//
//  UserInfoView.swift
//  ttaccessible
//

import SwiftUI
import Combine

@MainActor
final class UserInfoViewModel: ObservableObject {
    struct Row: Identifiable {
        let id: String
        let title: String
        let value: String
    }

    @Published private(set) var title: String = L10n.text("userInfo.window.title")
    @Published private(set) var rows: [Row] = []

    var userStatisticsProvider: ((Int32) -> UserStatistics?)?

    func update(user: ConnectedServerUser?) {
        title = user?.displayName ?? L10n.text("userInfo.window.title")

        let stats = user.flatMap { userStatisticsProvider?($0.id) }
        let packetLoss: String? = stats.map { s in
            let total = s.nVoicePacketsRecv + s.nVoicePacketsLost
            if total == 0 { return "0%" }
            let percent = Double(s.nVoicePacketsLost) / Double(total) * 100
            return String(format: "%.1f%% (%d / %d)", percent, s.nVoicePacketsLost, total)
        }

        let values: [(String, String, String?)] = [
            ("id", L10n.text("userInfo.field.id"), user.map { String($0.id) }),
            ("nickname", L10n.text("userInfo.field.nickname"), user?.nickname),
            ("username", L10n.text("userInfo.field.username"), user?.username.isEmpty == false ? user?.username : nil),
            ("statusMode", L10n.text("userInfo.field.statusMode"), user.map { L10n.text($0.statusMode.localizationKey) }),
            ("statusMessage", L10n.text("userInfo.field.statusMessage"), user?.statusMessage.isEmpty == false ? user?.statusMessage : nil),
            ("gender", L10n.text("userInfo.field.gender"), user.map { L10n.text($0.gender.localizationKey) }),
            ("userType", L10n.text("userInfo.field.userType"), user.map { $0.isAdministrator ? L10n.text("userInfo.value.userType.admin") : L10n.text("userInfo.value.userType.default") }),
            ("channelOperator", L10n.text("userInfo.field.channelOperator"), user.map { $0.isChannelOperator ? L10n.text("common.yes") : L10n.text("common.no") }),
            ("ipAddress", L10n.text("userInfo.field.ipAddress"), user?.ipAddress.isEmpty == false ? user?.ipAddress : nil),
            ("client", L10n.text("userInfo.field.client"), user?.clientName.isEmpty == false ? user?.clientName : nil),
            ("version", L10n.text("userInfo.field.version"), user?.clientVersion.isEmpty == false ? user?.clientVersion : nil),
            ("packetLoss", L10n.text("userInfo.field.packetLoss"), packetLoss)
        ]

        rows = values.compactMap { key, title, value in
            guard let value, value.isEmpty == false else { return nil }
            return Row(id: key, title: title, value: value)
        }
    }
}

struct UserInfoView: View {
    @ObservedObject var viewModel: UserInfoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(viewModel.title)
                .font(.title2)

            if viewModel.rows.isEmpty {
                Text(L10n.text("userInfo.empty"))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.rows) { row in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.title)
                                    .fontWeight(.bold)
                                Text(row.value)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 320)
    }
}
