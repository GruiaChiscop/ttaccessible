//
//  ConnectedServerViewController+OutlineDelegate.swift
//  ttaccessible
//
//  Created by Mathieu Martin on 17/03/2026.
//

import AppKit

// MARK: - Display Formatters

extension ConnectedServerViewController {
    func displayText(for node: ServerTreeNode) -> String {
        switch node {
        case .channel(let channel):
            return visualChannelText(for: channel)
        case .user(let user):
            return visualUserText(for: user)
        }
    }

    func accessibilityText(for node: ServerTreeNode) -> String {
        switch node {
        case .channel(let channel):
            var parts = [visualChannelText(for: channel)]
            if channel.topic.isEmpty == false {
                parts.append(L10n.format("connectedServer.channel.topicOnlyFormat", channel.topic))
            }
            return parts.joined(separator: ", ")
        case .user(let user):
            return userAccessibilityText(for: user)
        }
    }

    func visualChannelText(for channel: ConnectedServerChannel) -> String {
        let nameWithCount: String
        if channel.totalUserCount == 0 && channel.children.isEmpty {
            nameWithCount = channel.name
        } else if channel.children.isEmpty {
            nameWithCount = "\(channel.name) (\(channel.directUserCount))"
        } else {
            nameWithCount = "\(channel.name) (\(channel.directUserCount)/\(channel.totalUserCount))"
        }

        var parts = [nameWithCount]
        if channel.isCurrentChannel {
            parts.append(L10n.text("connectedServer.channel.currentSuffix"))
        }
        if channel.isPasswordProtected {
            parts.append(L10n.text("connectedServer.channel.passwordProtectedSuffix"))
        }
        if channel.isHidden {
            parts.append(L10n.text("connectedServer.channel.hiddenSuffix"))
        }
        return parts.joined(separator: ", ")
    }

    func visualUserText(for user: ConnectedServerUser) -> String {
        userTextParts(for: user).joined(separator: ", ")
    }

    func userAccessibilityText(for user: ConnectedServerUser) -> String {
        var parts = userTextParts(for: user)
        if isMarkedForMove(user) {
            parts.insert(L10n.text("connectedServer.move.selectedForMove.accessibilityPrefix"), at: 0)
        }
        return parts.joined(separator: ", ")
    }

    func markedUserAttributedText(for user: ConnectedServerUser, font: NSFont) -> NSAttributedString {
        let result = NSMutableAttributedString()
        if let image = NSImage(systemSymbolName: "checkmark", accessibilityDescription: nil) {
            let attachment = NSTextAttachment()
            attachment.image = image
            let baselineOffset = (font.capHeight - image.size.height) / 2
            attachment.bounds = NSRect(x: 0, y: baselineOffset, width: image.size.width, height: image.size.height)
            result.append(NSAttributedString(attachment: attachment))
            result.append(NSAttributedString(string: " "))
        }
        result.append(NSAttributedString(string: visualUserText(for: user), attributes: [.font: font]))
        return result
    }

    private func userTextParts(for user: ConnectedServerUser) -> [String] {
        var parts = [user.displayName]
        parts.append(L10n.text(user.statusMode.localizationKey))
        if user.isCurrentUser {
            parts.append(L10n.text("connectedServer.user.currentSuffix"))
        }
        if user.isAdministrator {
            parts.append(L10n.text("connectedServer.user.administratorSuffix"))
        }
        if user.isChannelOperator {
            parts.append(L10n.text("connectedServer.user.channelOperatorSuffix"))
        }
        if user.isTalking {
            parts.append(L10n.text("connectedServer.user.talkingSuffix"))
        }
        parts.append(L10n.text(user.gender.localizationKey))
        if user.statusMessage.isEmpty == false {
            parts.append(user.statusMessage)
        }
        return parts
    }
}

// MARK: - NSOutlineViewDelegate

extension ConnectedServerViewController: NSOutlineViewDelegate {
    func outlineViewSelectionDidChange(_ notification: Notification) {
        selectedKey = currentSelectionKey()
        updateMenuState()
        updateVideoSelectionFromTree()
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if case .channel(let ch) = item as? ServerTreeNode, !ch.topic.isEmpty {
            return 34
        }
        return outlineView.rowHeight
    }

    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        let rowView = ServerTreeRowView()
        if let node = item as? ServerTreeNode {
            rowView.voiceOverLabel = accessibilityText(for: node)
        }
        return rowView
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? ServerTreeNode else { return nil }

        let identifier = NSUserInterfaceItemIdentifier("ConnectedServerCell")
        let textField: PressActionTextField

        if let cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? PressActionTextField {
            textField = cell
        } else {
            textField = PressActionTextField(labelWithString: "")
            textField.identifier = identifier
            textField.lineBreakMode = .byTruncatingTail
        }

