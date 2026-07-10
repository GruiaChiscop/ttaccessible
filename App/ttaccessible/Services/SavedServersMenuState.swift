//
//  SavedServersMenuState.swift
//  ttaccessible
//
//  Created by Mathieu Martin on 17/03/2026.
//

import Combine
import Foundation

@MainActor
final class SavedServersMenuState: ObservableObject {
    enum Mode {
        case savedServers
        case connectedServer
    }

    static let shared = SavedServersMenuState()

    @Published private(set) var hasSelection = false
    @Published private(set) var mode: Mode = .savedServers
    @Published private(set) var hasSelectedChannel = false
    @Published private(set) var isInChannel = false
    @Published private(set) var isAdministrator = false
    @Published private(set) var canSendBroadcast = false
    @Published private(set) var canCreateTemporaryChannel = false
    @Published private(set) var canModifyChannels = false
    @Published private(set) var canKickUsers = false
    @Published private(set) var canBanUsers = false
    @Published private(set) var canUploadFiles = false
    @Published private(set) var canDownloadFiles = false
    @Published private(set) var canUpdateServerProperties = false
    @Published private(set) var canTransmitVoice = false
    @Published private(set) var voiceTransmissionEnabled = false
    @Published private(set) var canTransmitMediaFile = false
    @Published private(set) var canTextMessageUser = false
    @Published private(set) var canTextMessageChannel = false
    @Published private(set) var isNicknameLocked = false
    @Published private(set) var isStatusLocked = false
    @Published private(set) var hasSelectedUsers = false
    @Published private(set) var hasSingleSelectedUser = false
    @Published private(set) var hasSingleSelectedOtherUser = false
    @Published private(set) var canMoveSelectedUsers = false
    @Published private(set) var isSelectedUserMuted = false
    @Published private(set) var isSelectedUserMediaFileMuted = false
    @Published private(set) var isSelectedUserChannelOperator = false
    @Published private(set) var isMicrophoneMuted = false
    @Published private(set) var isMasterMuted = false
    @Published private(set) var isRecordingActive = false
    @Published private(set) var isHearMyselfEnabled = false
    @Published private(set) var isMediaStreamingActive = false
    @Published private(set) var keyBindingScheme: AppKeyBindingScheme = .ttaccessible
    @Published private(set) var selectedUserSubscriptionStates: [UserSubscriptionOption: Bool] = [:]

    private init() {
    }

    func setHasSelection(_ hasSelection: Bool) {
        if self.hasSelection != hasSelection {
            self.hasSelection = hasSelection
        }
    }

    func setMode(_ mode: Mode) {
        if self.mode != mode {
            self.mode = mode
        }
    }

    func setConnectedState(hasSelectedChannel: Bool, isInChannel: Bool) {
        if self.hasSelectedChannel != hasSelectedChannel {
            self.hasSelectedChannel = hasSelectedChannel
        }

        if self.isInChannel != isInChannel {
            self.isInChannel = isInChannel
        }
    }

    func resetConnectedTransientState() {
        setCanSendBroadcast(false)
        setConnectedPermissions(from: nil)
        setSelectedUsersState(hasSelectedUsers: false, hasSingleSelectedUser: false, hasSingleSelectedOtherUser: false, canMoveSelectedUsers: false, isSelectedUserMuted: false, isSelectedUserMediaFileMuted: false, isSelectedUserChannelOperator: false, states: [:])
        setMicrophoneMuted(false)
        setMasterMuted(false)
        setVoiceTransmissionEnabled(false)
        setRecordingActive(false)
        setHearMyselfEnabled(false)
        setMediaStreamingActive(false)
    }

    func setAdministrator(_ value: Bool) {
        if isAdministrator != value { isAdministrator = value }
    }

    func setCanSendBroadcast(_ value: Bool) {
        if canSendBroadcast != value { canSendBroadcast = value }
    }

