//
//  ttaccessibleApp.swift
//  ttaccessible
//
//  Created by Mathieu Martin on 17/03/2026.
//

import AppKit
import SwiftUI

@main
struct ttaccessibleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var menuState = SavedServersMenuState.shared

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            let keyBindings = menuState.keyBindingScheme

            CommandGroup(replacing: .appSettings) {
                Button(L10n.text("preferences.menu.title")) {
                    appDelegate.openPreferences()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.preferences))
            }

            CommandGroup(after: .appInfo) {
                Button(L10n.text("update.menu.checkForUpdates")) {
                    appDelegate.checkForUpdates()
                }

                Divider()

                Button(L10n.text("profile.menu.newInstance")) {
                    appDelegate.openProfilesWindow()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.newClientInstance))

                Button(L10n.text("profile.menu.manage")) {
                    appDelegate.openProfilesWindow()
                }
            }

            CommandGroup(after: .help) {
                Button(L10n.text("help.menu.viewOnGitHub")) {
                    NSWorkspace.shared.open(URL(string: "https://github.com/math65/ttaccessible")!)
                }
                Button(L10n.text("help.menu.reportIssue")) {
                    NSWorkspace.shared.open(URL(string: "https://github.com/math65/ttaccessible/issues/new/choose")!)
                }
                if AppBackendClient.isConfigured {
                    Button(L10n.text("help.menu.contactDeveloper")) {
                        appDelegate.openFeedback()
                    }
                }
            }

            CommandGroup(replacing: .newItem) {
            }

            CommandMenu(L10n.text("savedServers.menu.title")) {
                if menuState.mode == .savedServers {
                    Button(L10n.text("savedServers.menu.new")) {
                        appDelegate.addSavedServer()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.savedServerNew))

                    Button(L10n.text("savedServers.menu.connect")) {
                        appDelegate.connectSelectedSavedServer()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.savedServerConnect))
                    .disabled(menuState.hasSelection == false)

                    Button(L10n.text("savedServers.menu.import")) {
                        appDelegate.importTeamTalkServers()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.savedServerImport))

                    Button(L10n.text("serverExport.menu.title")) {
                        appDelegate.exportServer()
                    }
                    .disabled(menuState.hasSelection == false)

                    Button(L10n.text("savedServers.menu.exportList")) {
                        appDelegate.exportServerList()
                    }

                    Divider()

                    Button(L10n.text("savedServers.menu.edit")) {
                        appDelegate.editSelectedSavedServer()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.savedServerEdit))
                    .disabled(menuState.hasSelection == false)

                    Button(L10n.text("savedServers.menu.delete")) {
                        appDelegate.deleteSelectedSavedServer()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.savedServerDelete))
                    .disabled(menuState.hasSelection == false)
                } else {
                    Button(L10n.text("connectedServer.identity.nickname.menu")) {
                        appDelegate.changeNickname()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.changeNickname))
                    .disabled(menuState.isNicknameLocked)

                    Button(L10n.text("connectedServer.identity.status.menu")) {
                        appDelegate.changeStatus()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.changeStatus))
                    .disabled(menuState.isStatusLocked)

                    Divider()

                    Button(L10n.text("privateMessages.menu.open")) {
                        appDelegate.openMessages()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.privateMessagesFromServerMenu))

                    Button(L10n.text("files.menu.open")) {
                        appDelegate.openChannelFiles()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.channelFiles))
                    .disabled(menuState.isInChannel == false || (menuState.canDownloadFiles == false && menuState.canUploadFiles == false))

                    Button(L10n.text("files.menu.upload")) {
                        appDelegate.uploadFile()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.uploadFile))
                    .disabled(menuState.isInChannel == false || menuState.canUploadFiles == false)

                    Divider()

                    Button(L10n.text("connectedServer.menu.createChannel")) {
                        appDelegate.createChannel()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.createChannel))
                    .disabled(menuState.canCreateAnyChannel == false || (menuState.hasSelectedChannel == false && menuState.isInChannel == false))

                    Button(L10n.text("connectedServer.menu.editChannel")) {
                        appDelegate.updateChannel()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.editChannel))
                    .disabled(menuState.hasSelectedChannel == false || menuState.canModifyChannels == false)

                    Button(L10n.text("connectedServer.menu.deleteChannel")) {
                        appDelegate.deleteChannel()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.deleteChannel))
                    .disabled(menuState.hasSelectedChannel == false || menuState.canModifyChannels == false)

                    Divider()

                    Button(L10n.text("connectedUsers.menu.open")) {
                        appDelegate.openConnectedUsers()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.connectedUsers))
                    .disabled(menuState.mode != .connectedServer)

                    Button(L10n.text("accounts.menu.open")) {
                        appDelegate.openUserAccounts()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.userAccounts))
                    .disabled(menuState.mode != .connectedServer || menuState.isAdministrator == false)

                    Button(L10n.text("bans.menu.open")) {
                        appDelegate.openBannedUsers()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.bannedUsers))
                    .disabled(menuState.mode != .connectedServer || menuState.canBanUsers == false)

                    Button(L10n.text("serverProperties.menu.open")) {
                        appDelegate.openServerProperties()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.serverProperties))
                    .disabled(menuState.mode != .connectedServer || menuState.canUpdateServerProperties == false)

                    Button(L10n.text("serverConfig.menu.save")) {
                        appDelegate.saveServerConfig()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.saveServerConfig))
                    .disabled(menuState.mode != .connectedServer || menuState.canUpdateServerProperties == false)

                    Button(L10n.text("stats.menu.open")) {
                        appDelegate.openStats()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.serverStatistics))
                    .disabled(menuState.mode != .connectedServer)

                    Divider()

                    Button(L10n.text("broadcast.menu.send")) {
                        appDelegate.broadcastMessage()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.broadcastMessage))
                    .disabled(menuState.mode != .connectedServer || menuState.canSendBroadcast == false)

                    Divider()

                    Button(L10n.text("connectedServer.serverLink.copy")) {
                        appDelegate.copyServerLink()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.copyServerLink))

                    Button(L10n.text("serverExport.menu.title")) {
                        appDelegate.exportServer()
                    }

                    Divider()

                    Button(L10n.text("connectedServer.menu.disconnect")) {
                        appDelegate.disconnectServer()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.disconnect))
                }
            }

            if menuState.mode == .connectedServer {
                CommandMenu(L10n.text("user.menu.title")) {
                    Button(L10n.text("user.menu.info")) {
                        appDelegate.openSelectedUserInfo()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.userInfo))
                    .disabled(menuState.hasSingleSelectedUser == false)

                    Button(menuState.isSelectedUserMuted
                           ? L10n.text("user.menu.unmute")
                           : L10n.text("user.menu.mute")) {
                        appDelegate.toggleMuteSelectedUser()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.muteUser))
                    .disabled(menuState.hasSingleSelectedOtherUser == false)

                    Button(menuState.isSelectedUserMediaFileMuted
                           ? L10n.text("user.menu.unmuteMediaFile")
                           : L10n.text("user.menu.muteMediaFile")) {
                        appDelegate.toggleMuteSelectedUserMediaFile()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.muteUserMediaFile))
                    .disabled(menuState.hasSingleSelectedOtherUser == false)

                    Button(L10n.text("user.menu.volume")) {
                        appDelegate.adjustSelectedUserVolume()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.userVolume))
                    .disabled(menuState.hasSingleSelectedUser == false)

                    Button(menuState.isSelectedUserChannelOperator
                           ? L10n.text("user.menu.revokeOperator")
                           : L10n.text("user.menu.makeOperator")) {
                        appDelegate.toggleChannelOperator()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.toggleOperator))
                    .disabled(menuState.hasSingleSelectedOtherUser == false)

                    Divider()

                    Button(L10n.text("user.menu.kick")) {
                        appDelegate.kickSelectedUser()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.kickUser))
                    .disabled(menuState.hasSingleSelectedOtherUser == false || menuState.canKickUsers == false)

                    Button(L10n.text("user.menu.kickServer")) {
                        appDelegate.kickSelectedUserFromServer()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.kickUserFromServer))
                    .disabled(menuState.hasSingleSelectedOtherUser == false || menuState.canKickUsers == false)

                    Button(L10n.text("user.menu.kickBan")) {
                        appDelegate.kickBanSelectedUser()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.kickBanUser))
                    .disabled(menuState.hasSingleSelectedOtherUser == false || menuState.canBanUsers == false)

                    Button(L10n.text("user.menu.move")) {
                        appDelegate.moveSelectedUser()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.moveUser))
                    .disabled(menuState.canMoveSelectedUsers == false)

                    Button(L10n.text("connectedServer.menu.markForMove")) {
                        appDelegate.markSelectedUsersForMove()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.markForMove))
                    .disabled(menuState.canMoveSelectedUsers == false)

                    Button(L10n.text("connectedServer.menu.moveMarkedUsersHere")) {
                        appDelegate.moveMarkedUsersToSelectedChannel()
                    }
                    .appKeyboardShortcut(keyBindings.shortcut(.moveMarkedUsers))
                    .disabled(menuState.mode != .connectedServer || menuState.hasSelectedChannel == false || menuState.canMoveUsers == false)

                    Divider()

                    Menu(L10n.text("user.menu.subscriptions")) {
                        ForEach(UserSubscriptionOption.regularCases, id: \.self) { option in
                            Toggle(
                                L10n.text(option.localizationKey),
                                isOn: Binding(
                                    get: { menuState.isSelectedUsersSubscriptionEnabled(option) },
                                    set: { appDelegate.setSelectedUsersSubscription(option, enabled: $0) }
                                )
                            )
                            .appKeyboardShortcut(option.shortcut(in: keyBindings))
                            .disabled(menuState.hasSelectedUsers == false)
                        }

                        Divider()

                        ForEach(UserSubscriptionOption.interceptCases, id: \.self) { option in
                            Toggle(
                                L10n.text(option.localizationKey),
                                isOn: Binding(
                                    get: { menuState.isSelectedUsersSubscriptionEnabled(option) },
                                    set: { appDelegate.setSelectedUsersSubscription(option, enabled: $0) }
                                )
                            )
                            .appKeyboardShortcut(option.shortcut(in: keyBindings))
                            .disabled(menuState.hasSelectedUsers == false)
                        }
                    }
                    .disabled(menuState.hasSelectedUsers == false)
                }
            }

            CommandMenu(L10n.text("shortcuts.menu.title")) {
                Button(L10n.text("shortcuts.focus.primary")) {
                    appDelegate.focusPrimaryArea()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.focusPrimary))

                Button(L10n.text("shortcuts.focus.secondary")) {
                    appDelegate.focusSecondaryArea()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.focusSecondary))
                .disabled(menuState.mode != .connectedServer)

                Button(L10n.text("shortcuts.focus.message")) {
                    appDelegate.focusMessageArea()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.focusMessage))
                .disabled(menuState.mode != .connectedServer || menuState.isInChannel == false || menuState.canTextMessageChannel == false)

                Button(L10n.text("shortcuts.focus.history")) {
                    appDelegate.focusHistoryArea()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.focusHistory))
                .disabled(menuState.mode != .connectedServer)

                Button(L10n.text("mixer.menu.open")) {
                    appDelegate.focusChannelMixerArea()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.focusMixer))
                .disabled(menuState.mode != .connectedServer || menuState.isInChannel == false)

                Divider()

                Button(L10n.text("connectedServer.menu.join")) {
                    appDelegate.joinSelectedChannel()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.joinChannel))
                .disabled(menuState.mode != .connectedServer || menuState.hasSelectedChannel == false)

                Button(L10n.text("connectedServer.menu.leave")) {
                    appDelegate.leaveCurrentChannel()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.leaveChannel))
                .disabled(menuState.mode != .connectedServer || menuState.isInChannel == false)

                Button(L10n.text("shortcuts.messages")) {
                    appDelegate.openMessages()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.privateMessages))
                .disabled(menuState.mode != .connectedServer)

                Button(L10n.text("shortcuts.microphone")) {
                    appDelegate.toggleMicrophone()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.toggleMicrophone))
                .disabled(
                    menuState.mode != .connectedServer
                        || (menuState.voiceTransmissionEnabled == false
                            && (menuState.isInChannel == false || menuState.canTransmitVoice == false))
                )

                Button(menuState.isMasterMuted
                       ? L10n.text("shortcuts.masterUnmute")
                       : L10n.text("shortcuts.masterMute")) {
                    appDelegate.toggleMasterMute()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.masterMute))
                .disabled(menuState.mode != .connectedServer)

                Button(L10n.text("shortcuts.ttsEvents")) {
                    appDelegate.toggleTTSEvents()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.toggleTTSEvents))

                Button(L10n.text("shortcuts.soundEvents")) {
                    appDelegate.toggleSoundEvents()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.toggleSoundEvents))

                Button(menuState.isRecordingActive
                       ? L10n.text("shortcuts.recording.stop")
                       : L10n.text("shortcuts.recording.start")) {
                    appDelegate.toggleRecording()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.recording))
                .disabled(menuState.mode != .connectedServer || (!menuState.isRecordingActive && menuState.isInChannel == false))

                Divider()

                Button(L10n.text("shortcuts.mediaStream.startFile")) {
                    appDelegate.startStreamingMediaFromFile()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.streamMediaFile))
                .disabled(menuState.mode != .connectedServer || menuState.isMediaStreamingActive || menuState.isInChannel == false || menuState.canTransmitMediaFile == false)

                Button(L10n.text("shortcuts.mediaStream.startURL")) {
                    appDelegate.startStreamingMediaFromURL()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.streamMediaURL))
                .disabled(menuState.mode != .connectedServer || menuState.isMediaStreamingActive || menuState.isInChannel == false || menuState.canTransmitMediaFile == false)

                Button(L10n.text("shortcuts.mediaStream.stop")) {
                    appDelegate.stopMediaStreaming()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.stopMediaStream))
                .disabled(menuState.mode != .connectedServer || !menuState.isMediaStreamingActive)

                Button(L10n.text("shortcuts.hearMyself")) {
                    appDelegate.toggleHearMyself()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.hearMyself))
                .disabled(menuState.mode != .connectedServer || menuState.isInChannel == false)

                Button(L10n.text("shortcuts.announceAudio")) {
                    appDelegate.announceAudioState()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.announceAudio))
                .disabled(menuState.mode != .connectedServer)

                Divider()

                Button(L10n.text("shortcuts.exportChat")) {
                    appDelegate.exportChat()
                }
                .appKeyboardShortcut(keyBindings.shortcut(.exportChat))
                .disabled(menuState.mode != .connectedServer || menuState.isInChannel == false)
            }
        }
    }
}