        // VO-Espace effectue l'action par défaut sur CE nœud (rejoindre/quitter un salon,
        // ouvrir un message privé), comme la touche Entrée — indépendamment de la
        // sélection, car sans interaction l'arbre n'a aucune ligne sélectionnée.
        textField.onPress = { [weak self] in
            self?.performDefaultAction(for: node)
        }

        let accessLabel = accessibilityText(for: node)
        textField.toolTip = accessLabel
        textField.voiceOverLabel = accessLabel
        textField.setAccessibilityLabel(accessLabel)

        switch node {
        case .channel(let channel):
            let nameText = visualChannelText(for: channel)
            let nameFont: NSFont = channel.isCurrentChannel
                ? .boldSystemFont(ofSize: NSFont.systemFontSize)
                : .systemFont(ofSize: NSFont.systemFontSize)
            if channel.topic.isEmpty {
                textField.font = nameFont
                textField.stringValue = nameText
                textField.maximumNumberOfLines = 1
            } else {
                let attr = NSMutableAttributedString(
                    string: nameText,
                    attributes: [.font: nameFont]
                )
                attr.append(NSAttributedString(
                    string: "\n\(channel.topic)",
                    attributes: [
                        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                        .foregroundColor: NSColor.secondaryLabelColor
                    ]
                ))
                textField.attributedStringValue = attr
                textField.maximumNumberOfLines = 2
            }
            let joinActionName = channel.isCurrentChannel
                ? L10n.text("connectedServer.voAction.leave")
                : L10n.text("connectedServer.voAction.join")
            var actions = [
                NSAccessibilityCustomAction(name: joinActionName) { [weak self] in
                    self?.performDefaultAction(); return true
                }
            ]
            if session.canMoveUsers && markedUserIDsForMove.isEmpty == false {
                actions.append(NSAccessibilityCustomAction(name: L10n.text("connectedServer.menu.moveMarkedUsersHere")) { [weak self] in
                    self?.moveMarkedUsers(to: channel); return true
                })
            }
            textField.setAccessibilityCustomActions(actions)
        case .user(let user):
            textField.font = user.isTalking
                ? .boldSystemFont(ofSize: NSFont.systemFontSize)
                : .systemFont(ofSize: NSFont.systemFontSize)
            let userFont = textField.font ?? .systemFont(ofSize: NSFont.systemFontSize)
            if isMarkedForMove(user) {
                textField.attributedStringValue = markedUserAttributedText(for: user, font: userFont)
            } else {
                textField.stringValue = visualUserText(for: user)
            }
            textField.maximumNumberOfLines = 1
            var actions: [NSAccessibilityCustomAction] = []
            if !user.isCurrentUser, session.canTextMessageUser {
                actions.append(NSAccessibilityCustomAction(name: L10n.text("connectedServer.voAction.privateMessage")) { [weak self] in
                    self?.openPrivateConversation(nil); return true
                })
            }
            if !user.isCurrentUser {
                let isMuted = localMuteState[user.id] ?? user.isMuted
                let muteTitle = isMuted
                    ? L10n.text("connectedServer.menu.unmuteUser")
                    : L10n.text("connectedServer.menu.muteUser")
                actions.append(NSAccessibilityCustomAction(name: muteTitle) { [weak self] in
                    self?.toggleMuteUserAction(); return true
                })
                let isMediaFileMuted = localMediaFileMuteState[user.id] ?? user.isMediaFileMuted
                let mediaFileMuteTitle = isMediaFileMuted
                    ? L10n.text("connectedServer.menu.unmuteMediaFile")
                    : L10n.text("connectedServer.menu.muteMediaFile")
                actions.append(NSAccessibilityCustomAction(name: mediaFileMuteTitle) { [weak self] in
                    self?.toggleMuteUserMediaFileAction(); return true
                })
                if session.canKickUsers {
                    actions.append(NSAccessibilityCustomAction(name: L10n.text("connectedServer.menu.kickUser")) { [weak self] in
                        self?.kickUserAction(nil); return true
                    })
                }
            }
            if session.canMoveUsers {
                actions.append(NSAccessibilityCustomAction(name: L10n.text("connectedServer.menu.moveUser")) { [weak self] in
                    let selectedUsers = self?.selectedUserNodes() ?? []
                    self?.performMove(selectedUsers.isEmpty ? [user] : selectedUsers, presentingWindow: self?.view.window)
                    return true
                })
                let markTargets = moveMarkTargets(selectedUsers: selectedUserNodes(), fallbackUser: user)
                actions.append(NSAccessibilityCustomAction(name: markActionName(for: markTargets)) { [weak self] in
                    self?.performMarkForMove(self?.selectedUserNodes() ?? [], fallbackUser: user)
                    return true
                })
            }
            textField.setAccessibilityCustomActions(actions)
        }

        return textField
    }
}
