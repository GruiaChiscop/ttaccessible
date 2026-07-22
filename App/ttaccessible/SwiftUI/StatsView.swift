//
//  StatsView.swift
//  ttaccessible
//

import SwiftUI
import Combine

@MainActor
final class StatsViewModel: ObservableObject {
    struct Row: Identifiable {
        let id: String
        let label: String
        let value: String
    }

    @Published private(set) var rows: [Row]

    var onRefreshNeeded: (() -> Void)?
    var clientStatisticsProvider: (() -> ClientStatistics?)?

    private var refreshTimer: Timer?

    init() {
        rows = Self.buildRows(from: ServerStatistics(), clientStats: nil)
    }

    func update(stats: ServerStatistics) {
        rows = Self.buildRows(from: stats, clientStats: clientStatisticsProvider?())
    }

    func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.onRefreshNeeded?() }
        }
        onRefreshNeeded?()
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private static func buildRows(from stats: ServerStatistics, clientStats: ClientStatistics?) -> [Row] {
        var rows = [
            Row(id: "uptime", label: L10n.text("stats.uptime"), value: formatUptime(stats.nUptimeMSec)),
            Row(id: "usersServed", label: L10n.text("stats.usersServed"), value: "\(stats.nUsersServed)"),
            Row(id: "usersPeak", label: L10n.text("stats.usersPeak"), value: "\(stats.nUsersPeak)"),
            Row(id: "totalTX", label: L10n.text("stats.totalTX"), value: formatBytes(stats.nTotalBytesTX)),
            Row(id: "totalRX", label: L10n.text("stats.totalRX"), value: formatBytes(stats.nTotalBytesRX)),
            Row(id: "voiceTX", label: L10n.text("stats.voiceTX"), value: formatBytes(stats.nVoiceBytesTX)),
            Row(id: "voiceRX", label: L10n.text("stats.voiceRX"), value: formatBytes(stats.nVoiceBytesRX)),
        ]
        if let clientStats {
            rows.append(Row(id: "pingUDP", label: L10n.text("stats.pingUDP"), value: "\(clientStats.nUdpPingTimeMs) ms"))
            rows.append(Row(id: "pingTCP", label: L10n.text("stats.pingTCP"), value: "\(clientStats.nTcpPingTimeMs) ms"))
        }
        return rows
    }

    private static func formatUptime(_ ms: Int64) -> String {
        guard ms > 0 else { return "—" }
        let totalSeconds = Int(ms / 1000)
        let days    = totalSeconds / 86400
        let hours   = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        if days > 0 { return "\(days)j \(hours)h \(minutes)min" }
        if hours > 0 { return "\(hours)h \(minutes)min" }
        return "\(minutes) min"
    }

    private static func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 o" }
        let kb = Double(bytes) / 1024
        let mb = kb / 1024
        let gb = mb / 1024
        if gb >= 1 { return String(format: "%.1f Go", gb) }
        if mb >= 1 { return String(format: "%.1f Mo", mb) }
        return String(format: "%.1f Ko", kb)
    }
}

struct StatsView: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.rows) { row in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text(row.label + " :")
                        .fontWeight(.bold)
                        .frame(width: 140, alignment: .trailing)
                    Text(row.value)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(20)
        .frame(minWidth: 400, minHeight: 260)
        .onAppear { viewModel.startAutoRefresh() }
        .onDisappear { viewModel.stopAutoRefresh() }
    }
}