    func setConnectedPermissions(from session: ConnectedServerSession?) {
        let canCreateTemporaryChannel = session?.canCreateTemporaryChannel ?? false
        let canModifyChannels = session?.canModifyChannels ?? false
        let canKickUsers = session?.canKickUsers ?? false
        let canBanUsers = session?.canBanUsers ?? false
        let canUploadFiles = session?.canUploadFiles ?? false
        let canDownloadFiles = session?.canDownloadFiles ?? false
        let canUpdateServerProperties = session?.canUpdateServerProperties ?? false
        let canTransmitVoice = session?.canTransmitVoice ?? false
        let canTransmitMediaFile = session?.canTransmitMediaFile ?? false
        let canTextMessageUser = session?.canTextMessageUser ?? false
        let canTextMessageChannel = session?.canTextMessageChannel ?? false

        if self.canCreateTemporaryChannel != canCreateTemporaryChannel { self.canCreateTemporaryChannel = canCreateTemporaryChannel }
        if self.canModifyChannels != canModifyChannels { self.canModifyChannels = canModifyChannels }
        if self.canKickUsers != canKickUsers { self.canKickUsers = canKickUsers }
        if self.canBanUsers != canBanUsers { self.canBanUsers = canBanUsers }
        if self.canUploadFiles != canUploadFiles { self.canUploadFiles = canUploadFiles }
        if self.canDownloadFiles != canDownloadFiles { self.canDownloadFiles = canDownloadFiles }
        if self.canUpdateServerProperties != canUpdateServerProperties { self.canUpdateServerProperties = canUpdateServerProperties }
        if self.canTransmitVoice != canTransmitVoice { self.canTransmitVoice = canTransmitVoice }
        if self.canTransmitMediaFile != canTransmitMediaFile { self.canTransmitMediaFile = canTransmitMediaFile }
        if self.canTextMessageUser != canTextMessageUser { self.canTextMessageUser = canTextMessageUser }
        if self.canTextMessageChannel != canTextMessageChannel { self.canTextMessageChannel = canTextMessageChannel }
    }

    var canCreateAnyChannel: Bool {
        canCreateTemporaryChannel || canModifyChannels
    }

    func setNicknameLocked(_ value: Bool) {
        if isNicknameLocked != value { isNicknameLocked = value }
    }

    func setStatusLocked(_ value: Bool) {
        if isStatusLocked != value { isStatusLocked = value }
    }

    func setMicrophoneMuted(_ value: Bool) {
        if isMicrophoneMuted != value { isMicrophoneMuted = value }
    }

    func setMasterMuted(_ value: Bool) {
        if isMasterMuted != value { isMasterMuted = value }
    }

    func setRecordingActive(_ value: Bool) {
        if isRecordingActive != value { isRecordingActive = value }
    }

    func setVoiceTransmissionEnabled(_ value: Bool) {
        if voiceTransmissionEnabled != value { voiceTransmissionEnabled = value }
    }

    func setHearMyselfEnabled(_ value: Bool) {
        if isHearMyselfEnabled != value { isHearMyselfEnabled = value }
    }

    func setMediaStreamingActive(_ value: Bool) {
        if isMediaStreamingActive != value { isMediaStreamingActive = value }
    }

    func setKeyBindingScheme(_ scheme: AppKeyBindingScheme) {
        if keyBindingScheme != scheme { keyBindingScheme = scheme }
    }

    func setSelectedUsersState(hasSelectedUsers: Bool, hasSingleSelectedUser: Bool, hasSingleSelectedOtherUser: Bool, canMoveSelectedUsers: Bool, isSelectedUserMuted: Bool, isSelectedUserMediaFileMuted: Bool, isSelectedUserChannelOperator: Bool, states: [UserSubscriptionOption: Bool]) {
        if self.hasSelectedUsers != hasSelectedUsers {
            self.hasSelectedUsers = hasSelectedUsers
        }
        if self.hasSingleSelectedUser != hasSingleSelectedUser {
            self.hasSingleSelectedUser = hasSingleSelectedUser
        }
        if self.hasSingleSelectedOtherUser != hasSingleSelectedOtherUser {
            self.hasSingleSelectedOtherUser = hasSingleSelectedOtherUser
        }
        if self.canMoveSelectedUsers != canMoveSelectedUsers {
            self.canMoveSelectedUsers = canMoveSelectedUsers
        }
        if self.isSelectedUserMuted != isSelectedUserMuted {
            self.isSelectedUserMuted = isSelectedUserMuted
        }
        if self.isSelectedUserMediaFileMuted != isSelectedUserMediaFileMuted {
            self.isSelectedUserMediaFileMuted = isSelectedUserMediaFileMuted
        }
        if self.isSelectedUserChannelOperator != isSelectedUserChannelOperator {
            self.isSelectedUserChannelOperator = isSelectedUserChannelOperator
        }
        if self.selectedUserSubscriptionStates != states {
            self.selectedUserSubscriptionStates = states
        }
    }

    func isSelectedUsersSubscriptionEnabled(_ option: UserSubscriptionOption) -> Bool {
        selectedUserSubscriptionStates[option] ?? false
    }
}
